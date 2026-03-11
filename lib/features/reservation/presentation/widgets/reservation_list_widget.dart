import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/enums/reservation_state.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:washer/features/reservation/data/models/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/laundry_machine_model.dart';
import 'package:washer/features/reservation/presentation/widgets/reservation_floor_selector_widget.dart';
import 'package:washer/features/reservation/presentation/widgets/reservation_widget.dart';

part 'local_widgets/machine_data.dart';

class ReservationListWidget extends ConsumerStatefulWidget {
  final LaundryMachineType laundryMachineType;

  const ReservationListWidget({super.key, required this.laundryMachineType});

  @override
  ConsumerState<ReservationListWidget> createState() =>
      _ReservationListWidgetState();
}

class _ReservationListWidgetState extends ConsumerState<ReservationListWidget> {
  int? _selectedFloor;

  List<int> _floorsFrom(List<MachineModel> machines) {
    return machines.map((m) => m.floorNumber).whereType<int>().toSet().toList()
      ..sort();
  }

  ReservationState _toReservationState(
    MachineModel machine,
    ActiveReservationModel? activeReservation,
  ) {
    if (machine.isUnavailable) return ReservationState.unavailable;
    if (machine.isAvailable) return ReservationState.available;
    if (activeReservation != null &&
        machine.reservationId == activeReservation.id) {
      return ReservationState.reservedByMe;
    }
    if (machine.operatingState == 'running') return ReservationState.inUse;
    return ReservationState.reservedByOther;
  }

  List<_MachineData> _buildMachines(
    List<MachineModel> machines,
    ActiveReservationModel? activeReservation,
    int selectedFloor,
  ) {
    return machines
        .where(
          (m) =>
              m.type == widget.laundryMachineType.apiValue &&
              m.floorNumber == selectedFloor,
        )
        .map((m) {
          final state = _toReservationState(m, activeReservation);
          final isMyMachine =
              activeReservation != null &&
              m.reservationId == activeReservation.id;
          return _MachineData(
            m.name,
            state,
            finishedAt: m.expectedCompletionTime,
            room: isMyMachine ? activeReservation.userRoomNumber : null,
          );
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final machineAsync = ref.watch(machineStatusProvider);
    final activeReservation = ref
        .watch(activeReservationProvider)
        .whenOrNull(data: (r) => r);

    return machineAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(
          '기기 정보를 불러오지 못했습니다.',
          style: WasherTypography.body1(WasherColor.baseGray300),
        ),
      ),
      data: (data) {
        final floors = _floorsFrom(data.machines);
        final currentFloor =
            _selectedFloor ?? (floors.isNotEmpty ? floors.first : 0);
        final machines = _buildMachines(
          data.machines,
          activeReservation,
          currentFloor,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReservationFloorSelectorWidget(
              selectedFloor: currentFloor,
              floors: floors,
              onFloorChanged: (floor) => setState(() => _selectedFloor = floor),
            ),
            AppGap.v16,
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: machines.length,
                separatorBuilder: (_, __) => AppGap.v24,
                itemBuilder: (_, index) {
                  final data = machines[index];
                  return ReservationWidget(
                    laundryMachineType: widget.laundryMachineType,
                    reservationState: data.state,
                    machineName: data.name,
                    finishedAt: data.finishedAt,
                    room: data.room,
                    reservedAt: data.reservedAt,
                    remainDuration: data.remainDuration,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
