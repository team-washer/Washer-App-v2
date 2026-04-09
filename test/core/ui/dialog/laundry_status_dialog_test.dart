import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/enums/machine_state.dart';
import 'package:washer/core/ui/dialog/laundry_status_dialog.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/local/laundry_machine_model.dart';
import 'package:washer/features/reservation/data/repositories/home_repository_impl.dart';
import 'package:washer/features/reservation/domain/repositories/home_repository.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';

class _FakeHomeRepository implements HomeRepository {
  _FakeHomeRepository({
    required this.activeReservations,
  });

  final List<ActiveReservationModel> activeReservations;

  @override
  Future<List<ActiveReservationModel>> getActiveReservations() async =>
      activeReservations;

  @override
  Future<MachineStatusResponse> getMachineStatus() async =>
      const MachineStatusResponse(machines: [], totalCount: 0);
}

void main() {
  testWidgets('예약 상태 다이얼로그는 예약 만료 카운트다운을 우선 표시한다', (tester) async {
    const now = '2026-04-09T15:30:00.000';
    const reservedAt = '2026-04-09T15:28:44.436305512';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeRepositoryProvider.overrideWith(
            (ref) => _FakeHomeRepository(
              activeReservations: const [
                ActiveReservationModel(
                  id: 114,
                  userId: 15,
                  userName: '이주언',
                  userRoomNumber: '420',
                  userStudentId: '3413',
                  machineId: 83,
                  machineName: 'Washer-4F-L1',
                  reservedAt: reservedAt,
                  expectedCompletionTime: null,
                  status: 'RESERVED',
                ),
              ],
            ),
          ),
          clockProvider.overrideWith(
            (ref) => Stream.value(DateTime.parse(now)),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(412, 917),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return const MaterialApp(
              home: Scaffold(
                body: LaundryStatusDialog(
                  machineType: LaundryMachineType.washer,
                  machineName: 'Washer-4F-L1',
                  machineId: 83,
                  isUsed: true,
                  machineState: MachineState.wash,
                  expectedTime: '2026-04-09T16:45:00.000',
                  roomNumber: '420',
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.pump();

    expect(find.text('예약중'), findsOneWidget);
    expect(find.textContaining('예약 만료까지:'), findsOneWidget);
    expect(find.textContaining('세탁 완료 예정시간'), findsNothing);
  });
}
