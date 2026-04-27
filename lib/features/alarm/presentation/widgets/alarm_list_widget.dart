import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/core/utils/date_time_formatter.dart';
import 'package:washer/features/alarm/data/models/local/alarm_model.dart';
import 'package:washer/features/alarm/data/models/alarm_type.dart';
import 'package:washer/features/alarm/presentation/states/alarm_state.dart';
import 'package:washer/features/alarm/presentation/providers/alarm_provider.dart';
import 'package:washer/features/alarm/presentation/widgets/machine_state_widget.dart';

part 'local_widgets/alarm_date_section.dart';
part 'local_widgets/alarm_date_divider.dart';

/// 날짜별 알람 목록을 그룹화하여 표시하는 위젯
///
/// 기능:
/// - 날짜 분류 규칙
/// - 날짜 분류기 링크 제공
/// - 스크롤 펴닝
class AlarmListWidget extends ConsumerWidget {
  const AlarmListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(alarmProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '알림',
          style: WasherTypography.subTitle3(
            WasherColor.baseGray700,
          ),
        ),
        AppGap.v16,
        Expanded(child: _AlarmListBody(state: state)),
      ],
    );
  }
}

class _AlarmListBody extends ConsumerWidget {
  const _AlarmListBody({required this.state});

  final AlarmState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (state.status) {
      case AlarmStatus.initial:
        return Center(
          child: Text(
            '홈 화면을 새로고침하면 알림이 갱신됩니다.',
            style: WasherTypography.body1(WasherColor.baseGray400),
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
                style: WasherTypography.body1(WasherColor.baseGray400),
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
              style: WasherTypography.body1(WasherColor.baseGray400),
            ),
          );
        }

        final dateSections = _buildDateSections(state.alarms);

        return ListView.builder(
          itemCount: dateSections.length,
          itemBuilder: (context, index) {
            final section = dateSections[index];

            return _DateSection(
              date: section.date,
              alarms: section.alarms,
            );
          },
        );
    }
  }
}

List<({String date, List<_AlarmData> alarms})> _buildDateSections(
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

  final grouped = <String, List<_AlarmData>>{};

  for (final alarm in sortedAlarms) {
    final parsed = DateTime.tryParse(alarm.time);
    final sectionDate = DateTimeFormatter.formatToShortDate(alarm.time);
    final time = DateTimeFormatter.formatToShortWithTime(alarm.time);

    grouped
        .putIfAbsent(
          sectionDate.isNotEmpty ? sectionDate : alarm.time,
          () => <_AlarmData>[],
        )
        .add(
          _AlarmData(
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
