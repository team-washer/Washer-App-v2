import 'package:flutter/material.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/enums/laundry_status.dart';
import 'package:washer/core/utils/date_time_formatter.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_typography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';
import 'package:washer/core/constants/reservation_durations.dart';

/// 예약 카드 본문 — 예약 상태(laundryStatus)별로 다른 안내 문구를 표시
class MyReservationStatusBody extends StatelessWidget {
  const MyReservationStatusBody({
    super.key,
    required this.laundryMachineType,
    required this.laundryStatus,
    required this.reservedAt,
    required this.remainDuration,
    required this.finishedAt,
  });

  final LaundryMachineType laundryMachineType;
  final LaundryStatus laundryStatus;
  final String? reservedAt;
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
          _ReservationExpiryText(
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
          _InUseCountdownText(
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

/// "남은 세탁/건조 시간: ..." 문구 — clockProvider 틱마다 갱신된다.
class _InUseCountdownText extends ConsumerWidget {
  const _InUseCountdownText({
    required this.laundryMachineType,
    required this.finishedAt,
  });

  final LaundryMachineType laundryMachineType;
  final String? finishedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).asData?.value ?? DateTime.now();
    final countdown = DateTimeFormatter.formatRemainingTimeToKorean(
      finishedAt,
      now: now,
      expiredText: '완료 예정',
      includeHours: true,
    );

    return Text(
      '남은 ${laundryMachineType == LaundryMachineType.washer ? '세탁' : '건조'} 시간: $countdown',
      style: WasherTypography.body2(WasherColor.baseGray500),
    );
  }
}

/// "예약 만료까지: n분 n초" 문구 — clockProvider 틱마다 갱신된다.
class _ReservationExpiryText extends ConsumerWidget {
  const _ReservationExpiryText({
    required this.reservedAt,
    required this.remainDuration,
  });

  final String? reservedAt;
  final String? remainDuration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).asData?.value ?? DateTime.now();
    var countdown = remainDuration ?? '만료됨';

    final reservedTime = DateTimeFormatter.parseServerDateTime(reservedAt);
    if (reservedTime != null) {
      countdown = _formatDuration(
        reservedTime.add(reservationExpiryDuration).difference(now),
        expiredText: '만료됨',
      );
    }

    return Text(
      '예약 만료까지: $countdown',
      style: WasherTypography.body2(WasherColor.errorColor),
    );
  }
}

/// 남은 시간이 음수면 [expiredText], 아니면 "n시간 n분 n초" 형태로 변환한다.
String _formatDuration(
  Duration duration, {
  required String expiredText,
  bool includeHours = true,
}) {
  if (duration.isNegative) {
    return expiredText;
  }

  return DateTimeFormatter.formatDurationParts(
    duration,
    includeHours: includeHours,
  );
}
