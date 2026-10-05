import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/network/error.dart';
import 'package:washer/core/network/session_generation_provider.dart';
import 'package:washer/features/alarm/data/repositories/alarm_repository.dart';
import 'package:washer/features/alarm/presentation/states/alarm_state.dart';

/// 알람 목록 조회와 화면 이탈 시 정리를 담당하는 Notifier.
class AlarmNotifier extends Notifier<AlarmState> {
  // 한 번 로드된 뒤에는 force 없이 다시 조회하지 않기 위한 플래그
  bool _hasLoaded = false;

  // 화면 이탈 정리(삭제 → 재조회)가 진행 중이면 그 작업. 없으면 null
  Future<void>? _clearing;

  // 가장 최근에 시작한 조회 번호. 늦게 도착한 이전 조회의 응답은 버린다.
  int _requestId = 0;

  // 화면을 떠날 때마다 증가한다. 떠나기 전에 시작한 조회가 늦게 성공해도
  // 초기화한 로드 플래그를 다시 세우지 않게 하기 위한 값이다.
  int _leaveCount = 0;

  @override
  AlarmState build() {
    // 세션이 바뀌면 이전 사용자의 알림과 로드 플래그를 비워 새로 조회하게 한다.
    // 이전 세션의 이탈 정리는 새 세션의 조회가 기다리지 않도록 떼어 낸다.
    ref.listen(sessionGenerationProvider, (_, _) {
      _hasLoaded = false;
      _clearing = null;
      state = const AlarmState();
    });
    return const AlarmState();
  }

  /// 알람 목록을 불러온다. 이미 로드됐다면 [force]가 true일 때만 다시 조회한다.
  ///
  /// 화면 이탈 정리가 진행 중이면 정리가 끝난 뒤 다시 조회한다.
  /// 정리 도중의 응답에는 그 사이 생긴 알림이 빠져 있을 수 있기 때문이다.
  Future<void> fetchAlarmList({bool force = false}) async {
    final clearing = _clearing;
    if (clearing != null) {
      await clearing;
      force = true;
    }

    if (_hasLoaded && !force) {
      return;
    }

    await _loadAlarmList();
  }

  // 정리 작업 안에서도 쓰므로 진행 중인 정리를 기다리지 않는다.
  Future<void> _loadAlarmList() async {
    final requestId = ++_requestId;
    final leaveCount = _leaveCount;
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

    // 더 최신 조회가 시작됐으면 이 응답으로 상태를 덮지 않는다.
    if (requestId != _requestId) {
      return;
    }

    switch (result) {
      case ResultSuccess(:final value):
        // 조회 중에 화면을 떠났으면 다음 진입에서 다시 조회하도록 플래그는 두지 않는다.
        if (leaveCount == _leaveCount) {
          _hasLoaded = true;
        }
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
  ///
  /// 정리가 이미 진행 중이면(알림 화면이 겹쳐 열렸다 닫히는 경우 등) 새로
  /// 시작하지 않고 진행 중인 정리를 함께 기다린다.
  Future<void> clearAllOnLeave() async {
    final inFlight = _clearing;
    if (inFlight != null) {
      return inFlight;
    }

    _leaveCount++;

    if (state.alarms.isEmpty) {
      // 지울 알림은 없지만 머무는 동안 새 알림이 생겼을 수 있으므로
      // 다음 진입에서 다시 조회하도록 로드 플래그만 초기화한다.
      _hasLoaded = false;
      return;
    }

    final clearing = _deleteAllAndReload();
    _clearing = clearing;
    try {
      await clearing;
    } finally {
      if (identical(_clearing, clearing)) {
        _clearing = null;
      }
    }
  }

  Future<void> _deleteAllAndReload() async {
    final session = ref.read(sessionGenerationProvider);

    await ref.read(alarmRepositoryProvider).deleteAllNotifications();
    // 정리 중에 세션이 바뀌었으면 새 세션의 상태·로드 플래그를 건드리지 않는다.
    if (ref.read(sessionGenerationProvider) != session) {
      return;
    }

    await _loadAlarmList();
    if (ref.read(sessionGenerationProvider) != session) {
      return;
    }

    // 다음에 화면을 다시 열면 또 새로 불러오도록 로드 플래그를 초기화한다.
    // 정리 중에 다시 들어온 조회는 이 작업이 끝난 뒤에 시작하므로 덮어쓰지 않는다.
    _hasLoaded = false;
  }
}

final alarmProvider = NotifierProvider<AlarmNotifier, AlarmState>(
  AlarmNotifier.new,
);
