import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tivi/pages/settings/widgets/app_info.dart';
import 'package:tivi/pages/settings/widgets/settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.only(left: 40).r,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SettingsAppInfo(),
                SizedBox(height: 30.h),
                const SettingsMain(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
