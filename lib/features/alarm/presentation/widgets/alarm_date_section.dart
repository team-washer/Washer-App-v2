import 'package:flutter/material.dart';
import 'package:washer/features/alarm/data/models/alarm_type.dart';
import 'package:washer/features/alarm/presentation/widgets/alarm_card.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_typography.dart';

/// 화면 표시용으로 가공된 알람 항목 (시간은 포맷된 문자열)
class AlarmDisplayItem {
  final AlarmType status;
  final String time;
  final String description;
  final DateTime? createdAt;

  const AlarmDisplayItem({
    required this.status,
    required this.time,
    required this.description,
    required this.createdAt,
  });
}

/// 특정 날짜의 알람 섹션 위젯 - 날짜 구분선과 알람 카드 나열
class AlarmDateSection extends StatelessWidget {
  final String date;
  final List<AlarmDisplayItem> alarms;

  const AlarmDateSection({super.key, required this.date, required this.alarms});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AlarmDateDivider(date: date),
        AppGap.v8,
        ...alarms.map(
          (alarm) => Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.contentPadding),
            child: AlarmCard(
              alarmType: alarm.status,
              date: alarm.time,
              descriptionText: alarm.description,
            ),
          ),
        ),
      ],
    );
  }
}

/// 날짜 텍스트를 가운데 두고 양옆에 선을 그려 알람 그룹을 구분하는 위젯
class _AlarmDateDivider extends StatelessWidget {
  final String date;

  const _AlarmDateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: WasherColor.baseGray500, thickness: 1),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              date,
              style: WasherTypography.body4(WasherColor.baseGray500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: WasherColor.baseGray500, thickness: 1),
        ),
      ],
    );
  }
}
