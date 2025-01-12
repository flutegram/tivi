// Copyright 2024. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../index.dart';

int _compareVersions(String version1, String version2) {
  final v1 = version1.split('.').map(int.parse).toList();
  final v2 = version2.split('.').map(int.parse).toList();

  for (var i = 0; i < 3; i++) {
    if (v1[i] < v2[i]) {
      return -1;
    } else if (v1[i] > v2[i]) {
      return 1;
    }
  }

  return 0;
}

final _logger = LoggerUtil.create(['renew']);

class UpdateController extends GetxController  {
  String currentVersion = '0.0.0';

  var latestRelease = GithubRelease(
    tagName: 'v0.0.0',
    downloadUrl: '',
    description: '',
  );

  bool get hasUpdate => _compareVersions(
    latestRelease.tagName.substring(1),
    currentVersion,
  ) > 0;

  bool updating = false;

  Future<void> refreshLatestRelease() async {
    if (hasUpdate) {
      return;
    }

    try {
      _logger.debug('Start checking for updates: ${Constants.githubReleaseLatest}');

      currentVersion = (await PackageInfo.fromPlatform()).version;

      final result = jsonDecode(await RequestUtil.get(Constants.githubReleaseLatest));
      latestRelease = GithubRelease(
        tagName: result['tag_name'],
        downloadUrl: result['assets'][0]['browser_download_url'],
        description: result['body'],
      );

      _logger.debug('Check for updates successfully: ${latestRelease.tagName}');

      if (hasUpdate && AppSettings.lastLatestVersion != latestRelease.tagName) {
        showToast('New version found: ${latestRelease.tagName}');
        AppSettings.lastLatestVersion = latestRelease.tagName;
      }else{
        _logger.debug('The current version is the latest version:${AppSettings.lastLatestVersion}');
      }
    } catch (e, st) {
      _logger.handle(e, st);
      showToast('Check for updates failed');
      rethrow;
    }
  }

  Future<void> downloadAndInstall() async {
    if (!hasUpdate) {
      return;
    }
    if (updating) {
      return;
    }

    updating = true;
    _logger.debug('Downloading updates: ${latestRelease.tagName}');
    showToast('Downloading updates: ${latestRelease.tagName}', duration: const Duration(seconds: 10));
    try {
      final path = await RequestUtil.download(
        url: '${Constants.githubProxy}${latestRelease.downloadUrl}',
        directory: (await getApplicationSupportDirectory()).path,
        name: 'my_tv-latest.apk',
        onProgress: (percent) {
          _logger.debug('Downloading updates: ${percent.toInt()}%');
          showToast('Downloading updates: ${percent.toInt()}%', duration: const Duration(seconds: 10));
        },
      );

      _logger.debug('Download update successfully: $path');
      showToast('Download update successfully');

      if (await Permission.requestInstallPackages.request().isGranted) {
        await ApkInstaller.installApk(path);
      } else {
        showToast('Please grant permission to install');
      }
    } catch (e, st) {
      _logger.handle(e, st);
      showToast('Download update failed');
      rethrow;
    } finally {
      updating = false;
    }
  }
}
