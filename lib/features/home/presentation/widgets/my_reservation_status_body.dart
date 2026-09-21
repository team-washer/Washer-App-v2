import 'package:flutter/material.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/enums/laundry_status.dart';
import 'package:washer/core/utils/date_time_formatter.dart';
import 'package:washer/features/home/presentation/widgets/in_use_countdown_text.dart';
import 'package:washer/features/home/presentation/widgets/reservation_expiry_text.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_typography.dart';

/// 예약 카드 본문 — 예약 상태(laundryStatus)별로 다른 안내 문구를 표시
class MyReservationStatusBody extends StatelessWidget {
  const MyReservationStatusBody({
    super.key,
    required this.laundryMachineType,
    required this.laundryStatus,
    required this.reservedAt,
    required this.confirmedAt,
    required this.remainDuration,
    required this.finishedAt,
  });

  final LaundryMachineType laundryMachineType;
  final LaundryStatus laundryStatus;
  final String? reservedAt;
  final String? confirmedAt;
  final String? remainDuration;
  final String? finishedAt;

  @override
  Widget build(BuildContext context) {
    switch (laundryStatus) {
      case LaundryStatus.reserved:
        return _buildReserved();
      case LaundryStatus.needConfirm:
        return _buildNeedConfirm();
      case LaundryStatus.inUse:
        return _buildInUse();
      case LaundryStatus.completed:
        return _buildCompleted();
    }
  }

  /// 예약 대기 — 예약 시간과 만료까지 남은 시간
  Widget _buildReserved() {
    final hasReservedAt = reservedAt != null && reservedAt!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasReservedAt) ...[
          Text(
            '예약 시간: ${DateTimeFormatter.formatToShortWithTime(reservedAt)}',
            style: WasherTypography.body2(WasherColor.baseGray500),
          ),
          AppGap.v4,
          ReservationExpiryText(
            reservedAt: reservedAt,
            remainDuration: remainDuration,
          ),
          AppGap.v12,
        ],
      ],
    );
  }

  /// 기기 동작이 감지되어 사용자 확인이 필요한 상태
  Widget _buildNeedConfirm() {
    return Text(
      '기기 동작이 감지되었습니다. 확인해주세요.',
      style: WasherTypography.body2(WasherColor.errorColor),
    );
  }

  /// 사용 중 — 남은 시간(완료 예정 시각이 없으면 "분석중")
  Widget _buildInUse() {
    final hasFinishedAt = finishedAt != null && finishedAt!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${laundryMachineType.text} 사용 중',
          style: WasherTypography.body2(WasherColor.baseGray500),
        ),
        if (hasFinishedAt) ...[
          AppGap.v4,
          InUseCountdownText(
            laundryMachineType: laundryMachineType,
            finishedAt: finishedAt,
          ),
        ] else ...[
          AppGap.v4,
          Text(
            '분석중',
            style: WasherTypography.body2(WasherColor.baseGray500),
          ),
        ],
      ],
    );
  }

  /// 완료 — 완료 시간
  Widget _buildCompleted() {
    final hasFinishedAt = finishedAt != null && finishedAt!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${laundryMachineType.text} 완료',
          style: WasherTypography.body2(WasherColor.baseGray500),
        ),
        if (hasFinishedAt) ...[
          AppGap.v4,
          Text(
            '${laundryMachineType.text} 완료 시간: ${DateTimeFormatter.formatToShortWithTime(finishedAt)}',
            style: WasherTypography.body2(WasherColor.baseGray500),
          ),
        ],
      ],
    );
  }
}
