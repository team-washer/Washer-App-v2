import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/network/error.dart';
import 'package:washer/core/network/session_generation_provider.dart';
import 'package:washer/features/alarm/data/repositories/alarm_repository.dart';
import 'package:washer/features/alarm/presentation/states/alarm_state.dart';

/// 알람 목록 조회와 화면 이탈 시 정리를 담당하는 Notifier.
class AlarmNotifier extends Notifier<AlarmState> {
  // 한 번 로드된 뒤에는 force 없이 다시 조회하지 않기 위한 플래그
  bool _hasLoaded = false;

  @override
  AlarmState build() {
    // 세션이 바뀌면 이전 사용자의 알림과 로드 플래그를 비워 새로 조회하게 한다.
    ref.listen(sessionGenerationProvider, (_, _) {
      _hasLoaded = false;
      state = const AlarmState();
    });
    return const AlarmState();
  }

  /// 알람 목록을 불러온다. 이미 로드됐다면 [force]가 true일 때만 다시 조회한다.
  Future<void> fetchAlarmList({bool force = false}) async {
    if (_hasLoaded && !force) {
      return;
    }

    state = state.copyWith(
      status: AlarmStatus.loading,
      errorMessage: null,
    );

    final session = ref.read(sessionGenerationProvider);
    final result = await guardApiCall(
      () => ref.read(alarmRepositoryProvider).fetchAlarms(),
      logName: 'AlarmNotifier',
    );

    // 조회 중에 세션이 바뀌었으면 이전 사용자의 응답을 반영하지 않는다.
    if (ref.read(sessionGenerationProvider) != session) {
      return;
    }

    switch (result) {
      case ResultSuccess(:final value):
        _hasLoaded = true;
        state = state.copyWith(
          status: AlarmStatus.success,
          alarms: value,
          errorMessage: null,
        );
      case ResultFailure(:final error):
        state = state.copyWith(
          status: AlarmStatus.error,
          errorMessage: error.message,
        );
    }
  }

  /// 알림 화면을 벗어날 때 서버의 모든 알림을 삭제하고, 서버에서 목록을
  /// 다시 불러와 상태(=뱃지)를 서버 기준으로 동기화한다.
  ///
  /// 로컬 상태를 임의로 비우지 않고 refetch하므로 삭제가 실패해도 UI가
  /// 실제 서버 상태와 어긋나지 않는다.
  /// (deleteAllNotifications는 내부에서 예외를 삼키므로 throw하지 않는다.)
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
