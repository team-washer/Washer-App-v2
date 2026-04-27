import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/alarm/data/repositories/alarm_repository_provider.dart';
import 'package:washer/features/alarm/presentation/states/alarm_state.dart';

class AlarmNotifier extends Notifier<AlarmState> {
  bool _hasLoaded = false;

  @override
  AlarmState build() {
    return const AlarmState();
  }

  Future<void> fetchAlarmList({bool force = false}) async {
    if (_hasLoaded && !force) {
      return;
    }

    state = state.copyWith(
      status: AlarmStatus.loading,
      errorMessage: null,
    );

    try {
      final alarms = await ref.read(alarmRepositoryProvider).fetchAlarms();
      _hasLoaded = true;
      state = state.copyWith(
        status: AlarmStatus.success,
        alarms: alarms,
        errorMessage: null,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        '알람 목록을 불러오는 중 오류가 발생했습니다.',
        name: 'AlarmNotifier',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        status: AlarmStatus.error,
        errorMessage: '알람을 불러오지 못했습니다. 잠시 후 다시 시도해주세요.',
      );
    }
  }
}

final alarmProvider = NotifierProvider<AlarmNotifier, AlarmState>(
  AlarmNotifier.new,
);
