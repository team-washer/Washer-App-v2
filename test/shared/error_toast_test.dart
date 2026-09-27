import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/shared/theme/washer_icon.dart';
import 'package:washer/shared/ui/error_toast.dart';

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

    overlay.showErrorToast(Exception('first'));
    await tester.pump(const Duration(seconds: 4));
    overlay.showErrorToast(Exception('second'));
    await tester.pump();

    expect(find.byType(WasherIconButton), findsOneWidget);

    // 첫 토스트의 5초가 지나도 이미 제거된 entry를 다시 지우지 않아야 한다.
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    expect(find.byType(WasherIconButton), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    expect(find.byType(WasherIconButton), findsNothing);
  });

  testWidgets('같은 프레임에 닫기가 두 번 호출돼도 한 번만 제거된다', (tester) async {
    final overlay = await _pumpHost(tester);

    overlay.showErrorToast(Exception('boom'));
    await tester.pump();

    // tap은 프레임을 진행하지 않으므로 두 번째 탭 시점에도 위젯이 트리에 남아 있다.
    await tester.tap(find.byType(WasherIconButton));
    await tester.tap(find.byType(WasherIconButton), warnIfMissed: false);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(WasherIconButton), findsNothing);
  });
}
