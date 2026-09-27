import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/enums/reservation_state.dart';
import 'package:washer/features/reservation/presentation/widgets/machine_card_footer.dart';
import 'package:washer/features/reservation/presentation/widgets/machine_card_layout_helpers.dart';
import 'package:washer/features/reservation/presentation/widgets/machine_history_icon_button.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_typography.dart';
import 'package:washer/shared/ui/indicators/status_badge.dart';

/// 기기 한 대의 예약 상태를 보여주는 카드. 상단에 기기명/상태 배지, 하단에 상태별 [MachineCardFooter]를 둔다.
class MachineReservationCard extends StatelessWidget {
  const MachineReservationCard({
    super.key,
    required this.laundryMachineType,
    required this.reservationState,
    required this.machineName,
    this.machineId = 0,
    this.reservationId = 0,
    this.room,
    this.reservedAt,
    this.finishedAt,
    this.remainDuration,
    this.activeUserName,
    this.activeUserStudentId,
    this.showActions = true,
    this.onReserve,
  });

  final LaundryMachineType laundryMachineType;
  final ReservationState reservationState;
  final String machineName;
  final int machineId;
  final int reservationId;
  final String? room;
  final String? reservedAt;
  final String? finishedAt;
  final String? remainDuration;
  final String? activeUserName;
  final String? activeUserStudentId;
  final bool showActions;
  final VoidCallback? onReserve;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 137.h),
      padding: AppPadding.card,
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    laundryMachineType.icon(
                      color: reservationState.color,
                    ),
                    AppGap.h8,
                    Expanded(
                      child: Text(
                        machineName,
                        style: WasherTypography.subTitle3(
                          WasherColor.baseGray800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              AppGap.h8,
              StatusBadge(
                label:
                    reservationState == ReservationState.inUse &&
                        !hasText(finishedAt)
                    ? '분석중'
                    : reservationState.label,
                color: reservationState.color,
                textStyle: WasherTypography.caption(Colors.white),
              ),
            ],
          ),
          AppGap.v12,
          MachineCardFooter(
            machineId: machineId,
            reservationId: reservationId,
            machineName: machineName,
            laundryMachineType: laundryMachineType,
            reservationState: reservationState,
            room: room,
            reservedAt: reservedAt,
            finishedAt: finishedAt,
            remainDuration: remainDuration,
            activeUserName: activeUserName,
            activeUserStudentId: activeUserStudentId,
            showActions: showActions,
            onReserve: onReserve,
            // 히스토리 아이콘은 machineId가 유효할 때만(0이면 잘못된 조회 방지) 노출한다.
            // 각 하단 섹션이 자기 마지막 텍스트 줄 우측에 붙인다.
            trailing: machineId > 0
                ? MachineHistoryIconButton(
                    machineId: machineId,
                    machineName: machineName,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
