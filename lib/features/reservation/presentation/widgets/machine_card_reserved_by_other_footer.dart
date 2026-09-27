import 'package:flutter/material.dart';
import 'package:washer/core/utils/date_time_formatter.dart';
import 'package:washer/core/utils/room_formatter.dart';
import 'package:washer/features/reservation/presentation/widgets/machine_card_layout_helpers.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_typography.dart';

/// 다른 사용자가 예약한 상태의 카드 하단.
class MachineCardReservedByOtherFooter extends StatelessWidget {
  const MachineCardReservedByOtherFooter({
    super.key,
    required this.machineId,
    required this.machineName,
    this.reservedAt,
    this.remainDuration,
    this.room,
    this.trailing,
  });

  final int machineId;
  final String machineName;
  final String? reservedAt;
  final String? remainDuration;
  final String? room;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final formattedReservedAt = DateTimeFormatter.formatToShortWithTime(
      reservedAt,
    );

    return withTrailing(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '예약 시간: ${formattedReservedAt.isEmpty ? '확인 중' : formattedReservedAt}',
            style: WasherTypography.body2(WasherColor.baseGray500),
          ),
          AppGap.v4,
          Text(
            '예약 상태: 사용 대기 중',
            style: WasherTypography.body2(WasherColor.baseGray500),
          ),
          if (room != null && room!.trim().isNotEmpty) ...[
            AppGap.v4,
            Text(
              '사용 호실: ${RoomFormatter.formatRoom(room)}',
              style: WasherTypography.body2(WasherColor.baseGray500),
            ),
          ],
        ],
      ),
      trailing,
    );
  }
}
