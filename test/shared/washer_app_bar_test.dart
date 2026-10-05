import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:washer/core/router/route_paths.dart';
import 'package:washer/shared/theme/washer_icon.dart';
import 'package:washer/shared/ui/buttons/washer_icon_button.dart';
import 'package:washer/shared/ui/layout/main_shell.dart';

const _alarmText = '알림 화면';

GoRoute _alarmRoute() => GoRoute(
  path: RoutePaths.alarmSubRoute,
  pageBuilder: (context, state) =>
      const NoTransitionPage(child: Text(_alarmText)),
);

/// 실제 앱과 같은 탭 구조(건조기/홈/세탁기 + 탭별 알림 하위 경로)의 라우터.
/// 알림 화면은 네트워크를 쓰지 않도록 텍스트로 대신한다.
GoRouter _buildRouter(String initialLocation) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        for (final path in [
          RoutePaths.dryer,
          RoutePaths.home,
          RoutePaths.washer,
        ])
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: path,
                builder: (context, state) => Text('탭 $path'),
                routes: [_alarmRoute()],
              ),
            ],
          ),
      ],
    ),
  ],
);

Future<GoRouter> _pumpApp(WidgetTester tester, String initialLocation) async {
  final router = _buildRouter(initialLocation);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: ScreenUtilInit(
        designSize: const Size(412, 917),
        // 테스트 환경에서 ink sparkle 셰이더를 로드하지 못하므로 스플래시를 끈다.
        builder: (_, __) => MaterialApp.router(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Future<void> _tapNotification(WidgetTester tester) async {
  await tester.tap(
    find.byWidgetPredicate(
      (widget) =>
          widget is WasherIconButton &&
          widget.type == WasherIconType.notification,
    ),
  );
  await tester.pumpAndSettle();
}

int _alarmPageCount() =>
    find.text(_alarmText, skipOffstage: false).evaluate().length;

void main() {
  group('앱바 알림 버튼', () {
    for (final tab in [RoutePaths.dryer, RoutePaths.home, RoutePaths.washer]) {
      testWidgets('$tab 탭에서 누르면 해당 탭의 알림 화면을 연다', (tester) async {
        final router = await _pumpApp(tester, tab);

        await _tapNotification(tester);

        expect(
          router.state.uri.path,
          '$tab/${RoutePaths.alarmSubRoute}',
        );
        expect(_alarmPageCount(), 1);
      });
    }

    testWidgets('알림 화면에서 다시 눌러도 알림 화면을 쌓지 않는다', (tester) async {
      final router = await _pumpApp(tester, RoutePaths.washer);

      await _tapNotification(tester);
      await _tapNotification(tester);
      await _tapNotification(tester);

      expect(_alarmPageCount(), 1);

      // 뒤로가기 한 번이면 탭 첫 화면으로 돌아간다.
      router.pop();
      await tester.pumpAndSettle();

      expect(router.state.uri.path, RoutePaths.washer);
      expect(_alarmPageCount(), 0);
      expect(find.text('탭 ${RoutePaths.washer}'), findsOneWidget);
    });
  });
}
