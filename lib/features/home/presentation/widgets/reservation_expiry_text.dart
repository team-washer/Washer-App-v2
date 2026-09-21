import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/constants/reservation_durations.dart';
import 'package:washer/core/utils/date_time_formatter.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_typography.dart';

/// "예약 만료까지: n분 n초" 문구 — clockProvider 틱마다 갱신된다.
class ReservationExpiryText extends ConsumerWidget {
  const ReservationExpiryText({
    super.key,
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
