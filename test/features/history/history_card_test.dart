import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/utils/date_time_formatter.dart';
import 'package:washer/features/history/data/models/machine_history_response.dart';
import 'package:washer/features/history/presentation/widgets/history_card.dart';

Future<void> _pumpCard(WidgetTester tester, HistoryContent item) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(412, 917),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: HistoryCard(machineName: 'Washer-3F-L1', item: item),
        ),
      ),
    ),
  );
}

void main() {
  // 서버 계약: completionTime = 실제 완료 시각 ?? 취소 시각(cancelledAt),
  // createdAt = 예약 생성 시각 (Washer-Backend-v2 QueryMachineReservationHistoryServiceImpl)
  const createdAt = '2026-01-27T21:00:00';
  const cancelledAt = '2026-01-27T21:20:00';

  testWidgets('취소 기록의 취소 시간은 생성 시각이 아니라 completionTime을 표시한다', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      const HistoryContent(
        id: 1,
        userRoomNumber: '301',
        startTime: '2026-01-27T21:30:00',
        completionTime: cancelledAt,
        status: 'CANCELLED',
        createdAt: createdAt,
      ),
    );

    expect(find.text('취소 시간'), findsOneWidget);
    expect(
      find.text(DateTimeFormatter.formatToShortWithTime(cancelledAt)),
      findsOneWidget,
    );
    expect(
      find.text(DateTimeFormatter.formatToShortWithTime(createdAt)),
      findsNothing,
    );
  });

  testWidgets('취소 기록에 completionTime이 없으면 생성 시각으로 추측하지 않고 -를 표시한다', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      const HistoryContent(
        id: 2,
        userRoomNumber: '301',
        startTime: '2026-01-27T21:30:00',
        status: 'CANCELLED',
        createdAt: createdAt,
      ),
    );

    expect(find.text('취소 시간'), findsOneWidget);
    expect(find.text('-'), findsOneWidget);
    expect(
      find.text(DateTimeFormatter.formatToShortWithTime(createdAt)),
      findsNothing,
    );
  });

  testWidgets('완료 기록은 완료 시간으로 completionTime을 표시한다', (tester) async {
    const completionTime = '2026-01-27T23:00:00';
    await _pumpCard(
      tester,
      const HistoryContent(
        id: 3,
        userRoomNumber: '302',
        startTime: '2026-01-27T21:30:00',
        completionTime: completionTime,
        status: 'COMPLETED',
        createdAt: createdAt,
      ),
    );

    expect(find.text('완료 시간'), findsOneWidget);
    expect(
      find.text(DateTimeFormatter.formatToShortWithTime(completionTime)),
      findsOneWidget,
    );
  });
}
