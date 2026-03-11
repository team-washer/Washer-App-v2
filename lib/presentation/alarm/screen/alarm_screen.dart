import 'package:flutter/material.dart';
import 'package:washer/core/enums/laundry_alarm_status.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/presentation/alarm/widget/machine_state_widget.dart';
import 'package:washer/presentation/common/scaffold/base_scaffold.dart';

// 목업 데이터
final _mockDateSections = [
  {
    'date': '25.08.19',
    'alarms': [
      {
        'status': LaundryAlarmStatus.washComplete,
        'time': '25.08.19 14:03',
        'description': 'Washer-3F-L1의 세탁이 완료되었습니다. 빠른 시간 내에 수거해 주시기 바랍니다.',
      },
      {
        'status': LaundryAlarmStatus.dryComplete,
        'time': '25.08.19 14:03',
        'description': 'Dryer-3F-L1의 세탁이 완료되었습니다. 빠른 시간 내에 수거해 주시기 바랍니다.',
      },
      {
        'status': LaundryAlarmStatus.washComplete,
        'time': '25.08.19 14:03',
        'description': 'Washer-3F-L1의 세탁이 완료되었습니다. 빠른 시간 내에 수거해 주시기 바랍니다.',
      },
      {
        'status': LaundryAlarmStatus.dryerError,
        'time': '25.08.19 14:03',
        'description': 'Dryer-3F-L1 기기에 이상이 감지되었습니다. 빠른 시간 내에 확인해 주시기 바랍니다.',
      },
      {
        'status': LaundryAlarmStatus.usageWarning,
        'time': '25.08.19 14:03',
        'description': '신고 경고가 접수되었습니다. 물품을 확인해 주시기 바랍니다.',
        'reason': '명백히 세탁 물품을 남겨둠',
      },
    ],
  },
  {
    'date': '25.08.18',
    'alarms': [
      {
        'status': LaundryAlarmStatus.washComplete,
        'time': '25.08.18 20:15',
        'description': 'Washer-2F-L2의 세탁이 완료되었습니다. 빠른 시간 내에 수거해 주시기 바랍니다.',
      },
      {
        'status': LaundryAlarmStatus.washerError,
        'time': '25.08.18 18:30',
        'description': 'Washer-3F-R1 기기에 이상이 감지되었습니다. 빠른 시간 내에 확인해 주시기 바랍니다.',
      },
      {
        'status': LaundryAlarmStatus.dryComplete,
        'time': '25.08.18 15:22',
        'description': 'Dryer-1F-L1의 건조가 완료되었습니다. 빠른 시간 내에 수거해 주시기 바랍니다.',
      },
    ],
  },
  {
    'date': '25.08.17',
    'alarms': [
      {
        'status': LaundryAlarmStatus.dryComplete,
        'time': '25.08.17 16:45',
        'description': 'Dryer-2F-R1의 건조가 완료되었습니다. 빠른 시간 내에 수거해 주시기 바랍니다.',
      },
      {
        'status': LaundryAlarmStatus.usageWarning,
        'time': '25.08.17 12:20',
        'description': '신고 경고가 접수되었습니다. 물품을 확인해 주시기 바랍니다.',
        'reason': '기기를 장시간 점유',
      },
      {
        'status': LaundryAlarmStatus.washComplete,
        'time': '25.08.17 10:00',
        'description': 'Washer-1F-L1의 세탁이 완료되었습니다. 빠른 시간 내에 수거해 주시기 바랍니다.',
      },
    ],
  },
  {
    'date': '25.08.16',
    'alarms': [
      {
        'status': LaundryAlarmStatus.dryerError,
        'time': '25.08.16 22:10',
        'description': 'Dryer-2F-L2 기기에 이상이 감지되었습니다. 빠른 시간 내에 확인해 주시기 바랍니다.',
      },
      {
        'status': LaundryAlarmStatus.washComplete,
        'time': '25.08.16 19:40',
        'description': 'Washer-3F-L2의 세탁이 완료되었습니다. 빠른 시간 내에 수거해 주시기 바랍니다.',
      },
    ],
  },
];

class AlarmScreen extends StatelessWidget {
  const AlarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '알람',
            style: WasherTypography.subTitle3(),
          ),
          const SizedBox(height: AppSpacing.v16),
          Expanded(
            child: ListView.builder(
              itemCount: _mockDateSections.length,
              itemBuilder: (context, index) {
                final section = _mockDateSections[index];
                final alarms = (section['alarms'] as List).map((alarm) {
                  return _AlarmData(
                    status: alarm['status'] as LaundryAlarmStatus,
                    time: alarm['time'] as String,
                    description: alarm['description'] as String,
                    reason: alarm['reason'] as String?,
                  );
                }).toList();

                return _DateSection(
                  date: section['date'] as String,
                  alarms: alarms,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSection extends StatelessWidget {
  final String date;
  final List<_AlarmData> alarms;

  const _DateSection({
    required this.date,
    required this.alarms,
  });

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

class _DateDivider extends StatelessWidget {
  final String date;

  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: WasherColor.baseGray200,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            date,
            style: WasherTypography.body4(WasherColor.baseGray200),
          ),
        ),
        const Expanded(
          child: Divider(
            color: WasherColor.baseGray200,
            thickness: 1,
          ),
        ),
      ],
    );
  }
}
