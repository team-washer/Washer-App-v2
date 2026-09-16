import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/network/auth_notifier.dart';
import 'package:washer/core/network/token_utils.dart';
import 'package:washer/shared/ui/main_shell.dart';
import 'package:washer/features/alarm/presentation/screens/alarm_screen.dart';
import 'package:washer/features/auth/presentation/screens/login_screen.dart';
import 'package:washer/features/home/presentation/screens/home_screen.dart';
import 'package:washer/features/reservation/presentation/screens/reservation_screen.dart';
import 'package:washer/splash_screen.dart';

import 'route_paths.dart';

const _storage = FlutterSecureStorage();

/// 토큰 상태와 목적지만으로 리다이렉트 대상을 정한다.
///
/// 저장소 접근과 토큰 삭제는 [appRouter] 에 남기고 판단만 분리해서,
/// 인증 게이트를 기기 없이 검증할 수 있게 한다.
String? resolveAuthRedirect({
  required String location,
  required String? accessToken,
  required String? refreshToken,
  DateTime? now,
}) {
  final hasRefreshToken =
      refreshToken != null &&
      refreshToken.isNotEmpty &&
      !TokenUtils.isExpired(refreshToken, now: now);
  final hasValidAccessToken =
      accessToken != null &&
      accessToken.isNotEmpty &&
      !TokenUtils.isExpired(accessToken, now: now);
  final hasSession = hasValidAccessToken || hasRefreshToken;
  final isSplashRoute = location == RoutePaths.splash;
  final isAuthRoute = location == RoutePaths.login;

  if (isSplashRoute) {
    return null;
  }

  if (!hasSession && !isAuthRoute) {
    return RoutePaths.login;
  }

  if (hasSession && isAuthRoute) {
    return RoutePaths.splash;
  }

  return null;
}

final appRouter = GoRouter(
  initialLocation: RoutePaths.splash,
  refreshListenable: authNotifier,
  redirect: (context, state) async {
    final accessToken = await _storage.read(key: 'access_token');
    final refreshToken = await _storage.read(key: 'refresh_token');
    final destination = resolveAuthRedirect(
      location: state.matchedLocation,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    if (destination == RoutePaths.login) {
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
    }

    return destination;
  },
  routes: [
    GoRoute(
      path: RoutePaths.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: RoutePaths.login,
      builder: (context, state) => const LoginScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.dryer,
              builder: (context, state) => const ReservationScreen(
                laundryMachineType: LaundryMachineType.dryer,
              ),
              routes: [
                GoRoute(
                  path: RoutePaths.alarmSubRoute,
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: AlarmScreen(),
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.home,
              builder: (context, state) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: RoutePaths.alarmSubRoute,
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: AlarmScreen(),
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.washer,
              builder: (context, state) => const ReservationScreen(
                laundryMachineType: LaundryMachineType.washer,
              ),
              routes: [
                GoRoute(
                  path: RoutePaths.alarmSubRoute,
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: AlarmScreen(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
