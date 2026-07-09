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
  // 알람 리스트
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

  /// 알림 화면을 벗어날 때 서버의 모든 알림을 삭제하고, 서버에서 목록을
  /// 다시 불러와 상태(=뱃지)를 서버 기준으로 동기화한다.
  ///
  /// 로컬 상태를 임의로 비우지 않고 refetch하므로 삭제가 실패해도 UI가
  /// 실제 서버 상태와 어긋나지 않는다.
  /// (deleteAllNotifications는 내부에서 예외를 삼키므로 throw하지 않는다.)
  // 
  Future<void> clearAllOnLeave() async {
    if (state.alarms.isEmpty) {
      return;
    }

    await ref.read(alarmRepositoryProvider).deleteAllNotifications();
    await fetchAlarmList(force: true);
    // 다음에 화면을 다시 열면 또 새로 불러오도록 로드 플래그를 초기화한다.
    _hasLoaded = false;
  }
}

final alarmProvider = NotifierProvider<AlarmNotifier, AlarmState>(
  AlarmNotifier.new,
);
