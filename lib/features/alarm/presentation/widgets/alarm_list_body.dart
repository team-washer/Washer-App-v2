import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/utils/date_time_formatter.dart';
import 'package:washer/features/alarm/data/models/local/alarm_model.dart';
import 'package:washer/features/alarm/presentation/providers/alarm_provider.dart';
import 'package:washer/features/alarm/presentation/states/alarm_state.dart';
import 'package:washer/features/alarm/presentation/widgets/alarm_date_section.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_typography.dart';

/// 알람 상태(초기/로딩/오류/성공)에 따라 본문을 그리는 위젯
class AlarmListBody extends ConsumerWidget {
  const AlarmListBody({super.key, required this.state});

  final AlarmState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (state.status) {
      case AlarmStatus.initial:
        return Center(
          child: Text(
            '홈 화면을 새로고침하면 알림이 갱신됩니다.',
            style: WasherTypography.body1(WasherColor.baseGray500),
            textAlign: TextAlign.center,
          ),
        );
      case AlarmStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case AlarmStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.errorMessage ?? '알람을 불러오지 못했습니다.',
                style: WasherTypography.body1(WasherColor.baseGray500),
                textAlign: TextAlign.center,
              ),
              AppGap.v12,
              TextButton(
                onPressed: () {
                  ref
                      .read(alarmProvider.notifier)
                      .fetchAlarmList(
                        force: true,
                      );
                },
                child: const Text('다시 시도'),
              ),
            ],
          ),
        );
      case AlarmStatus.success:
        if (state.alarms.isEmpty) {
          return Center(
            child: Text(
              '알림이 없습니다!',
              style: WasherTypography.body1(WasherColor.baseGray500),
            ),
          );
        }

        final dateSections = _buildDateSections(state.alarms);

        return ListView.builder(
          itemCount: dateSections.length,
          itemBuilder: (context, index) {
            final section = dateSections[index];

            return AlarmDateSection(
              date: section.date,
              alarms: section.alarms,
            );
          },
        );
    }
  }
}

/// 알람을 최신순으로 정렬한 뒤 날짜(짧은 형식) 기준으로 그룹화한다.
///
/// 파싱 가능한 시각이 없는 항목은 뒤로 보내고, 날짜 포맷이 비면 원본 문자열을 쓴다.
List<({String date, List<AlarmDisplayItem> alarms})> _buildDateSections(
  List<AlarmModel> alarms,
) {
  final sortedAlarms = [...alarms]
    ..sort((a, b) {
      final aParsed = DateTime.tryParse(a.time);
      final bParsed = DateTime.tryParse(b.time);

      if (aParsed != null && bParsed != null) {
        return bParsed.compareTo(aParsed);
      }

      if (aParsed != null) {
        return -1;
      }

      if (bParsed != null) {
        return 1;
      }

      return b.time.compareTo(a.time);
    });

  final grouped = <String, List<AlarmDisplayItem>>{};

  for (final alarm in sortedAlarms) {
    final parsed = DateTime.tryParse(alarm.time);
    final sectionDate = DateTimeFormatter.formatToShortDate(alarm.time);
    final time = DateTimeFormatter.formatToShortWithTime(alarm.time);

    grouped
        .putIfAbsent(
          sectionDate.isNotEmpty ? sectionDate : alarm.time,
          () => <AlarmDisplayItem>[],
        )
        .add(
          AlarmDisplayItem(
            status: alarm.status,
            time: time.isNotEmpty ? time : alarm.time,
            description: alarm.description,
            createdAt: parsed,
          ),
        );
  }

  return grouped.entries
      .map((entry) => (date: entry.key, alarms: entry.value))
      .toList(growable: false);
}
