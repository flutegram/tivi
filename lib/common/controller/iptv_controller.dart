// Copyright 2024. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:get/get.dart';

import '../index.dart';

class IptvController extends GetxController {
  List<IptvGroup> iptvGroupList = [];

  List<Iptv> get iptvList => iptvGroupList.expand((e) => e.list).toList();

  Rx<Iptv> currentIptv = Iptv.empty.obs;

  RxInt currentChannel = 0.obs;

  RxBool iptvInfoVisible = false.obs;

  RxString channelNo = ''.obs;

  Timer? confirmChannelTimer;

  List<Epg>? epgList;

  Iptv getPrevIptv([Iptv? iptv]) {
    final prevIdx = iptvList.indexOf(iptv ?? currentIptv.value) - 1;
    return prevIdx < 0 ? iptvList.last : iptvList.elementAt(prevIdx);
  }

  Iptv getNextIptv([Iptv? iptv]) {
    final nextIdx = iptvList.indexOf(iptv ?? currentIptv.value) + 1;
    return nextIdx >= iptvList.length
      ? iptvList.first
      : iptvList.elementAt(nextIdx);
  }

  Iptv getPrevGroupIptv([Iptv? iptv]) {
    final prevIdx = (iptv?.groupIdx ?? currentIptv.value.groupIdx) - 1;
    return prevIdx < 0
      ? iptvGroupList.last.list.first
      : iptvGroupList.elementAt(prevIdx).list.first;
  }

  Iptv getNextGroupIptv([Iptv? iptv]) {
    final nextIdx = (iptv?.groupIdx ?? currentIptv.value.groupIdx) + 1;
    return nextIdx >= iptvGroupList.length
      ? iptvGroupList.first.list.first
      : iptvGroupList.elementAt(nextIdx).list.first;
  }

  Future<void> refreshIptvList({IPTVCallBack? callBack}) async {
    iptvGroupList = await IptvUtil.refreshAndGet(callBack);
  }

  Future<void> refreshEpgList({EpgCallBack? callBack}) async {
    epgList = await EpgUtil
      .refreshAndGet(iptvList.map((e) => e.tvgName)
      .toList());
  }

  void inputChannelNo(String no) {
    confirmChannelTimer?.cancel();
    channelNo.value = channelNo.value + no;
    confirmChannelTimer = Timer(
      Duration(seconds: 4 - channelNo.value.length),
      () {
        final channel = int.tryParse(channelNo.value) ?? 0;
        final iptv = iptvList.firstWhere(
          (e) => e.channel == channel,
          orElse: () => currentIptv.value,
        );
        currentIptv = iptv.obs;
        RefreshEvent.refreshVod();
        channelNo = ''.obs;
      },
    );
  }

  ({RxString current, RxString next}) getIptvProgrammes(Iptv iptv) {
    final now = DateTime.now().millisecondsSinceEpoch;

    final epg = epgList?.firstWhereOrNull((e) => e.channel == iptv.tvgName);

    final currentProgramme = epg?.programmes
      .firstWhereOrNull((e) => e.start <= now && e.stop >= now);
    final nextProgramme = epg?.programmes
      .firstWhereOrNull((e) => e.start > now);

    return (
      current: currentProgramme?.title.obs ?? ''.obs,
      next: nextProgramme?.title.obs ?? ''.obs,
    );
  }

  ({RxString current, RxString next}) get currentIptvProgrammes =>
    getIptvProgrammes(currentIptv.value);
}
