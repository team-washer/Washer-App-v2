import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_icon.dart';
import 'package:washer/shared/ui/indicators/status_dot.dart';

/// 앱바 우측의 설정/알림 아이콘 묶음(흰 알약 컨테이너).
class AppBarActions extends StatelessWidget {
  final bool hasNotification;
  final double maxHeight;
  final VoidCallback onSettingTap;
  final VoidCallback onNotificationTap;

  const AppBarActions({
    super.key,
    required this.hasNotification,
    required this.maxHeight,
    required this.onSettingTap,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
        ),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.circular,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            WasherIconButton(
              type: WasherIconType.setting,
              size: 24,
              onTap: onSettingTap,
            ),
            Container(
              width: 1,
              height: 24.h,
              color: WasherColor.baseGray700,
            ),
            _NotificationIconButton(
              hasNotification: hasNotification,
              onTap: onNotificationTap,
            ),
          ],
        ),
      ),
    );
  }
}

/// 알림 아이콘. [hasNotification]이 true면 우상단에 파란 점을 표시한다.
class _NotificationIconButton extends StatelessWidget {
  final bool hasNotification;
  final VoidCallback onTap;

  const _NotificationIconButton({
    required this.hasNotification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        WasherIconButton(
          type: WasherIconType.notification,
          size: 24,
          onTap: onTap,
        ),
        if (hasNotification)
          const Positioned(
            right: 0,
            top: 0,
            child: StatusDot(color: StatusDotColor.blue),
          ),
      ],
    );
  }
}
