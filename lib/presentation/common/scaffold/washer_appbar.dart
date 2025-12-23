import 'package:flutter/material.dart';
import 'package:project_setting/core/theme/icon.dart';
import 'package:project_setting/presentation/common/circle_widget.dart';

class WasherAppbar extends StatelessWidget implements PreferredSizeWidget {
  final bool hasNotification;

  const WasherAppbar({
    super.key,
    this.hasNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            WasherIcon(
              type: WasherIconType.logo,
              size: 40,
            ),
            _buildNotificationIcon(
              onTap: () {
                // 알림 아이콘 클릭 시 동작할 코드 작성
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon({required Function()? onTap}) {
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            WasherIcon(
              type: WasherIconType.notification,
              size: 24,
              onTap: onTap,
            ),
            if (hasNotification)
              Positioned(
                right: 0,
                top: 0,
                child: CircleWidget(color: CircleColor.blue),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
