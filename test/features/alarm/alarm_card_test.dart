import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/features/alarm/data/models/alarm_type.dart';
import 'package:washer/features/alarm/presentation/widgets/alarm_card.dart';

Future<void> _pumpCard(
  WidgetTester tester, {
  required AlarmType type,
  required String description,
}) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(412, 917),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: AlarmCard(
            alarmType: type,
            date: '오후 10:00',
            descriptionText: description,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('AlarmCard 제목', () {
    // 서버는 세탁기·건조기에 같은 타입을 쓰고 기기 종류를 내려주지 않는다.
    testWidgets('건조기 완료 알림의 제목을 세탁기로 표시하지 않는다', (tester) async {
      await _pumpCard(
        tester,
        type: AlarmType.COMPLETION,
        description: 'DRYER-3F-L1의 건조가 완료되었습니다. 빠른 시간 내에 수거해 주시기 바랍니다.',
      );

      expect(find.text('이용 완료'), findsOneWidget);
      expect(find.textContaining('세탁'), findsNothing);
    });

    testWidgets('건조기 이상 알림의 제목을 세탁기로 표시하지 않는다', (tester) async {
      await _pumpCard(
        tester,
        type: AlarmType.MALFUNCTION,
        description: 'DRYER-3F-L1 기기에 이상이 감지되었습니다. 빠른 시간 내에 확인해 주시기 바랍니다.',
      );

      expect(find.text('기기 이상'), findsOneWidget);
      expect(find.textContaining('세탁'), findsNothing);
    });

    testWidgets('세탁기 완료 알림은 같은 제목과 서버 본문을 그대로 표시한다', (tester) async {
      const description = 'WASHER-3F-L1의 세탁이 완료되었습니다. 빠른 시간 내에 수거해 주시기 바랍니다.';
      await _pumpCard(
        tester,
        type: AlarmType.COMPLETION,
        description: description,
      );

      expect(find.text('이용 완료'), findsOneWidget);
      expect(find.text(description), findsOneWidget);
    });
  });
}
