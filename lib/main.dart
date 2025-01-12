// Copyright 2024. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:oktoast/oktoast.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'common/index.dart';
import 'pages/iptv/page/iptv_view.dart';


void main() async {
  MediaKit.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    statusBarColor: Colors.transparent,
  ));
  await WakelockPlus.enable();
  await PrefsUtil.init();
  LoggerUtil.init();
  RequestUtil.init();

  Get.put(PlayController());
  Get.put(IptvController());
  Get.put(UpdateController());

  runApp(const MyApp());
}

class NoThumbScrollBehavior extends ScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const colorScheme = ColorScheme.dark(surface: Colors.black);

    return ScreenUtilInit(
      designSize: const Size(1920, 1080),
      minTextAdapt: true,
      splitScreenMode: true,
      child: RestartWidget(
        child: GetMaterialApp(
          title: 'JowoTV',
          theme: ThemeData(
            colorScheme: colorScheme,
          ),
          scrollBehavior: NoThumbScrollBehavior().copyWith(scrollbars: false),
          localizationsDelegates: const [...GlobalMaterialLocalizations.delegates, GlobalWidgetsLocalizations.delegate],
          supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
          home: const DelayRenderer(
            child: DoubleBackExit(
              child: IptvPage(),
            ),
          ),
          builder: (context, widget) => OKToast(
            position: const ToastPosition(align: Alignment.topCenter, offset: 0),
            textPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            dismissOtherOnShow: true,
            child: widget!,
          ),
        ),
      ),
    );
  }
}
