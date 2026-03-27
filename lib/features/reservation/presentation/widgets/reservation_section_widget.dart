import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:washer/core/constants/durations.dart';
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
import 'package:washer/features/user/presentation/viewmodels/my_user_view_model.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(activeReservationProvider.notifier).ensureLoaded();
    });
  }

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
    List<ActiveReservationModel> activeReservations,
    int? myUserId,
  ) {
    final activeReservation = _findReservationForMachine(
      machine,
      activeReservations,
    );
    final isMyMachine = _isMyReservation(
      activeReservation: activeReservation,
      myUserId: myUserId,
    );

    if (machine.isUnavailable) return ReservationState.unavailable;

    if (isMyMachine && activeReservation != null) {
      final myReservation = activeReservation;
      if (myReservation.laundryStatus == LaundryStatus.inUse ||
          myReservation.laundryStatus == LaundryStatus.completed) {
        return ReservationState.inUse;
      }
      return ReservationState.reservedByMe;
    }

    if (machine.isAvailable) return ReservationState.available;
    if (machine.isInUse) return ReservationState.inUse;
    return ReservationState.reservedByOther;
  }

  List<_MachineData> _buildItems(
    List<MachineModel> machines,
    List<ActiveReservationModel> activeReservations,
    int floor,
    int? myUserId,
  ) {
    return machines
        .where((machine) => machine.floorNumber == floor)
        .map((machine) {
          final activeReservation = _findReservationForMachine(
            machine,
            activeReservations,
          );
          final state = _toReservationState(
            machine,
            activeReservations,
            myUserId,
          );
          final isMyMachine = _isMyReservation(
            activeReservation: activeReservation,
            myUserId: myUserId,
          );

          final room = isMyMachine && activeReservation != null
              ? activeReservation.userRoomNumber
              : machine.roomNumber;
          final reservedAt = isMyMachine && activeReservation != null
              ? activeReservation.reservedAt
              : null;
          final reservationId = isMyMachine && activeReservation != null
              ? activeReservation.id
              : 0;

          return _MachineData(
            machine.machineId,
            machine.name,
            state,
            isOwnedByMe: isMyMachine,
            finishedAt: machine.expectedCompletionTime,
            room: room,
            reservedAt: reservedAt,
            remainDuration: null,
            reservationId: reservationId,
            activeUserName: !isMyMachine
                ? activeReservation?.userName ?? machine.userName
                : null,
            activeUserStudentId: !isMyMachine
                ? activeReservation?.userStudentId ?? machine.userStudentId
                : null,
          );
        })
        .toList(growable: false);
  }

  Future<void> _refreshReservationScreen() async {
    await Future.wait([
      ref.read(machineStatusProvider.notifier).refresh(),
      ref.read(activeReservationProvider.notifier).refresh(),
    ]);
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
              '${item.name} 예약이 완료되었습니다\n'
              '$reservationExpiryMinutes분 동안 기기 연결을 확인합니다',
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
    final isReservationActionLoading = ref.watch(
      reservationViewModelProvider.select(
        (state) => state.status == ReservationActionStatus.loading,
      ),
    );
    final activeReservations =
        ref
            .watch(activeReservationProvider)
            .whenOrNull(data: (reservations) => reservations) ??
        const <ActiveReservationModel>[];
    final myUserId = ref
        .watch(myUserProvider)
        .whenOrNull(
          data: (user) => user?.id,
        );

    return machineAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => RefreshIndicator(
        onRefresh: _refreshReservationScreen,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 240,
              child: Center(
                child: Text(
                  '기기 정보를 불러오지 못했습니다.',
                  style: WasherTypography.body1(WasherColor.baseGray300),
                ),
              ),
            ),
          ],
        ),
      ),
      data: (data) {
        final typedMachines = _machinesForType(data.machines);
        final floors = _floorsFrom(typedMachines);
        final currentFloor =
            _selectedFloor ?? (floors.isNotEmpty ? floors.first : 0);
        final items = _buildItems(
          typedMachines,
          activeReservations,
          currentFloor,
          myUserId,
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
              child: RefreshIndicator(
                onRefresh: _refreshReservationScreen,
                child: items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: 240,
                            child: Center(
                              child: Text(
                                '표시할 기기가 없습니다.',
                                style: WasherTypography.body1(
                                  WasherColor.baseGray300,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(bottom: AppSpacing.v12),
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
                            activeUserName: item.activeUserName,
                            activeUserStudentId: item.activeUserStudentId,
                            showActions: item.isOwnedByMe,
                            onReserve:
                                item.state == ReservationState.available &&
                                    !isReservationActionLoading
                                ? () => _reserveMachine(context, item)
                                : null,
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  ActiveReservationModel? _findReservationForMachine(
    MachineModel machine,
    List<ActiveReservationModel> activeReservations,
  ) {
    return activeReservations.firstWhereOrNull(
      (reservation) =>
          machine.machineId == reservation.machineId ||
          machine.reservationId == reservation.id,
    );
  }

  bool _isMyReservation({
    required ActiveReservationModel? activeReservation,
    required int? myUserId,
  }) {
    if (activeReservation == null || myUserId == null) {
      return false;
    }

    return activeReservation.userId == myUserId;
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
                            ? WasherColor.mainColor500
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
    this.isOwnedByMe = false,
    this.finishedAt,
    this.room,
    this.reservedAt,
    this.remainDuration,
    this.reservationId = 0,
    this.activeUserName,
    this.activeUserStudentId,
  });

  final int machineId;
  final String name;
  final ReservationState state;
  final bool isOwnedByMe;
  final String? finishedAt;
  final String? room;
  final String? reservedAt;
  final String? remainDuration;
  final int reservationId;
  final String? activeUserName;
  final String? activeUserStudentId;
}
