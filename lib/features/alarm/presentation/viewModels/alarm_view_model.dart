import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/features/alarm/data/repositories/alarm_repository_impl.dart';
import 'package:washer/features/alarm/presentation/states/alarm_ui_state.dart';

class AlarmViewModel extends Notifier<AlarmUiState> {
  bool _hasLoaded = false;

  @override
  AlarmUiState build() {
    return const AlarmUiState();
  }

  Future<void> fetchAlarmList({bool force = false}) async {
    if (_hasLoaded && !force) {
      return;
    }

    state = state.copyWith(
      status: AlarmUiStatus.loading,
      clearErrorMessage: true,
    );

    try {
      final alarms = await ref.read(alarmRepositoryProvider).getAlarmList();
      _hasLoaded = true;
      state = state.copyWith(
        status: AlarmUiStatus.success,
        alarms: alarms,
        clearErrorMessage: true,
      );
    } catch (_) {
      state = state.copyWith(
        status: AlarmUiStatus.error,
        errorMessage: '알람을 불러오지 못했습니다. 잠시 후 다시 시도해주세요.',
      );
    }
  }
}

final alarmViewModelProvider = NotifierProvider<AlarmViewModel, AlarmUiState>(
  AlarmViewModel.new,
);
