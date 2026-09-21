import 'package:flutter/material.dart';
import 'package:washer/features/alarm/data/models/alarm_type.dart';
import 'package:washer/features/alarm/presentation/widgets/alarm_card.dart';
import 'package:washer/features/alarm/presentation/widgets/alarm_date_divider.dart';
import 'package:washer/shared/theme/app_spacing.dart';

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
        AlarmDateDivider(date: date),
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
