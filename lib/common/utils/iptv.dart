import 'dart:io';
import 'package:tivi/common/index.dart';
import 'package:oktoast/oktoast.dart';
import 'package:path_provider/path_provider.dart';

final _logger = LoggerUtil.create(['iptv']);

/// iptv工具类
class IptvUtil {
  IptvUtil._();

  /// 获取远程直播源
  static Future<String> _fetchSource(IPTVCallBack? callBack) async {
    try {
      final iptvSource =IptvSettings.customIptvSource.isNotEmpty ? IptvSettings.customIptvSource : Constants.iptvSource;
      _logger.debug('Get remote live source: $iptvSource');
      final result = await RequestUtil.get(iptvSource,callBack: callBack);
      return result;
    } catch (e, st) {
      _logger.handle(e, st);
      showToast('Failed to obtain live source, please check the network connection');
      rethrow;
    }
  }

  /// 获取缓存直播源文件
  static Future<File> _getCacheFile() async {
    return File('${(await getApplicationSupportDirectory()).path}/iptv.txt');
  }

  /// 获取缓存直播源
  static Future<String> _getCache() async {
    try {
      final cacheFile = await _getCacheFile();
      if (await cacheFile.exists()) {
        return await cacheFile.readAsString();
      }

      return '';
    } catch (e, st) {
      _logger.handle(e, st);
      return '';
    }
  }

  /// 解析直播源m3u
  static List<IptvGroup> _parseSourceM3u(String source) {
    var groupList = <IptvGroup>[];

    final lines = source.split('\n');

    var channel = 0;
    for (final (lineIdx, line) in lines.indexed) {
      if (!line.startsWith('#EXTINF:')) {
        continue;
      }

      final groupName = RegExp('group-title="(.*?)"').firstMatch(line)?.group(1) ?? '其他';
      final name = line.split(',').last;
      final logo = RegExp('tvg-logo="(.*?)"').firstMatch(line)?.group(1) ?? '';

      if (IptvSettings.iptvSourceSimplify) {
        if (!name.toLowerCase().startsWith('cctv') && !name.endsWith('卫视')) continue;
      }

      final group = groupList.firstWhere((it) => it.name == groupName, orElse: () {
        final group = IptvGroup(idx: groupList.length, name: groupName, list: []);
        groupList.add(group);
        return group;
      });

      late String url;
      for (var i = lineIdx + 1; i < lines.length; i++) {
        final nextLine = lines[i];
        if (!nextLine.startsWith('#') && nextLine.isNotEmpty) {
          url = nextLine;
          break;
        }
      }

      if(group.list.any((iptv)=>iptv.name == name)){
        group.list.elementAt( group.list.indexWhere((element) => element.name == name)).urlList.add(url);
      }else{
        channel = channel + 1;
        final iptv = Iptv(
          idx: group.list.length,
          channel: group.list.length+1,
          groupIdx: group.list.length+1,
          name: name,
          urlList:[url],
          tvgName: RegExp('tvg-name="(.*?)"').firstMatch(line)?.group(1) ?? name,
          logo:logo,
        );
        group.list.add(iptv);
      }
    }
    if(IptvSettings.iptvChannelList.length != channel){
      IptvSettings.iptvChannelList = List<String>.filled(channel, "");
    }
    _logger.debug('Parsing m3u completed: ${groupList.length}Groups, ${channel}Channels');
    return groupList;
  }

  /// 解析直播源tvbox
  static List<IptvGroup> _parseSourceTvbox(String source) {
    var groupList = <IptvGroup>[];

    final lines = source.split('\n');

    var channel = 0;
    IptvGroup? group;
    for (final line in lines) {
      if (line.isEmpty) continue;
      if (line.startsWith('#')) continue;

      if (line.endsWith('#genre#')) {
        final groupName = line.split(',')[0];
        group = IptvGroup(idx: groupList.length, name: groupName, list: []);
        groupList.add(group);
      } else {
        List<String> separators = ['，'];
        final newLine = line.splitMapJoin(
          RegExp('[${separators.map((s) => '\\$s').join('')}]'),
          onMatch: (m) => ',',
          onNonMatch: (n) => n,
        );

        if (newLine.split(',').length < 2) continue;

        final name = newLine.split(',')[0];
        final url = newLine.split(',')[1];
        channel = channel +  1;
        final iptv = Iptv(
          idx: group!.list.length,
          channel:channel,
          groupIdx: group.idx,
          name: name,
          urlList: [url],
          tvgName: name,
          logo: ""
        );

        group.list.add(iptv);
      }
    }

    _logger.debug('Parsing tvbox completed: ${groupList.length}Groups, ${channel}Channels');

    return groupList;
  }

  /// 解析直播源
  static List<IptvGroup> _parseSource(String source) {
    try {
      if (source.startsWith('#EXTM3U')) {
        return _parseSourceM3u(source);
      } else {
        return _parseSourceTvbox(source);
      }
    } catch (e, st) {
      _logger.handle(e, st);
      showToast('Failed to parse the live source, please check the live source format');
      rethrow;
    }
  }

  /// 刷新并获取直播源
  static Future<List<IptvGroup>> refreshAndGet(IPTVCallBack? callBack) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - IptvSettings.iptvSourceCacheTime < IptvSettings.iptvSourceCacheKeepTime) {
      final cache = await _getCache();
      if (cache.isNotEmpty) {
        _logger.debug('Using cached live source');
        return _parseSource(cache);
      }
    }

    IptvSettings.iptvChannelList = [];
    final source = await _fetchSource(callBack);
    final cacheFile = await _getCacheFile();
    print('Cache File: $cacheFile');
    await cacheFile.writeAsString(source);
    IptvSettings.iptvSourceCacheTime = now;
    return _parseSource(source);
  }
}
