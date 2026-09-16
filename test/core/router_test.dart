import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:washer/core/router/app_router.dart';
import 'package:washer/core/router/route_paths.dart';

/// exp 만 담은 최소 JWT. TokenUtils 가 payload 의 exp 만 보므로 서명은 필요 없다.
String tokenExpiringAt(DateTime expiry) {
  final payload = base64Url.encode(
    utf8.encode(
      jsonEncode({'exp': expiry.toUtc().millisecondsSinceEpoch ~/ 1000}),
    ),
  );
  return 'header.$payload.signature';
}

Set<String> collectPaths(List<RouteBase> routes, [String prefix = '']) {
  final paths = <String>{};
  for (final route in routes) {
    var current = prefix;
    if (route is GoRoute) {
      current = route.path.startsWith('/')
          ? route.path
          : '$prefix/${route.path}';
      paths.add(current);
    }
    paths.addAll(collectPaths(route.routes, current));
  }
  return paths;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.utc(2026, 1, 1, 12);
  final live = tokenExpiringAt(now.add(const Duration(hours: 1)));
  final dead = tokenExpiringAt(now.subtract(const Duration(hours: 1)));

  group('appRouter 라우트 테이블', () {
    test('앱이 진입하는 모든 경로가 등록되어 있다', () {
      final paths = collectPaths(appRouter.configuration.routes);

      expect(
        paths,
        containsAll([
          RoutePaths.splash,
          RoutePaths.login,
          RoutePaths.home,
          RoutePaths.washer,
          RoutePaths.dryer,
          '${RoutePaths.home}/${RoutePaths.alarmSubRoute}',
          '${RoutePaths.washer}/${RoutePaths.alarmSubRoute}',
          '${RoutePaths.dryer}/${RoutePaths.alarmSubRoute}',
        ]),
      );
    });

    test('초기 경로는 스플래시다', () {
      expect(appRouter.configuration.routes, isNotEmpty);
      expect(
        collectPaths(appRouter.configuration.routes),
        contains(RoutePaths.splash),
      );
    });
  });

  group('resolveAuthRedirect', () {
    test('세션이 없으면 보호된 경로에서 로그인으로 보낸다', () {
      for (final path in [
        RoutePaths.home,
        RoutePaths.washer,
        RoutePaths.dryer,
      ]) {
        expect(
          resolveAuthRedirect(
            location: path,
            accessToken: null,
            refreshToken: null,
            now: now,
          ),
          RoutePaths.login,
          reason: path,
        );
      }
    });

    test('스플래시는 세션이 없어도 통과시킨다', () {
      expect(
        resolveAuthRedirect(
          location: RoutePaths.splash,
          accessToken: null,
          refreshToken: null,
          now: now,
        ),
        isNull,
      );
    });

    test('세션이 있으면 로그인 화면에서 스플래시로 되돌린다', () {
      expect(
        resolveAuthRedirect(
          location: RoutePaths.login,
          accessToken: live,
          refreshToken: dead,
          now: now,
        ),
        RoutePaths.splash,
      );
    });

    test('액세스 토큰이 만료돼도 리프레시가 살아있으면 통과시킨다', () {
      expect(
        resolveAuthRedirect(
          location: RoutePaths.home,
          accessToken: dead,
          refreshToken: live,
          now: now,
        ),
        isNull,
      );
    });

    test('양쪽 토큰이 모두 만료되면 로그인으로 보낸다', () {
      expect(
        resolveAuthRedirect(
          location: RoutePaths.home,
          accessToken: dead,
          refreshToken: dead,
          now: now,
        ),
        RoutePaths.login,
      );
    });

    test('세션이 없을 때 로그인 화면은 그대로 둔다(리다이렉트 루프 방지)', () {
      expect(
        resolveAuthRedirect(
          location: RoutePaths.login,
          accessToken: null,
          refreshToken: null,
          now: now,
        ),
        isNull,
      );
    });
  });
}
