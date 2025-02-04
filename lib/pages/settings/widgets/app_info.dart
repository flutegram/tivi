import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsAppInfo extends StatefulWidget {
  const SettingsAppInfo({super.key});

  @override
  State<SettingsAppInfo> createState() => _SettingsAppInfoState();
}

class _SettingsAppInfoState extends State<SettingsAppInfo> {
  final _version = ''.obs;

  _initData() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version.value = packageInfo.version;
    });
  }

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'My TV',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 60.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 20.w),
            Obx( () => Text(
                'v$_version',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  fontSize: 30.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Text(
          'MyTV',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            fontSize: 30.sp,
          ),
        ),
      ],
    );
  }
}
