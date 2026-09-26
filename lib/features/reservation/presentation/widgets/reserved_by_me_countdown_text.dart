import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/constants/reservation_durations.dart';
import 'package:washer/core/utils/date_time_formatter.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_typography.dart';

/// 내 예약의 만료까지 남은 시간을 1초 단위로 갱신해 보여준다.
/// 시계 구독으로 인한 재빌드를 이 텍스트로 한정하기 위해 분리했다.
class ReservedByMeCountdownText extends ConsumerWidget {
  const ReservedByMeCountdownText({
    super.key,
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
