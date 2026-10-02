import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/network/error.dart';
import 'package:washer/shared/ui/dialog/dialog_action.dart';

DialogAction<bool> _failingAction({
  Object? Function(ProviderContainer container)? failureError,
}) => DialogAction<bool>(
  run: (_) async => false,
  isSuccess: (result) => result,
  successMessage: '성공했습니다.',
  fallbackMessage: '처리에 실패했습니다.',
  failureError: failureError,
  logName: 'TestAction',
);

/// [action]을 실행하는 버튼 하나만 있는 화면을 띄우고 누른다.
Future<void> _run(WidgetTester tester, DialogAction<bool> action) async {
  await tester.pumpWidget(
    ProviderScope(
      child: ScreenUtilInit(
        designSize: const Size(412, 917),
        // 테스트 환경에서 ink sparkle 셰이더를 로드하지 못하므로 스플래시를 끈다.
        builder: (_, __) => MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    runDialogAction(context, action, popFirst: false),
                child: const Text('실행'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('실행'));
  await tester.pump();
}

void main() {
  testWidgets('성공하면 스낵바가 아닌 성공 토스트로 성공 문구를 보여준다', (tester) async {
    await _run(
      tester,
      DialogAction<bool>(
        run: (_) async => true,
        isSuccess: (result) => result,
        successMessage: '성공했습니다.',
        fallbackMessage: '처리에 실패했습니다.',
        logName: 'TestAction',
      ),
    );

    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('성공했습니다.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('실패 원인 정보가 없어도 스낵바가 아닌 에러 토스트로 기본 문구를 보여준다', (tester) async {
    await _run(tester, _failingAction());

    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('처리에 실패했습니다.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('실패 원인 정보가 있으면 그 문구로 에러 토스트를 보여준다', (tester) async {
    await _run(
      tester,
      _failingAction(
        failureError: (_) => AppException(message: '원인별 안내 문구'),
      ),
    );

    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('원인별 안내 문구'), findsOneWidget);
    expect(find.text('처리에 실패했습니다.'), findsNothing);

    await tester.pump(const Duration(seconds: 6));
  });
}
