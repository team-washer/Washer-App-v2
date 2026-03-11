import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/features/alarm/presentation/screens/alarm_screen.dart';
import 'package:washer/features/auth/presentation/screens/auth_webview_screen.dart';
import 'package:washer/features/auth/presentation/screens/login_screen.dart';
import 'package:washer/features/reservation/presentation/screens/reservation_screen.dart';
import 'package:washer/core/ui/main_shell.dart';
import 'package:washer/features/home/presentation/screens/home_screen.dart';
import 'route_paths.dart';

const _storage = FlutterSecureStorage();

final appRouter = GoRouter(
  initialLocation: RoutePaths.login,
  redirect: (context, state) async {
    final token = await _storage.read(key: 'access_token');
    final hasToken = token != null && token.isNotEmpty;
    final location = state.matchedLocation;
    final isAuthRoute =
        location == RoutePaths.login || location == RoutePaths.authWebView;

    if (!hasToken && !isAuthRoute) return RoutePaths.login;
    if (hasToken && isAuthRoute) return RoutePaths.home;
    return null;
  },
  routes: [
    // ============================================
    // Auth Routes - 인증 화면
    // ============================================
    GoRoute(
      path: RoutePaths.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: RoutePaths.authWebView,
      builder: (context, state) => const AuthWebViewScreen(),
    ),
    // ============================================
    // Main Shell - 하단 탭 네비게이션
    // ============================================
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        // ----------------------------------------
        // Tab 1: 건조기 화면
        // ----------------------------------------
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

        // ----------------------------------------
        // Tab 2: 홈 화면 (기본)
        // ----------------------------------------
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),

        // ----------------------------------------
        // Tab 3: 세탁기 화면
        // ----------------------------------------
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

    // ============================================
    // Standalone Routes - 탭 외부 화면
    // ============================================

    // 알림 화면
    GoRoute(
      path: RoutePaths.alarm,
      builder: (context, state) => AlarmScreen(),
    ),
  ],
);
