import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:project_setting/core/theme/color.dart';
import 'package:project_setting/core/theme/icon.dart';
import 'package:project_setting/core/theme/spacing.dart';
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
      titleSpacing: 0,
      backgroundColor: WasherColor.backgroundColor,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      title: Padding(
        padding: AppPadding.appBarPadding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            WasherIcon(
              type: WasherIconType.logo,
              size: 40,
            ),
            _NotificationIcon(
              hasNotification: hasNotification,
              onTap: () => context.push('/alarm'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _NotificationIcon extends StatelessWidget {
  final bool hasNotification;
  final VoidCallback? onTap;

  const _NotificationIcon({
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
            child: CircleWidget(color: CircleColor.blue),
          ),
      ],
    );
  }
}
