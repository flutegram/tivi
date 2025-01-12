// Copyright 2024. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../index.dart';

enum PlayerState {
  waiting,
  playing,
  failed,
}

final _logger = LoggerUtil.create(['Player']);

class PlayController extends GetxController {
  static IptvController get iptvController => Get.find<IptvController>();

  final Player player = Player();

  late final VideoController controller = VideoController(player);

  RxInt width = 0.obs;

  RxInt height = 0.obs;

  Rx<PlayerState> state = PlayerState.waiting.obs;

  RxString msg = ''.obs;

  @override
  Future<void> onInit() async {
    super.onInit();

    player.stream.buffering.listen((event){
      if(event && state.value == PlayerState.waiting){
        state.value = PlayerState.playing;
        _logger.debug('Parsing playback connection');
      }
      if(event == false && state.value != PlayerState.waiting){
        if(state.value != PlayerState.failed){
          RefreshEvent.hiddenDelayIptv();
          _logger.debug('Playback successful');
        }else{
          RefreshEvent.showIptv();
          final (channel, ipTv) = (
            iptvController.currentChannel,
            iptvController.currentIptv,
          );
          if(channel.value + 1 < ipTv.value.urlList.length){
            RefreshEvent.changeIptv();
          }
          _logger.debug('Playback failed');
        }
      }
    });

    player.stream.error.listen((event) {
      _logger.debug('Error:$event');
      msg.value  = event;
      state.value = PlayerState.failed;
      player.stop();
    });

    player.stream.log.listen((log) {
      _logger.debug('Log:$log');
    });


    player.stream.height.listen((data) {
      if (data != null) {
        height.value = data;
      } else {
        height.value = 0;
      }
    });

    player.stream.width.listen((data) {
      if (data != null) {
        width.value = data;
      } else {
        width.value = 0;
      }
    });
  }

  Future<void> playIptv(Iptv iptv) async {
    try {
      final channelList = IptvSettings.iptvChannelList;
      final initialChannelIdx = channelList[iptv.idx].isEmpty
        ? 0
        : int.parse(IptvSettings.iptvChannelList[iptv.idx]);
      iptvController.currentChannel.value = initialChannelIdx;
      channelList[iptv.idx] = initialChannelIdx.toString();
      IptvSettings.iptvChannelList = channelList;
      state.value = PlayerState.waiting;
      _logger.debug('Play live source: ${iptv.urlList.elementAt(initialChannelIdx)},Source idx:$initialChannelIdx');
      unawaited(player.open(Media(iptv.urlList.elementAt(initialChannelIdx))));
    } catch (e, st) {
      _logger.handle(e, st);
      state.value = PlayerState.failed;
      rethrow;
    }
  }
}
