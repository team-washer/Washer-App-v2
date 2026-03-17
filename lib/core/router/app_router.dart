import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/network/auth_notifier.dart';
import 'package:washer/core/network/token_utils.dart';
import 'package:washer/core/ui/main_shell.dart';
import 'package:washer/features/alarm/presentation/screens/alarm_screen.dart';
import 'package:washer/features/auth/presentation/screens/auth_webview_screen.dart';
import 'package:washer/features/auth/presentation/screens/login_screen.dart';
import 'package:washer/features/home/presentation/screens/home_screen.dart';
import 'package:washer/features/reservation/presentation/screens/reservation_screen.dart';
import 'package:washer/splash_screen.dart';

import 'route_paths.dart';

const _storage = FlutterSecureStorage();

final appRouter = GoRouter(
  initialLocation: RoutePaths.splash,
  refreshListenable: authNotifier,
  redirect: (context, state) async {
    final accessToken = await _storage.read(key: 'access_token');
    final refreshToken = await _storage.read(key: 'refresh_token');
    final hasRefreshToken = refreshToken != null && refreshToken.isNotEmpty;
    final hasValidAccessToken =
        accessToken != null &&
        accessToken.isNotEmpty &&
        !TokenUtils.isExpired(accessToken);
    final hasSession = hasValidAccessToken || hasRefreshToken;
    final location = state.matchedLocation;
    final isSplashRoute = location == RoutePaths.splash;
    final isAuthRoute =
        location == RoutePaths.login || location == RoutePaths.authWebView;

    if (isSplashRoute) {
      return null;
    }

    if (!hasSession && !isAuthRoute) {
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
      return RoutePaths.login;
    }

    if (hasSession && isAuthRoute) {
      return RoutePaths.splash;
    }

    return null;
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
    GoRoute(
      path: RoutePaths.authWebView,
      builder: (context, state) => const AuthWebViewScreen(),
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
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.home,
              builder: (context, state) => const HomeScreen(),
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
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: RoutePaths.alarm,
      builder: (context, state) => AlarmScreen(),
    ),
  ],
);
