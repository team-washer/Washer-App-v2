import 'package:flutter/material.dart';
import 'package:washer/core/enums/laundry_alarm_status.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/features/alarm/presentation/widgets/machine_state_widget.dart';

part 'local_widgets/alarm_date_section.dart';
part 'local_widgets/alarm_date_divider.dart';

/// 날짜별 알람 목록을 그룹화하여 표시하는 위젯
///
/// 기능:
/// - 날짜 분류 규칙
/// - 날짜 분류기 링크 제공
/// - 스크롤 펴닝
// 목업 데이터
final _mockDateSections = [
  (
    date: '25.08.19',
    alarms: [
      _AlarmData(
        status: LaundryAlarmStatus.washComplete,
        time: '25.08.19 14:03',
        description: 'Washer-3F-L1의 세탁이 완료되었습니다. 빠른 시간 내에 수거해 주시기 바랍니다.',
      ),
      _AlarmData(
        status: LaundryAlarmStatus.dryComplete,
        time: '25.08.19 14:03',
        description: 'Dryer-3F-L1의 세탁이 완료되었습니다. 빠른 시간 내에 수거해 주시기 바랍니다.',
      ),
      _AlarmData(
        status: LaundryAlarmStatus.washComplete,
        time: '25.08.19 14:03',
        description: 'Washer-3F-L1의 세탁이 완료되었습니다. 빠른 시간 내에 수거해 주시기 바랍니다.',
      ),
      _AlarmData(
        status: LaundryAlarmStatus.dryerError,
        time: '25.08.19 14:03',
        description: 'Dryer-3F-L1 기기에 이상이 감지되었습니다. 빠른 시간 내에 확인해 주시기 바랍니다.',
      ),
      _AlarmData(
        status: LaundryAlarmStatus.usageWarning,
        time: '25.08.19 14:03',
        description: '신고 경고가 접수되었습니다. 물품을 확인해 주시기 바랍니다.',
        reason: '명백히 세탁 물품을 남겨둠',
      ),
    ],
  ),
  (
    date: '25.08.18',
    alarms: [
      _AlarmData(
        status: LaundryAlarmStatus.washComplete,
        time: '25.08.18 20:15',
        description: 'Washer-2F-L2의 세탁이 완료되었습니다. 빠른 시간 내에 수거해 주시기 바랍니다.',
      ),
      _AlarmData(
        status: LaundryAlarmStatus.dryComplete,
        time: '25.08.18 15:22',
        description: 'Dryer-1F-L1의 건조가 완료되었습니다. 빠른 시간 내에 수거해 주시기 바랍니다.',
      ),
    ],
  ),
  (
    date: '25.08.17',
    alarms: [
      _AlarmData(
        status: LaundryAlarmStatus.dryComplete,
        time: '25.08.17 16:45',
        description: 'Dryer-2F-R1의 건조가 완료되었습니다. 빠른 시간 내에 수거해 주시기 바랍니다.',
      ),
      _AlarmData(
        status: LaundryAlarmStatus.usageWarning,
        time: '25.08.17 12:20',
        description: '신고 경고가 접수되었습니다. 물품을 확인해 주시기 바랍니다.',
        reason: '기기를 장시간 점유',
      ),
      _AlarmData(
        status: LaundryAlarmStatus.washComplete,
        time: '25.08.17 10:00',
        description: 'Washer-1F-L1의 세탁이 완료되었습니다. 빠른 시간 내에 수거해 주시기 바랍니다.',
      ),
    ],
  ),
  (
    date: '25.08.16',
    alarms: [
      _AlarmData(
        status: LaundryAlarmStatus.dryerError,
        time: '25.08.16 22:10',
        description: 'Dryer-2F-L2 기기에 이상이 감지되었습니다. 빠른 시간 내에 확인해 주시기 바랍니다.',
      ),
      _AlarmData(
        status: LaundryAlarmStatus.washComplete,
        time: '25.08.16 19:40',
        description: 'Washer-3F-L2의 세탁이 완료되었습니다. 빠른 시간 내에 수거해 주시기 바랍니다.',
      ),
    ],
  ),
];

class AlarmListWidget extends StatelessWidget {
  const AlarmListWidget({super.key});

  /// 알람 목록 빌드
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('알람', style: WasherTypography.subTitle3()),
        AppGap.v16,
        Expanded(
          child: ListView.builder(
            itemCount: _mockDateSections.length,
            itemBuilder: (context, index) {
              final section = _mockDateSections[index];

              return _DateSection(
                date: section.date,
                alarms: section.alarms,
              );
            },
          ),
        ),
      ],
    );
  }
}
