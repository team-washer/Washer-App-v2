import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/network/error.dart';
import 'package:washer/shared/theme/washer_icon.dart';
import 'package:washer/shared/ui/washer_toast.dart';

Future<OverlayState> _pumpHost(WidgetTester tester) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(412, 917),
      // 테스트 환경에서 ink sparkle 셰이더를 로드하지 못하므로 스플래시를 끈다.
      builder: (_, __) => MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: const Scaffold(),
      ),
    ),
  );
  return tester.state<OverlayState>(find.byType(Overlay).first);
}

void main() {
  testWidgets('토스트를 연속으로 띄우면 이전 토스트는 교체되고 예외가 없다', (tester) async {
    final overlay = await _pumpHost(tester);

    overlay.showToast(WasherToast.error(Exception('first')));
    await tester.pump(const Duration(seconds: 4));
    overlay.showToast(WasherToast.error(Exception('second')));
    await tester.pump();

    expect(find.byType(WasherIconButton), findsOneWidget);

    // 첫 토스트의 5초가 지나도 이미 제거된 entry를 다시 지우지 않아야 한다.
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    expect(find.byType(WasherIconButton), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    expect(find.byType(WasherIconButton), findsNothing);
  });

  testWidgets('원인 문구와 함께 입력 오류 항목과 문의용 오류 ID를 보여준다', (tester) async {
    final overlay = await _pumpHost(tester);

    overlay.showToast(
      WasherToast.error(
        AppException(
          message: '입력한 정보를 다시 확인해주세요.',
          statusCode: 400,
          errorCode: 'VALIDATION_FAILED',
          traceId: 'trace-abc',
          fieldErrors: const [
            {'field': 'machineId', 'message': '기기 ID는 필수입니다'},
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.text('입력한 정보를 다시 확인해주세요.'), findsOneWidget);
    expect(find.text('· 기기 ID는 필수입니다'), findsOneWidget);
    expect(find.text('오류 ID: trace-abc'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('같은 프레임에 닫기가 두 번 호출돼도 한 번만 제거된다', (tester) async {
    final overlay = await _pumpHost(tester);

    overlay.showToast(WasherToast.error(Exception('boom')));
    await tester.pump();

    // tap은 프레임을 진행하지 않으므로 두 번째 탭 시점에도 위젯이 트리에 남아 있다.
    await tester.tap(find.byType(WasherIconButton));
    await tester.tap(find.byType(WasherIconButton), warnIfMissed: false);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(WasherIconButton), findsNothing);
  });

  testWidgets('앱이 스스로 취소한 요청은 토스트를 띄우지 않는다', (tester) async {
    final overlay = await _pumpHost(tester);

    overlay.showToast(
      WasherToast.error(
        DioException(
          requestOptions: RequestOptions(path: '/reservations'),
          type: DioExceptionType.cancel,
          error: '인증 토큰 갱신에 실패했습니다.',
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(WasherIconButton), findsNothing);
  });

  group('종류별 동작', () {
    /// 화면 아래쪽에 누를 수 있는 버튼이 있는 호스트. 토스트가 화면을 막는지 확인한다.
    Future<(OverlayState, int Function())> pumpWithButton(
      WidgetTester tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(412, 917),
          builder: (_, __) => MaterialApp(
            theme: ThemeData(splashFactory: NoSplash.splashFactory),
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: TextButton(
                  onPressed: () => taps += 1,
                  child: const Text('뒤 화면 버튼'),
                ),
              ),
            ),
          ),
        ),
      );
      return (
        tester.state<OverlayState>(find.byType(Overlay).first),
        () => taps,
      );
    }

    for (final (name, toast) in [
      ('성공', WasherToast.success('예약이 취소되었습니다.')),
      ('안내', WasherToast.info('예약 후 자동으로 기기 연결 확인이 진행됩니다.')),
    ]) {
      testWidgets('$name 토스트는 화면을 막지 않고 3초 뒤 닫히며 문의 안내가 없다', (tester) async {
        final (overlay, taps) = await pumpWithButton(tester);

        overlay.showToast(toast);
        await tester.pump();

        expect(find.byType(WasherIconButton), findsOneWidget);
        expect(find.textContaining('관리자에게 문의'), findsNothing);

        await tester.tap(find.text('뒤 화면 버튼'));
        expect(taps(), 1, reason: '뒤 화면을 그대로 쓸 수 있어야 한다');

        // 노출 시간은 토스트를 그린 다음 프레임부터 센다.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 2900));
        expect(find.byType(WasherIconButton), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump();
        expect(find.byType(WasherIconButton), findsNothing);
      });
    }

    testWidgets('에러 토스트는 딤 배경으로 뒤 화면 조작을 막고 문의 안내를 보여준다', (tester) async {
      final (overlay, taps) = await pumpWithButton(tester);

      overlay.showToast(WasherToast.error(Exception('boom')));
      await tester.pump();

      expect(find.textContaining('관리자에게 문의'), findsOneWidget);

      await tester.tap(find.text('뒤 화면 버튼'), warnIfMissed: false);
      expect(taps(), 0);

      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(WasherIconButton), findsOneWidget, reason: '5초 동안 유지');

      await tester.pump(const Duration(seconds: 3));
    });
  });
}
