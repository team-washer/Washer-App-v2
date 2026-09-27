import 'package:flutter/material.dart';
import 'package:washer/core/enums/laundry_action_type.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/utils/date_time_formatter.dart';
import 'package:washer/features/reservation/presentation/widgets/machine_card_layout_helpers.dart';
import 'package:washer/features/reservation/presentation/widgets/reserved_by_me_countdown_text.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_typography.dart';
import 'package:washer/shared/ui/buttons/washer_big_button.dart';
import 'package:washer/shared/ui/dialog/laundry_action_dialog.dart';

/// 내가 예약한 상태의 카드 하단. 예약 시간, 만료 카운트다운, 예약 취소 버튼을 보여준다.
class MachineCardReservedByMeFooter extends StatelessWidget {
  const MachineCardReservedByMeFooter({
    super.key,
    required this.laundryMachineType,
    this.reservedAt,
    required this.machineId,
    required this.reservationId,
    required this.machineName,
    this.showActions = true,
    this.trailing,
  });

  final LaundryMachineType laundryMachineType;
  final String? reservedAt;
  final int machineId;
  final int reservationId;
  final String machineName;
  final bool showActions;
  final Widget? trailing;

  String _formatCountdown(DateTime expireAt, DateTime now) {
    final remaining = expireAt.difference(now);
    if (remaining.isNegative) return '만료됨';

    return DateTimeFormatter.formatDurationParts(remaining);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        withTrailing(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '예약 시간: ${DateTimeFormatter.formatToShortWithTime(reservedAt)}',
                style: WasherTypography.body2(WasherColor.baseGray500),
              ),
              AppGap.v4,
              ReservedByMeCountdownText(
                reservedAt: reservedAt,
                formatCountdown: _formatCountdown,
              ),
            ],
          ),
          trailing,
        ),
        if (showActions) ...[
          AppGap.v12,
          SizedBox(
            width: double.infinity,
            child: WasherBigButton(
              text: '예약 취소',
              onPressed: () {
                if (reservationId > 0) {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: LaundryActionDialog(
                        actionType: LaundryActionType.cancelReservation,
                        deviceId: machineName,
                        reservationId: reservationId,
                        machineId: machineId,
                      ),
                    ),
                  );
                }
              },
              color: WasherColor.baseGray300,
            ),
          ),
        ],
      ],
    );
  }
}
