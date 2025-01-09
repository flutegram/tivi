import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tivi/common/index.dart';

class PanelPlayerInfo extends StatelessWidget {
  const PanelPlayerInfo({super.key});

  static PlayController get playController => Get.find<PlayController>();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Obx( () => Text(
            'Resolusi：${playController.width.value}×${playController.height.value}',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 30.sp),
          ),
        )
      ],
    );
  }
}
