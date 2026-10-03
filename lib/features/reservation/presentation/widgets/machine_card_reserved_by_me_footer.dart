import 'package:flutter/material.dart';
import 'package:washer/core/enums/laundry_action_type.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/utils/date_time_formatter.dart';
import 'package:washer/features/reservation/presentation/widgets/machine_card_layout_helpers.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_typography.dart';
import 'package:washer/shared/ui/buttons/washer_big_button.dart';
import 'package:washer/shared/ui/dialog/laundry_action_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/constants/reservation_durations.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';

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
              _ReservedByMeCountdownText(
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

/// 내 예약의 만료까지 남은 시간을 1초 단위로 갱신해 보여준다.
/// 시계 구독으로 인한 재빌드를 이 텍스트로 한정하기 위해 분리했다.
class _ReservedByMeCountdownText extends ConsumerWidget {
  const _ReservedByMeCountdownText({
    required this.reservedAt,
    required this.formatCountdown,
  });

  final String? reservedAt;
  final String Function(DateTime expireAt, DateTime now) formatCountdown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).asData?.value ?? DateTime.now();
    final reservedTime = DateTimeFormatter.parseServerDateTime(reservedAt);
    final expireAt = reservedTime?.add(reservationExpiryDuration);

    return Text(
      '예약 만료까지: ${expireAt != null ? formatCountdown(expireAt, now) : ''}',
      style: WasherTypography.body2(WasherColor.errorColor),
    );
  }
}
