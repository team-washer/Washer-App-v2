import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/features/report/presentation/widgets/report_broken_dialog.dart';

void main() {
  testWidgets('ReportBrokenDialog renders report form fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        builder: (_, __) => const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ReportBrokenDialog(
                machineId: 1,
                deviceId: 'Washer-3F-L1',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('기기 고장 신고'), findsOneWidget);
    expect(find.text('고장 내용'), findsOneWidget);
    expect(find.text('신고하기'), findsOneWidget);
    expect(find.text('고장 증상이나 특이사항을 자세히 설명해주세요.'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
