part of '../alarm_list_widget.dart';

class _AlarmData {
  final LaundryAlarmStatus status;
  final String time;
  final String description;
  final String? reason;

  const _AlarmData({
    required this.status,
    required this.time,
    required this.description,
    this.reason,
  });
}

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
        const SizedBox(height: AppSpacing.v8),
        ...alarms.map(
          (alarm) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.v12),
            child: MachineStateWidget(
              laundryStatus: alarm.status,
              date: alarm.time,
              descriptionText: alarm.description,
              reason: alarm.reason ?? '',
            ),
          ),
        ),
      ],
    );
  }
}
