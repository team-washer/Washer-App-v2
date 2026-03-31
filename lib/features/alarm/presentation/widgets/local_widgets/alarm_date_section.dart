part of '../alarm_list_widget.dart';

/// 알람 데이터 모델
class _AlarmData {
  final AlarmType status;
  final String time;
  final String description;

  const _AlarmData({
    required this.status,
    required this.time,
    required this.description,
  });
}

/// 특정 날짜의 알람 섹션 위젯 - 날짜 구분선과 알람 카드 나열
class _DateSection extends StatelessWidget {
  final String date;
  final List<_AlarmData> alarms;

  const _DateSection({required this.date, required this.alarms});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DateDivider(date: date),
        AppGap.v8,
        ...alarms.map(
          (alarm) => Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.contentPadding),
            child: MachineStateWidget(
              laundryStatus: alarm.status,
              date: alarm.time,
              descriptionText: alarm.description,
            ),
          ),
        ),
      ],
    );
  }
}
