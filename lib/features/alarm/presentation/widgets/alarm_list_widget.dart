import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/enums/laundry_alarm_status.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/features/alarm/domain/entities/alarm_model.dart';
import 'package:washer/features/alarm/presentation/states/alarm_ui_state.dart';
import 'package:washer/features/alarm/presentation/viewmodels/alarm_view_model.dart';
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
    final state = ref.watch(alarmViewModelProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('알람', style: WasherTypography.subTitle3()),
        AppGap.v16,
        Expanded(child: _AlarmListBody(state: state)),
      ],
    );
  }
}

class _AlarmListBody extends ConsumerWidget {
  const _AlarmListBody({required this.state});

  final AlarmUiState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (state.status) {
      case AlarmUiStatus.initial:
      case AlarmUiStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case AlarmUiStatus.error:
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
                      .read(alarmViewModelProvider.notifier)
                      .fetchAlarmList(
                        force: true,
                      );
                },
                child: const Text('다시 시도'),
              ),
            ],
          ),
        );
      case AlarmUiStatus.success:
        if (state.alarms.isEmpty) {
          return Center(
            child: Text(
              '표시할 알람이 없습니다.',
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
  final grouped = <String, List<_AlarmData>>{};

  for (final alarm in alarms) {
    final parsed = DateTime.tryParse(alarm.time);
    final sectionDate = parsed != null
        ? _formatDate(parsed)
        : (alarm.time.length >= 8 ? alarm.time.substring(0, 8) : alarm.time);
    final time = parsed != null ? _formatDateTime(parsed) : alarm.time;

    grouped
        .putIfAbsent(sectionDate, () => <_AlarmData>[])
        .add(
          _AlarmData(
            status: _toLaundryAlarmStatus(alarm.status),
            time: time,
            description: alarm.description,
            reason: alarm.reason,
          ),
        );
  }

  return grouped.entries
      .map((entry) => (date: entry.key, alarms: entry.value))
      .toList(growable: false);
}

String _formatDate(DateTime dateTime) {
  final year = (dateTime.year % 100).toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  return '$year.$month.$day';
}

String _formatDateTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '${_formatDate(dateTime)} $hour:$minute';
}

LaundryAlarmStatus _toLaundryAlarmStatus(String status) {
  switch (status) {
    case 'washComplete':
      return LaundryAlarmStatus.washComplete;
    case 'dryComplete':
      return LaundryAlarmStatus.dryComplete;
    case 'washerError':
      return LaundryAlarmStatus.washerError;
    case 'dryerError':
      return LaundryAlarmStatus.dryerError;
    case 'usageWarning':
      return LaundryAlarmStatus.usageWarning;
    default:
      return LaundryAlarmStatus.usageWarning;
  }
}
