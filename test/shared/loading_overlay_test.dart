import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/shared/ui/loading_overlay.dart';

void main() {
  testWidgets('작업 중 로딩을 표시하고 정상 완료 후 entry를 정리한다', (tester) async {
    final action = Completer<int>();
    late BuildContext context;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox();
          },
        ),
      ),
    );

    final result = showLoadingWhile(context, () => action.future);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<ColoredBox>(find.byType(ColoredBox).last).color,
      const Color(0x66000000),
    );

    action.complete(42);
    expect(await result, 42);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('작업이 예외로 끝나도 entry를 정리한다', (tester) async {
    final action = Completer<void>();
    late BuildContext context;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox();
          },
        ),
      ),
    );

    final result = showLoadingWhile(context, () => action.future);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    action.completeError(StateError('실패'));
    await expectLater(result, throwsStateError);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('작업 도중 overlay가 먼저 해제돼도 정리 오류가 발생하지 않는다', (
    tester,
  ) async {
    final action = Completer<void>();
    late OverlayState overlay;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            overlay = Overlay.of(context, rootOverlay: true);
            return const SizedBox();
          },
        ),
      ),
    );

    final result = runWithLoadingOverlay(overlay, () => action.future);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    expect(overlay.mounted, isFalse);

    action.complete();
    await result;
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('이미 해제된 overlay에서는 entry 없이 작업만 실행한다', (tester) async {
    late OverlayState overlay;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            overlay = Overlay.of(context, rootOverlay: true);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox());

    var calls = 0;
    final result = await runWithLoadingOverlay(overlay, () async {
      calls += 1;
      return 7;
    });

    expect(result, 7);
    expect(calls, 1);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
