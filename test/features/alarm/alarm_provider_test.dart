import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/network/session_generation_provider.dart';
import 'package:washer/core/notifications/fcm_sync_trigger.dart';
import 'package:washer/features/alarm/data/models/alarm_type.dart';
import 'package:washer/features/alarm/data/models/local/alarm_model.dart';
import 'package:washer/features/alarm/data/repositories/alarm_repository.dart';
import 'package:washer/features/alarm/presentation/providers/alarm_provider.dart';
import 'package:washer/features/alarm/presentation/states/alarm_state.dart';

/// 서버의 알림 목록을 테스트가 직접 바꾸고, 조회·삭제 호출 횟수를 세는 fake.
///
/// 서버는 요청을 받은 시점에 처리를 끝내고, [fetchGate]·[deleteGate]가 있으면
/// 그 응답의 전달만 늦춘다(다음 요청 한 번에만 적용).
class _FakeAlarmRepository implements AlarmRepository {
  var serverAlarms = <AlarmModel>[];
  var fetchCount = 0;
  var deleteCount = 0;
  Completer<void>? fetchGate;
  Completer<void>? deleteGate;

  @override
  Future<List<AlarmModel>> fetchAlarms() async {
    fetchCount++;
    final snapshot = List.of(serverAlarms);
    final gate = fetchGate;
    fetchGate = null;
    if (gate != null) {
      await gate.future;
    }
    return snapshot;
  }

  @override
  Future<void> deleteAllNotifications() async {
    deleteCount++;
    serverAlarms = [];
    final gate = deleteGate;
    deleteGate = null;
    if (gate != null) {
      await gate.future;
    }
  }

  @override
  void enableFcmRegistration() {}

  @override
  void enableFcmRegistrationForExistingSession() {}

  @override
  void disableFcmRegistration({bool blockUntilLogin = false}) {}

  @override
  Future<void> registerCurrentFcmToken({
    FcmSyncTrigger trigger = FcmSyncTrigger.manual,
  }) async {}

  @override
  Future<void> registerFcmToken(
    String fcmToken, {
    FcmSyncTrigger trigger = FcmSyncTrigger.tokenRefresh,
    bool forceServerSync = false,
  }) async {}

  @override
  Future<void> deleteFcmToken() async {}

  @override
  void dispose() {}
}

AlarmModel _alarm(String id) => AlarmModel(
  id: id,
  status: AlarmType.COMPLETION,
  time: '2026-10-04T21:00:00',
  description: '세탁이 완료되었습니다.',
);

void main() {
  late _FakeAlarmRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _FakeAlarmRepository();
    container = ProviderContainer(
      overrides: [alarmRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  /// MainShell 뱃지와 같은 기준(알림이 하나라도 있으면 표시)
  bool hasBadge() => container.read(alarmProvider).alarms.isNotEmpty;

  group('AlarmNotifier 화면 재진입 조회', () {
    test('빈 목록으로 화면을 떠난 뒤 새 알림이 생기면 재진입에서 다시 조회한다', () async {
      final notifier = container.read(alarmProvider.notifier);

      // 1. 빈 알림 목록을 조회한 뒤 화면 이탈
      await notifier.fetchAlarmList();
      expect(container.read(alarmProvider).alarms, isEmpty);
      expect(hasBadge(), isFalse);
      await notifier.clearAllOnLeave();

      // 2. 서버에 새 알림 추가
      repository.serverAlarms = [_alarm('new')];

      // 3. 홈 수동 갱신 없이 알림 화면 재진입
      await notifier.fetchAlarmList();

      expect(repository.fetchCount, 2);
      expect(container.read(alarmProvider).status, AlarmStatus.success);
      expect(container.read(alarmProvider).alarms, [_alarm('new')]);
      expect(hasBadge(), isTrue);
    });

    test('빈 목록으로 화면을 떠날 때는 삭제 API를 호출하지 않는다', () async {
      final notifier = container.read(alarmProvider.notifier);

      await notifier.fetchAlarmList();
      await notifier.clearAllOnLeave();

      expect(repository.deleteCount, 0);
      expect(repository.fetchCount, 1);
    });

    test('화면을 떠나기 전에는 force 없이 다시 조회하지 않는다', () async {
      final notifier = container.read(alarmProvider.notifier);

      await notifier.fetchAlarmList();
      await notifier.fetchAlarmList();

      expect(repository.fetchCount, 1);
    });

    test('알림이 있던 화면을 떠나면 서버 기준으로 비우고 재진입에서 다시 조회한다', () async {
      final notifier = container.read(alarmProvider.notifier);
      repository.serverAlarms = [_alarm('old')];

      await notifier.fetchAlarmList();
      expect(hasBadge(), isTrue);

      await notifier.clearAllOnLeave();
      expect(repository.deleteCount, 1);
      expect(container.read(alarmProvider).alarms, isEmpty);
      expect(hasBadge(), isFalse);

      repository.serverAlarms = [_alarm('new')];
      await notifier.fetchAlarmList();

      expect(repository.fetchCount, 3);
      expect(container.read(alarmProvider).alarms, [_alarm('new')]);
      expect(hasBadge(), isTrue);
    });
  });

  group('AlarmNotifier 이탈 정리 중 재진입', () {
    test('정리의 재조회 응답을 기다리는 중 다시 들어오면 정리가 끝난 뒤 새로 조회한다', () async {
      final notifier = container.read(alarmProvider.notifier);
      repository.serverAlarms = [_alarm('old')];
      await notifier.fetchAlarmList();

      // 정리의 재조회는 삭제 직후(빈 목록) 시점의 응답을 늦게 받는다.
      final gate = Completer<void>();
      repository.fetchGate = gate;
      final leave = notifier.clearAllOnLeave();
      await _settle();
      expect(repository.fetchCount, 2);

      // 그 사이 새 알림이 생기고 사용자가 알림 화면에 다시 들어온다.
      repository.serverAlarms = [_alarm('new')];
      final reenter = notifier.fetchAlarmList();
      gate.complete();
      await Future.wait([leave, reenter]);

      expect(repository.fetchCount, 3);
      expect(repository.deleteCount, 1);
      expect(container.read(alarmProvider).alarms, [_alarm('new')]);
      expect(hasBadge(), isTrue);
    });

    test('삭제 응답을 기다리는 중 다시 들어오면 정리가 끝난 뒤에 조회를 시작한다', () async {
      final notifier = container.read(alarmProvider.notifier);
      repository.serverAlarms = [_alarm('old')];
      await notifier.fetchAlarmList();

      final gate = Completer<void>();
      repository.deleteGate = gate;
      final leave = notifier.clearAllOnLeave();
      await _settle();

      final reenter = notifier.fetchAlarmList();
      await _settle();
      // 정리가 끝나기 전에는 재진입 조회를 보내지 않는다.
      expect(repository.fetchCount, 1);

      repository.serverAlarms = [_alarm('new')];
      gate.complete();
      await Future.wait([leave, reenter]);

      // 최초 조회 + 정리의 재조회 + 정리 후 재진입 조회
      expect(repository.fetchCount, 3);
      expect(container.read(alarmProvider).alarms, [_alarm('new')]);
      expect(hasBadge(), isTrue);
    });

    test('정리 중 재진입으로 조회한 뒤에는 화면에 머무는 동안 다시 조회하지 않는다', () async {
      final notifier = container.read(alarmProvider.notifier);
      repository.serverAlarms = [_alarm('old')];
      await notifier.fetchAlarmList();

      final gate = Completer<void>();
      repository.deleteGate = gate;
      final leave = notifier.clearAllOnLeave();
      await _settle();
      final reenter = notifier.fetchAlarmList();
      gate.complete();
      await Future.wait([leave, reenter]);
      final countAfterReenter = repository.fetchCount;

      // 정리 끝의 로드 플래그 초기화가 재진입 조회의 결과를 덮지 않아야 한다.
      await notifier.fetchAlarmList();

      expect(repository.fetchCount, countAfterReenter);
    });

    test('겹친 이탈 정리 호출은 삭제를 한 번만 하고 모든 호출이 끝난다', () async {
      final notifier = container.read(alarmProvider.notifier);
      repository.serverAlarms = [_alarm('old')];
      await notifier.fetchAlarmList();

      final gate = Completer<void>();
      repository.deleteGate = gate;
      final firstLeave = notifier.clearAllOnLeave();
      final secondLeave = notifier.clearAllOnLeave();
      final reenter = notifier.fetchAlarmList();
      final refresh = notifier.fetchAlarmList(force: true);
      await _settle();
      gate.complete();

      await Future.wait([
        firstLeave,
        secondLeave,
        reenter,
        refresh,
      ]).timeout(const Duration(seconds: 1));

      expect(repository.deleteCount, 1);
      expect(container.read(alarmProvider).status, AlarmStatus.success);
    });

    test('정리 중 세션이 바뀌면 새 세션 조회는 정리를 기다리지 않고 정리가 새 상태를 덮지 않는다', () async {
      final notifier = container.read(alarmProvider.notifier);
      repository.serverAlarms = [_alarm('old')];
      await notifier.fetchAlarmList();

      final gate = Completer<void>();
      repository.deleteGate = gate;
      final leave = notifier.clearAllOnLeave();
      await _settle();

      container.read(sessionGenerationProvider.notifier).advance();
      repository.serverAlarms = [_alarm('next')];
      await notifier.fetchAlarmList().timeout(const Duration(seconds: 1));
      expect(repository.fetchCount, 2);
      expect(container.read(alarmProvider).alarms, [_alarm('next')]);

      gate.complete();
      await leave;
      await notifier.fetchAlarmList();

      // 이전 세션의 정리는 재조회·로드 플래그 초기화를 하지 않는다.
      expect(repository.fetchCount, 2);
      expect(container.read(alarmProvider).alarms, [_alarm('next')]);
    });
  });

  group('AlarmNotifier 이탈 전에 시작한 조회의 늦은 응답', () {
    test('진입 조회 응답 전에 빈 목록으로 떠나면 늦은 응답이 와도 재진입에서 다시 조회한다', () async {
      final notifier = container.read(alarmProvider.notifier);
      repository.serverAlarms = [_alarm('a')];

      // 진입 조회 응답이 오기 전에 화면을 떠난다(아직 목록은 비어 있음).
      final gate = Completer<void>();
      repository.fetchGate = gate;
      final enter = notifier.fetchAlarmList();
      await _settle();
      await notifier.clearAllOnLeave();
      expect(repository.deleteCount, 0);

      // 늦게 도착한 응답은 뱃지에 반영한다.
      gate.complete();
      await enter;
      expect(container.read(alarmProvider).alarms, [_alarm('a')]);
      expect(hasBadge(), isTrue);

      // 그 사이 새 알림이 생기면 재진입에서 다시 조회해 보여준다.
      repository.serverAlarms = [_alarm('a'), _alarm('new')];
      await notifier.fetchAlarmList();

      expect(repository.fetchCount, 2);
      expect(container.read(alarmProvider).alarms, [
        _alarm('a'),
        _alarm('new'),
      ]);
    });

    test('떠나기 전에 시작한 조회가 정리의 재조회보다 늦게 와도 삭제 전 목록으로 덮지 않는다', () async {
      final notifier = container.read(alarmProvider.notifier);
      repository.serverAlarms = [_alarm('old')];
      await notifier.fetchAlarmList();

      // 새로고침 응답이 늦어지는 동안 화면을 떠나 삭제 → 재조회가 끝난다.
      final gate = Completer<void>();
      repository.fetchGate = gate;
      final refresh = notifier.fetchAlarmList(force: true);
      await _settle();
      await notifier.clearAllOnLeave();
      expect(container.read(alarmProvider).alarms, isEmpty);

      // 삭제 전 목록을 담은 늦은 응답은 버린다.
      gate.complete();
      await refresh;
      expect(container.read(alarmProvider).alarms, isEmpty);
      expect(hasBadge(), isFalse);

      // 재진입에서는 다시 조회한다.
      repository.serverAlarms = [_alarm('new')];
      await notifier.fetchAlarmList();
      expect(repository.fetchCount, 4);
      expect(container.read(alarmProvider).alarms, [_alarm('new')]);
    });
  });
}

/// 대기 중인 비동기 작업이 진행될 기회를 준다.
Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
