import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/network/error.dart';
import 'package:washer/shared/ui/buttons/washer_icon_button.dart';
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
  group('대기(FIFO)', () {
    testWidgets('에러 토스트가 떠 있는 동안 온 성공 토스트는 에러가 닫힌 뒤에 뜬다', (tester) async {
      final overlay = await _pumpHost(tester);

      overlay.showToast(
        WasherToast.error(AppException(message: '폴링 실패')),
      );
      await tester.pump();
      overlay.showToast(WasherToast.success('예약이 취소되었습니다.'));
      await tester.pump(const Duration(seconds: 4));

      // 5초가 지나기 전에는 에러가 덮이지 않는다.
      expect(find.text('폴링 실패'), findsOneWidget);
      expect(find.text('예약이 취소되었습니다.'), findsNothing);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(find.text('폴링 실패'), findsNothing);
      expect(find.text('예약이 취소되었습니다.'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      expect(tester.takeException(), isNull);
    });

    testWidgets('대기 중인 토스트는 들어온 순서대로 하나씩 뜬다', (tester) async {
      final overlay = await _pumpHost(tester);

      overlay.showToast(WasherToast.error(AppException(message: '첫 번째')));
      await tester.pump();
      overlay
        ..showToast(WasherToast.error(AppException(message: '두 번째')))
        ..showToast(WasherToast.info('세 번째'));

      for (final (current, next) in [
        ('첫 번째', '두 번째'),
        ('두 번째', '세 번째'),
      ]) {
        expect(find.text(current), findsOneWidget);
        expect(find.text(next), findsNothing);
        expect(
          find.byType(WasherIconButton),
          findsOneWidget,
          reason: '한 번에 하나',
        );

        await tester.tap(find.byType(WasherIconButton));
        await tester.pump();
      }

      expect(find.text('세 번째'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(find.byType(WasherIconButton), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('대기 중인 중복 토스트는 대기 순서를 유지한 채 최신 것 하나만 뜬다', (tester) async {
      final overlay = await _pumpHost(tester);

      overlay.showToast(WasherToast.error(AppException(message: '앞 토스트')));
      await tester.pump();
      overlay
        ..showToast(
          WasherToast.error(AppException(message: '폴링 실패', traceId: 'old')),
        )
        ..showToast(WasherToast.success('예약이 취소되었습니다.'))
        ..showToast(
          WasherToast.error(AppException(message: '폴링 실패', traceId: 'new')),
        );

      await tester.tap(find.byType(WasherIconButton));
      await tester.pump();
      // 먼저 들어온 자리에서, 나중에 온 최신 내용으로 뜬다.
      expect(find.text('폴링 실패'), findsOneWidget);
      expect(find.text('오류 ID: new'), findsOneWidget);

      await tester.tap(find.byType(WasherIconButton));
      await tester.pump();
      expect(find.text('예약이 취소되었습니다.'), findsOneWidget);

      await tester.tap(find.byType(WasherIconButton));
      await tester.pump();
      expect(find.byType(WasherIconButton), findsNothing, reason: '중복은 한 번만');
    });

    testWidgets('떠 있는 토스트와 같은 토스트는 다시 띄우지 않는다', (tester) async {
      final overlay = await _pumpHost(tester);

      overlay.showToast(WasherToast.error(AppException(message: '폴링 실패')));
      // 노출 시간은 토스트를 그린 다음 프레임부터 센다.
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      overlay.showToast(WasherToast.error(AppException(message: '폴링 실패')));
      await tester.pump();

      // 노출 시간도 다시 시작하지 않는다(처음 뜬 시점부터 5초).
      await tester.pump(const Duration(milliseconds: 1900));
      expect(find.byType(WasherIconButton), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      expect(find.byType(WasherIconButton), findsNothing, reason: '대기열에도 없다');
    });

    testWidgets('메시지가 같아도 종류가 다르면 중복이 아니다', (tester) async {
      final overlay = await _pumpHost(tester);

      overlay.showToast(WasherToast.info('같은 문구'));
      await tester.pump();
      overlay.showToast(WasherToast.success('같은 문구'));

      await tester.tap(find.byType(WasherIconButton));
      await tester.pump();
      expect(find.text('같은 문구'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('토스트가 떠 있던 화면이 사라져도 이후 토스트가 대기에 갇히지 않는다', (tester) async {
      final oldOverlay = await _pumpHost(tester);
      oldOverlay.showToast(WasherToast.error(Exception('이전 화면')));
      await tester.pump();

      // 닫기 전에 화면 트리를 통째로 교체한다.
      await tester.pumpWidget(const SizedBox());
      final overlay = await _pumpHost(tester);

      overlay.showToast(WasherToast.info('새 화면 안내'));
      await tester.pump();

      expect(find.text('새 화면 안내'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });
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
