import 'package:flutter/material.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/enums/reservation_state.dart';
import 'package:washer/features/reservation/presentation/widgets/machine_card_available_footer.dart';
import 'package:washer/features/reservation/presentation/widgets/machine_card_cleaning_footer.dart';
import 'package:washer/features/reservation/presentation/widgets/machine_card_in_use_footer.dart';
import 'package:washer/features/reservation/presentation/widgets/machine_card_reserved_by_me_footer.dart';
import 'package:washer/features/reservation/presentation/widgets/machine_card_reserved_by_other_footer.dart';
import 'package:washer/features/reservation/presentation/widgets/machine_card_unavailable_footer.dart';

/// 예약 상태([ReservationState])에 맞는 카드 하단 위젯을 골라 보여준다.
class MachineCardFooter extends StatelessWidget {
  const MachineCardFooter({
    super.key,
    required this.reservationState,
    required this.laundryMachineType,
    this.machineId = 0,
    this.reservationId = 0,
    this.machineName = '',
    this.room,
    this.reservedAt,
    this.finishedAt,
    this.remainDuration,
    this.activeUserName,
    this.activeUserStudentId,
    this.showActions = true,
    this.onReserve,
    this.trailing,
  });

  final LaundryMachineType laundryMachineType;
  final ReservationState reservationState;
  final int machineId;
  final int reservationId;
  final String machineName;
  final String? room;
  final String? reservedAt;
  final String? finishedAt;
  final String? remainDuration;
  final String? activeUserName;
  final String? activeUserStudentId;
  final bool showActions;
  final VoidCallback? onReserve;

  /// 하단 정보 마지막 텍스트 줄 우측에 붙일 위젯(히스토리 아이콘). null이면 미노출.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    switch (reservationState) {
      case ReservationState.inUse:
        return MachineCardInUseFooter(
          laundryMachineType: laundryMachineType,
          machineId: machineId,
          machineName: machineName,
          finishedAt: finishedAt,
          room: room,
          activeUserName: activeUserName,
          activeUserStudentId: activeUserStudentId,
          trailing: trailing,
        );
      case ReservationState.available:
        return MachineCardAvailableFooter(
          machineId: machineId,
          machineName: machineName,
          laundryMachineType: laundryMachineType,
          onReserve: onReserve,
          trailing: trailing,
        );
      case ReservationState.reservedByMe:
        return MachineCardReservedByMeFooter(
          laundryMachineType: laundryMachineType,
          reservedAt: reservedAt,
          machineId: machineId,
          reservationId: reservationId,
          machineName: machineName,
          showActions: showActions,
          trailing: trailing,
        );
      case ReservationState.reservedByOther:
        return MachineCardReservedByOtherFooter(
          machineId: machineId,
          machineName: machineName,
          reservedAt: reservedAt,
          remainDuration: remainDuration,
          room: room,
          trailing: trailing,
        );
      case ReservationState.unavailable:
        return MachineCardUnavailableFooter(
          laundryMachineType: laundryMachineType,
          trailing: trailing,
        );
      case ReservationState.cleaning:
        return MachineCardCleaningFooter(
          laundryMachineType: laundryMachineType,
          trailing: trailing,
        );
    }
  }
}
