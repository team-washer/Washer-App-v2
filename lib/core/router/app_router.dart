import 'package:go_router/go_router.dart';
import 'package:project_setting/core/enums/laundry_machine_type.dart';
import 'package:project_setting/presentation/alarm/screen/alarm_screen.dart';
import 'package:project_setting/presentation/reservation/screens/reservation_screen.dart';
import '../../presentation/common/scaffold/main_shell.dart';
import '../../presentation/home/screen/home_screen.dart';
import 'route_paths.dart';

final appRouter = GoRouter(
  initialLocation: RoutePaths.home,
  routes: [
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
