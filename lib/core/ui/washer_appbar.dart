import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:washer/core/network/auth_notifier.dart';
import 'package:washer/core/router/route_paths.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/icon.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/core/ui/circle_widget.dart';
import 'package:washer/core/ui/dialog/washer_dialog.dart';
import 'package:washer/features/auth/presentation/viewmodels/logout_view_model.dart';
import 'package:washer/features/user/presentation/viewmodels/withdraw_view_model.dart';

class WasherAppbar extends ConsumerWidget implements PreferredSizeWidget {
  static const double _toolbarHeight = 72;
  final bool hasNotification;

  const WasherAppbar({
    super.key,
    this.hasNotification = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      toolbarHeight: _toolbarHeight.h,
      titleSpacing: 0,
      backgroundColor: WasherColor.backgroundColor,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      title: Padding(
        padding: AppPadding.appBarPadding,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                WasherIcon(
                  type: WasherIconType.logo,
                  size: 40,
                ),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _ActionContainer(
                      hasNotification: hasNotification,
                      maxHeight: constraints.maxHeight,
                      onSettingTap: () {
                        showDialog<void>(
                          context: context,
                          builder: (dialogContext) => _SettingDialog(
                            onLogoutTap: () async {
                              final shouldLogout = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) =>
                                    const _LogoutDialog(),
                              );
                              if (shouldLogout != true) {
                                return;
                              }
                              // 로그아웃 처리
                              await ref
                                  .read(logoutViewModelProvider.notifier)
                                  .logout();
                              if (!context.mounted) {
                                return;
                              }

                              context.go(RoutePaths.login);
                            },
                            onWithdrawTap: () async {
                              final shouldWithdraw = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) =>
                                    const _WithdrawDialog(),
                              );
                              if (shouldWithdraw != true) {
                                return;
                              }

                              final didWithdraw = await ref
                                  .read(withdrawViewModelProvider.notifier)
                                  .withdraw();
                              if (!didWithdraw) {
                                return;
                              }
                              if (!context.mounted) {
                                return;
                              }

                              await showDialog<void>(
                                context: context,
                                barrierDismissible: false,
                                builder: (dialogContext) =>
                                    const _WithdrawCompleteDialog(),
                              );
                              if (!context.mounted) {
                                return;
                              }

                              authNotifier.logout();
                              context.go(RoutePaths.login);
                            },
                          ),
                        );
                      },
                      onNotificationTap: () {
                        final location = GoRouterState.of(context).uri.path;
                        final baseRoute = _resolveAlarmBaseRoute(location);
                        context.push('$baseRoute/${RoutePaths.alarmSubRoute}');
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(_toolbarHeight.h);
}

String _resolveAlarmBaseRoute(String location) {
  if (location.startsWith(RoutePaths.dryer)) {
    return RoutePaths.dryer;
  }
  if (location.startsWith(RoutePaths.washer)) {
    return RoutePaths.washer;
  }
  return RoutePaths.home;
}

class _ActionContainer extends StatelessWidget {
  final bool hasNotification;
  final double maxHeight;
  final VoidCallback onSettingTap;
  final VoidCallback onNotificationTap;

  const _ActionContainer({
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
            _NotificationIcon(
              hasNotification: hasNotification,
              onTap: onNotificationTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingDialog extends StatelessWidget {
  final Future<void> Function() onLogoutTap;
  final Future<void> Function() onWithdrawTap;

  const _SettingDialog({
    required this.onLogoutTap,
    required this.onWithdrawTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        width: double.infinity,
        padding: AppPadding.card,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '설정',
              style: WasherTypography.subTitle3(WasherColor.baseGray700),
            ),
            AppGap.v16,
            _SettingMenuItem(
              icon: WasherIconType.logout,
              label: '로그아웃',
              onTap: () async {
                Navigator.of(context).pop();
                await onLogoutTap();
              },
            ),
            AppGap.v8,
            _SettingMenuItem(
              icon: WasherIconType.withDraw,
              label: '회원탈퇴',
              onTap: () async {
                Navigator.of(context).pop();
                await onWithdrawTap();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: WasherDialog(
        title: '로그아웃',
        backText: '취소',
        confirmText: '로그아웃',
        confirmColor: WasherColor.errorColor,
        onBackPressed: () => Navigator.of(context).pop(false),
        onConfirmPressed: () => Navigator.of(context).pop(true),
        content: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.v16),
          child: Text(
            '로그아웃 하시겠습니까?',
            style: WasherTypography.subTitle4(),
          ),
        ),
      ),
    );
  }
}

class _WithdrawDialog extends StatelessWidget {
  const _WithdrawDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: WasherDialog(
        title: '회원탈퇴',
        backText: '취소',
        confirmText: '회원탈퇴',
        confirmColor: WasherColor.errorColor,
        onBackPressed: () => Navigator.of(context).pop(false),
        onConfirmPressed: () => Navigator.of(context).pop(true),
        content: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.v16),
          child: Text(
            'Washer 회원탈퇴를 하시겠습니까?',
            style: WasherTypography.subTitle4(WasherColor.negative),
          ),
        ),
      ),
    );
  }
}

class _WithdrawCompleteDialog extends StatelessWidget {
  const _WithdrawCompleteDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        width: double.infinity,
        padding: AppPadding.card,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.v16),
              child: Text(
                '그동안 Washer를 사용해 주셔서 감사합니다.',
                style: WasherTypography.subTitle4(),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: WasherColor.mainColor400,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.medium,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
                child: Text(
                  '닫기',
                  style: WasherTypography.body1(Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingMenuItem extends StatelessWidget {
  final WasherIconType icon;
  final String label;
  final VoidCallback onTap;

  const _SettingMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.medium,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 10.h),
          child: Row(
            children: [
              WasherIcon(
                type: icon,
                size: 20,
                color: WasherColor.negative,
              ),
              AppGap.h12,
              Text(
                label,
                style: WasherTypography.body2(WasherColor.negative),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                size: 20.sp,
                color: WasherColor.negative,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  final bool hasNotification;
  final VoidCallback onTap;

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
