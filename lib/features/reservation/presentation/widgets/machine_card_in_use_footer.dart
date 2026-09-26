import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/utils/date_time_formatter.dart';
import 'package:washer/core/utils/room_formatter.dart';
import 'package:washer/core/utils/user_formatter.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';
import 'package:washer/features/reservation/presentation/widgets/machine_card_layout_helpers.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_typography.dart';

/// 사용 중 상태의 카드 하단. 남은 시간(완료 시각이 없으면 '분석중')과 사용자 정보를 보여준다.
class MachineCardInUseFooter extends ConsumerWidget {
  const MachineCardInUseFooter({
    super.key,
    required this.laundryMachineType,
    required this.machineId,
    required this.machineName,
    this.finishedAt,
    this.room,
    this.activeUserName,
    this.activeUserStudentId,
    this.trailing,
  });

  final LaundryMachineType laundryMachineType;
  final int machineId;
  final String machineName;
  final String? finishedAt;
  final String? room;
  final String? activeUserName;
  final String? activeUserStudentId;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeUserLabel = UserFormatter.formatUserLabel(
      studentId: activeUserStudentId,
      userName: activeUserName,
    );

    if (!hasText(finishedAt)) {
      return withTrailing(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${laundryMachineType.text} 사용 중',
              style: WasherTypography.body2(WasherColor.baseGray500),
            ),
            AppGap.v4,
            Text(
              '분석중',
              style: WasherTypography.body2(WasherColor.baseGray500),
            ),
            AppGap.v4,
            if (room != null)
              Text(
                '사용 호실: ${RoomFormatter.formatRoom(room)}',
                style: WasherTypography.body2(WasherColor.baseGray500),
              ),
            if (activeUserLabel != null) ...[
              AppGap.v4,
              Text(
                '$activeUserLabel 이용중...',
                style: WasherTypography.body2(WasherColor.baseGray500),
              ),
            ],
          ],
        ),
        trailing,
      );
    }

    final now = ref.watch(clockProvider).asData?.value ?? DateTime.now();
    final countdown = DateTimeFormatter.formatRemainingTimeToKorean(
      finishedAt,
      now: now,
      expiredText: '완료 예정',
      includeHours: true,
    );

    return withTrailing(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${laundryMachineType.text} 사용 중',
            style: WasherTypography.body2(WasherColor.baseGray500),
          ),
          AppGap.v4,
          Text(
            '남은 ${laundryMachineType == LaundryMachineType.washer ? '세탁' : '건조'} 시간: $countdown',
            style: WasherTypography.body2(WasherColor.baseGray500),
          ),
          AppGap.v4,
          if (room != null)
            Text(
              '사용 호실: ${RoomFormatter.formatRoom(room)}',
              style: WasherTypography.body2(WasherColor.baseGray500),
            ),
          if (activeUserLabel != null) ...[
            AppGap.v4,
            Text(
              '$activeUserLabel 이용중...',
              style: WasherTypography.body2(WasherColor.baseGray500),
            ),
          ],
        ],
      ),
      trailing,
    );
  }
}
