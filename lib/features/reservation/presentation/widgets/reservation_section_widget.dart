import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/enums/reservation_state.dart';
import 'package:washer/core/router/route_paths.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:washer/features/reservation/data/models/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/laundry_machine_model.dart';
import 'package:washer/features/reservation/presentation/viewmodels/reservation_view_model.dart';
import 'package:washer/features/reservation/presentation/widgets/reservation_widget.dart';

class ReservationSectionWidget extends ConsumerStatefulWidget {
  final LaundryMachineType laundryMachineType;
  final VoidCallback? onMapTap;

  const ReservationSectionWidget({
    super.key,
    required this.laundryMachineType,
    this.onMapTap,
  });

  @override
  ConsumerState<ReservationSectionWidget> createState() =>
      _ReservationSectionWidgetState();
}

class _ReservationSectionWidgetState
    extends ConsumerState<ReservationSectionWidget> {
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

  List<_MachineData> _buildItems(
    List<MachineModel> machines,
    ActiveReservationModel? activeReservation,
    int floor,
  ) {
    return machines
        .where(
          (m) =>
              m.type == widget.laundryMachineType.apiValue &&
              m.floorNumber == floor,
        )
        .map((m) {
          final state = _toReservationState(m, activeReservation);
          final isMyMachine =
              activeReservation != null &&
              m.reservationId == activeReservation.id;
          
          // expectedCompletionTime에서 남은 시간 계산 (HH:MM:SS 형식)
          String? remainDuration;
          if (m.expectedCompletionTime != null) {
            final completionTime = DateTime.tryParse(m.expectedCompletionTime!);
            if (completionTime != null) {
              final now = DateTime.now();
              if (completionTime.isAfter(now)) {
                final remaining = completionTime.difference(now);
                final hours = remaining.inHours;
                final minutes = remaining.inMinutes % 60;
                final seconds = remaining.inSeconds % 60;
                remainDuration = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
              }
            }
          }
          
          return _MachineData(
            m.machineId,
            m.name,
            state,
            finishedAt: m.expectedCompletionTime,
            room: isMyMachine ? activeReservation.userRoomNumber : null,
            remainDuration: remainDuration,
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

    ref.listen<ReservationActionState>(
      reservationViewModelProvider,
      (_, next) {
        switch (next.status) {
          case ReservationActionStatus.success:
            ref.read(machineStatusProvider.notifier).refresh();
            ref.read(activeReservationProvider.notifier).refresh();
            ref.read(reservationViewModelProvider.notifier).reset();
            context.go(RoutePaths.home);
          case ReservationActionStatus.error:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(next.errorMessage ?? '예약에 실패했습니다.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            ref.read(reservationViewModelProvider.notifier).reset();
          default:
            break;
        }
      },
    );

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
        final items = _buildItems(
          data.machines,
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
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: items.length,
                separatorBuilder: (_, __) => AppGap.v24,
                itemBuilder: (_, index) {
                  final item = items[index];
                  return ReservationWidget(
                    laundryMachineType: widget.laundryMachineType,
                    reservationState: item.state,
                    machineName: item.name,
                    finishedAt: item.finishedAt,
                    room: item.room,
                    reservedAt: item.reservedAt,
                    remainDuration: item.remainDuration,
                    onReserve: item.state == ReservationState.available
                        ? () => ref
                              .read(reservationViewModelProvider.notifier)
                              .reserve(
                                machineId: item.machineId,
                                startTime: DateTime.now(),
                              )
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
  final List<int> floors;
  final int selectedFloor;
  final ValueChanged<int> onFloorChanged;
  final VoidCallback? onMapTap;

  const _FloorSelectorRow({
    required this.floors,
    required this.selectedFloor,
    required this.onFloorChanged,
    this.onMapTap,
  });

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
            ],
          ),
        ),
      ],
    );
  }
}

class _MachineData {
  final int machineId;
  final String name;
  final ReservationState state;
  final String? finishedAt;
  final String? room;
  final String? reservedAt;
  final String? remainDuration;

  _MachineData(
    this.machineId,
    this.name,
    this.state, {
    this.finishedAt,
    this.room,
    this.reservedAt,
    this.remainDuration,
  });
}
