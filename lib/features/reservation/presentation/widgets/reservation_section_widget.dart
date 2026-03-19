import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/enums/laundry_status.dart';
import 'package:washer/core/enums/reservation_state.dart';
import 'package:washer/core/router/route_paths.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/icon.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/local/laundry_machine_model.dart';
import 'package:washer/features/reservation/presentation/viewmodels/reservation_view_model.dart';
import 'package:washer/features/reservation/presentation/widgets/reservation_widget.dart';

class ReservationSectionWidget extends ConsumerStatefulWidget {
  const ReservationSectionWidget({
    super.key,
    required this.laundryMachineType,
    this.onMapTap,
  });

  final LaundryMachineType laundryMachineType;
  final VoidCallback? onMapTap;

  @override
  ConsumerState<ReservationSectionWidget> createState() =>
      _ReservationSectionWidgetState();
}

class _ReservationSectionWidgetState
    extends ConsumerState<ReservationSectionWidget> {
  int? _selectedFloor;

  List<MachineModel> _machinesForType(List<MachineModel> machines) {
    return machines
        .where((machine) => machine.type == widget.laundryMachineType.apiValue)
        .toList(growable: false);
  }

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
      if (activeReservation.laundryStatus == LaundryStatus.confirmed) {
        return ReservationState.confirmed;
      }
      return ReservationState.reservedByMe;
    }
    if (machine.operatingState == 'running') return ReservationState.inUse;
    return ReservationState.reservedByOther;
  }

  List<_MachineData> _buildItems(
    List<MachineModel> machines,
    ActiveReservationModel? activeReservation,
    int floor,
  ) {
    return machines
        .where((machine) => machine.floorNumber == floor)
        .map((machine) {
          final state = _toReservationState(machine, activeReservation);
          final isMyMachine =
              activeReservation != null &&
              machine.reservationId == activeReservation.id;

          return _MachineData(
            machine.machineId,
            machine.name,
            state,
            finishedAt: machine.expectedCompletionTime,
            room: isMyMachine ? activeReservation.userRoomNumber : null,
            reservedAt: isMyMachine ? activeReservation.reservedAt : null,
            remainDuration: null,
            reservationId: machine.reservationId ?? 0,
          );
        })
        .toList(growable: false);
  }

  Future<void> _reserveMachine(BuildContext context, _MachineData item) async {
    try {
      final reservationState = await ref
          .read(reservationViewModelProvider.notifier)
          .reserve(machineId: item.machineId);

      if (reservationState.status == ReservationActionStatus.error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('예약 실패: ${reservationState.errorMessage}'),
            ),
          );
        }
        return;
      }

      if (context.mounted) {
        context.go(RoutePaths.home);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${item.name} 예약이 완료되었습니다\n5분 이내에 기기를 켜주세요',
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final machineAsync = ref.watch(machineStatusProvider);
    final activeReservation = ref
        .watch(activeReservationProvider)
        .whenOrNull(data: (reservation) => reservation);

    return machineAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(
          '기기 정보를 불러오지 못했습니다.',
          style: WasherTypography.body1(WasherColor.baseGray300),
        ),
      ),
      data: (data) {
        final typedMachines = _machinesForType(data.machines);
        final floors = _floorsFrom(typedMachines);
        final currentFloor =
            _selectedFloor ?? (floors.isNotEmpty ? floors.first : 0);
        final items = _buildItems(
          typedMachines,
          activeReservation,
          currentFloor,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FloorSelectorRow(
              floors: floors,
              selectedFloor: currentFloor,
              onFloorChanged: (floor) => setState(() => _selectedFloor = floor),
              onMapTap: widget.onMapTap,
            ),
            AppGap.v16,
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        '표시할 기기가 없습니다.',
                        style: WasherTypography.body1(WasherColor.baseGray300),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => AppGap.v12,
                      itemBuilder: (_, index) {
                        final item = items[index];

                        return ReservationWidget(
                          laundryMachineType: widget.laundryMachineType,
                          reservationState: item.state,
                          machineId: item.machineId,
                          machineName: item.name,
                          finishedAt: item.finishedAt,
                          room: item.room,
                          reservedAt: item.reservedAt,
                          remainDuration: item.remainDuration,
                          reservationId: item.reservationId,
                          onReserve: item.state == ReservationState.available
                              ? () => _reserveMachine(context, item)
                              : null,
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

class _FloorSelectorRow extends StatelessWidget {
  const _FloorSelectorRow({
    required this.floors,
    required this.selectedFloor,
    required this.onFloorChanged,
    this.onMapTap,
  });

  final List<int> floors;
  final int selectedFloor;
  final ValueChanged<int> onFloorChanged;
  final VoidCallback? onMapTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: floors
              .map(
                (floor) => Padding(
                  padding: EdgeInsets.only(
                    right: floor != floors.last ? AppSpacing.h8 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () => onFloorChanged(floor),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selectedFloor == floor
                            ? WasherColor.mainColor600
                            : WasherColor.baseGray100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$floor층',
                        style: WasherTypography.body4(
                          selectedFloor == floor
                              ? Colors.white
                              : WasherColor.baseGray600,
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        GestureDetector(
          onTap: onMapTap,
          child: Row(
            children: [
              Text(
                '배치도 보기',
                style: WasherTypography.body4(WasherColor.baseGray300),
              ),
              AppGap.h4,
              const WasherIcon(
                type: WasherIconType.map,
                size: 20,
                color: WasherColor.baseGray300,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MachineData {
  _MachineData(
    this.machineId,
    this.name,
    this.state, {
    this.finishedAt,
    this.room,
    this.reservedAt,
    this.remainDuration,
    this.reservationId = 0,
  });

  final int machineId;
  final String name;
  final ReservationState state;
  final String? finishedAt;
  final String? room;
  final String? reservedAt;
  final String? remainDuration;
  final int reservationId;
}
