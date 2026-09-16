import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/local/laundry_machine_model.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';
import 'package:washer/features/reservation/presentation/widgets/reservation_section_widget.dart';
import 'package:washer/features/user/data/models/my_user_model.dart';
import 'package:washer/features/user/presentation/providers/my_user_provider.dart';

class _FakeMachineStatusNotifier extends MachineStatusNotifier {
  _FakeMachineStatusNotifier(this.machines);

  final List<MachineModel> machines;

  @override
  Future<MachineStatusResponse> build() async =>
      MachineStatusResponse(machines: machines, totalCount: machines.length);
}

class _FakeActiveReservationNotifier extends ActiveReservationNotifier {
  @override
  Future<List<ActiveReservationModel>> build() async => const [];

  @override
  Future<void> ensureLoaded() async {}
}

class _FakeMyUserNotifier extends MyUserNotifier {
  _FakeMyUserNotifier(this.roomNumber);

  final String? roomNumber;

  @override
  Future<MyUserModel?> build() async => MyUserModel(
    id: 1,
    name: '테스트',
    roomNumber: roomNumber,
  );
}

MachineModel _washer(String name) => MachineModel(
  machineId: name.hashCode,
  name: name,
  type: 'WASHER',
  status: 'AVAILABLE',
  availability: 'AVAILABLE',
);

Future<void> _pumpSection(
  WidgetTester tester, {
  required List<MachineModel> machines,
  required String? roomNumber,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        machineStatusProvider.overrideWith(
          () => _FakeMachineStatusNotifier(machines),
        ),
        activeReservationProvider.overrideWith(
          _FakeActiveReservationNotifier.new,
        ),
        myUserProvider.overrideWith(() => _FakeMyUserNotifier(roomNumber)),
      ],
      child: ScreenUtilInit(
        designSize: const Size(412, 917),
        builder: (_, __) => const MaterialApp(
          home: Scaffold(
            body: ReservationSectionWidget(
              laundryMachineType: LaundryMachineType.washer,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ReservationSectionWidget currentFloor', () {
    testWidgets('기기 목록이 비어 있고 사용자 층도 없으면 빈 안내를 보여준다', (tester) async {
      await _pumpSection(tester, machines: const [], roomNumber: null);

      expect(tester.takeException(), isNull);
      expect(find.text('표시할 기기가 없습니다.'), findsOneWidget);
    });

    testWidgets('해당 타입 기기가 하나도 없어도(건조기만 존재) 크래시하지 않는다', (tester) async {
      await _pumpSection(
        tester,
        machines: [
          const MachineModel(
            machineId: 1,
            name: 'Dryer-3F-L1',
            type: 'DRYER',
            status: 'AVAILABLE',
            availability: 'AVAILABLE',
          ),
        ],
        roomNumber: null,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('표시할 기기가 없습니다.'), findsOneWidget);
    });

    testWidgets('사용자 층을 못 읽어도 기기가 있으면 가장 낮은 층을 보여준다', (tester) async {
      await _pumpSection(
        tester,
        machines: [_washer('Washer-4F-L1'), _washer('Washer-3F-L1')],
        roomNumber: null,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Washer-3F-L1'), findsOneWidget);
    });

    testWidgets('사용자 층이 있으면 그 층이 기본 선택된다', (tester) async {
      await _pumpSection(
        tester,
        machines: [_washer('Washer-3F-L1'), _washer('Washer-4F-L1')],
        roomNumber: '412',
      );

      expect(find.text('Washer-4F-L1'), findsOneWidget);
      expect(find.text('Washer-3F-L1'), findsNothing);
    });
  });
}
