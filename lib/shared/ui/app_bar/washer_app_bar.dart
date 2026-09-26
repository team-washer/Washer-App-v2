import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:washer/core/network/auth_notifier.dart';
import 'package:washer/core/router/route_paths.dart';
import 'package:washer/shared/ui/error_toast.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_icon.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/ui/app_bar/app_bar_actions.dart';
import 'package:washer/shared/ui/app_bar/logout_confirm_dialog.dart';
import 'package:washer/shared/ui/app_bar/setting_dialog.dart';
import 'package:washer/shared/ui/app_bar/withdraw_complete_dialog.dart';
import 'package:washer/shared/ui/app_bar/withdraw_confirm_dialog.dart';
import 'package:washer/features/auth/presentation/providers/logout_provider.dart';
import 'package:washer/features/user/presentation/providers/withdraw_provider.dart';

/// 메인 화면 공통 앱바. 로고와 설정/알림 버튼을 표시하며,
/// 설정 메뉴의 로그아웃·회원탈퇴 흐름도 여기서 조율한다.
class WasherAppBar extends ConsumerWidget implements PreferredSizeWidget {
  static const double _toolbarHeight = 72;
  final bool hasNotification;

  const WasherAppBar({
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
                    child: AppBarActions(
                      hasNotification: hasNotification,
                      maxHeight: constraints.maxHeight,
                      onSettingTap: () {
                        showDialog<void>(
                          context: context,
                          builder: (dialogContext) => SettingDialog(
                            onLogoutTap: () async {
                              final shouldLogout = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) =>
                                    const LogoutConfirmDialog(),
                              );
                              if (shouldLogout != true) {
                                return;
                              }
                              // 로그아웃 처리
                              await ref.read(logoutProvider.notifier).logout();
                              if (!context.mounted) {
                                return;
                              }

                              context.go(RoutePaths.login);
                            },
                            onWithdrawTap: () async {
                              final shouldWithdraw = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) =>
                                    const WithdrawConfirmDialog(),
                              );
                              if (shouldWithdraw != true) {
                                return;
                              }

                              final didWithdraw = await ref
                                  .read(withdrawProvider.notifier)
                                  .withdraw();
                              if (!didWithdraw) {
                                if (context.mounted) {
                                  context.showErrorToast(
                                    ref.read(withdrawProvider).error,
                                  );
                                }
                                return;
                              }
                              if (!context.mounted) {
                                return;
                              }

                              await showDialog<void>(
                                context: context,
                                barrierDismissible: false,
                                builder: (dialogContext) =>
                                    const WithdrawCompleteDialog(),
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

/// 현재 경로가 속한 탭(건조기/세탁기/홈)의 루트 경로를 찾아 알림 화면의 상위 경로로 쓴다.
String _resolveAlarmBaseRoute(String location) {
  if (location.startsWith(RoutePaths.dryer)) {
    return RoutePaths.dryer;
  }
  if (location.startsWith(RoutePaths.washer)) {
    return RoutePaths.washer;
  }
  return RoutePaths.home;
}
