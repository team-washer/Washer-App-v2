import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/common/scaffold/main_shell.dart';
import '../../presentation/home/screen/home_screen.dart';
import 'route_paths.dart';

final appRouter = GoRouter(
  initialLocation: RoutePaths.home,

  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.dryer,
              builder: (context, state) => const Placeholder(), // DryerScreen()
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.home,
              builder: (context, state) => const HomeScreen(), // HomeScreen()
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.washer,
              builder: (context, state) =>
                  const Placeholder(), // WasherScreen()
            ),
          ],
        ),
      ],
    ),

    // 탭 밖 라우트들
    GoRoute(
      path: RoutePaths.alarm,
      builder: (context, state) => const Placeholder(), // AlarmScreen()
    ),
  ],
);

