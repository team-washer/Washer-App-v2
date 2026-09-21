import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/utils/date_time_formatter.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_typography.dart';

/// "남은 세탁/건조 시간: ..." 문구 — clockProvider 틱마다 갱신된다.
class InUseCountdownText extends ConsumerWidget {
  const InUseCountdownText({
    super.key,
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
