import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/enums/laundry_status.dart';
import 'package:washer/core/enums/reservation_state.dart';
import 'package:washer/core/router/route_paths.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_typography.dart';
import 'package:washer/shared/ui/dialog/dialog_action.dart';
import 'package:washer/shared/ui/dialog/laundry_dialog_actions.dart';
import 'package:washer/core/utils/room_formatter.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/local/machine_model.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_action_provider.dart';
import 'package:washer/features/reservation/presentation/widgets/floor_selector_row.dart';
import 'package:washer/features/reservation/presentation/widgets/laundry_layout_dialog.dart';
import 'package:washer/features/reservation/presentation/widgets/machine_reservation_card.dart';
import 'package:washer/features/user/presentation/providers/my_user_provider.dart';

/// 선택한 층의 기기 목록(예약 카드 리스트)과 층 선택/배치도 진입 UI.
///
/// 기기 상태와 활성 예약을 조합해 카드별 [ReservationState]를 결정한다.
class ReservationMachineList extends ConsumerStatefulWidget {
  const ReservationMachineList({
    super.key,
    required this.laundryMachineType,
    this.onMapTap,
  });

  final LaundryMachineType laundryMachineType;

  /// 지정하지 않으면 기본 배치도 다이얼로그를 띄운다.
  final VoidCallback? onMapTap;

  @override
  ConsumerState<ReservationMachineList> createState() =>
      _ReservationMachineListState();
}

class _ReservationMachineListState
    extends ConsumerState<ReservationMachineList> {
  /// 사용자가 직접 고른 층. null이면 내 방 층 -> 첫 번째 층 순으로 대체한다.
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

  List<int> _floorsFrom(List<MachineModel> machines, int? userFloor) {
    final floors = machines.map((m) => m.floorNumber).whereType<int>().toSet();
    if (userFloor != null) {
      floors.add(userFloor);
    }
    return floors.toList()..sort();
  }

  /// 기기 상태와 (내) 활성 예약을 조합해 카드에 표시할 상태를 결정한다.
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

  /// 선택한 층의 기기를 카드 표시용 데이터로 변환한다.
  /// 내 예약이면 예약 정보를, 남의 기기면 사용자 정보를 채운다.
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
    await refreshReservationStatusWidgets(ref);
  }

  Future<void> _reserveMachine(BuildContext context, _MachineData item) async {
    // router는 비동기 작업 전에 캡처해야 안전하다.
    final router = GoRouter.of(context);

    await runDialogAction(
      context,
      LaundryDialogActions.reserve(
        machineName: item.name,
        machineId: item.machineId,
      ),
      popFirst: false,
      onSuccess: () => router.go(RoutePaths.home),
    );
  }

  void _showLaundryLayoutDialog(
    BuildContext context, {
    required int floor,
    required List<MachineModel> machines,
  }) {
    showDialog<void>(
      context: context,
      builder: (_) => LaundryLayoutDialog(
        laundryMachineType: widget.laundryMachineType,
        floor: floor,
        machines: machines,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final machineAsync = ref.watch(machineStatusProvider);
    final isReservationActionLoading = ref.watch(
      reservationActionProvider.select(
        (state) => state.isLoading,
      ),
    );
    final activeReservations =
        ref
            .watch(activeReservationProvider)
            .whenOrNull(data: (reservations) => reservations) ??
        const <ActiveReservationModel>[];
    final myUser = ref.watch(myUserProvider).value;
    final myUserId = myUser?.id;
    final userFloor = RoomFormatter.floorFromRoomNumber(myUser?.roomNumber);

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
        final floors = _floorsFrom(typedMachines, userFloor);
        // 해당 타입 기기가 없고 방 번호로 층도 못 읽으면 floors 가 비어 있다.
        final currentFloor =
            _selectedFloor ?? userFloor ?? floors.firstOrNull ?? 0;
        final items = _buildItems(
          typedMachines,
          activeReservations,
          currentFloor,
          myUserId,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FloorSelectorRow(
              floors: floors,
              selectedFloor: currentFloor,
              onFloorChanged: (floor) => setState(() => _selectedFloor = floor),
              onMapTap: () {
                if (widget.onMapTap != null) {
                  widget.onMapTap!();
                  return;
                }
                _showLaundryLayoutDialog(
                  context,
                  floor: currentFloor,
                  machines: typedMachines,
                );
              },
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

                          return MachineReservationCard(
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

  /// 기기 ID 또는 기기에 연결된 예약 ID로 활성 예약을 찾는다.
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

/// 예약 카드 한 장을 그리기 위한 표시용 데이터.
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
