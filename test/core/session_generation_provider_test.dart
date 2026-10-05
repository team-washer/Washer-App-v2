import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/network/auth_notifier.dart';
import 'package:washer/core/network/error.dart';
import 'package:washer/core/network/session_generation_provider.dart';
import 'package:washer/core/notifications/fcm_sync_trigger.dart';
import 'package:washer/features/alarm/data/models/alarm_type.dart';
import 'package:washer/features/alarm/data/models/local/alarm_model.dart';
import 'package:washer/features/alarm/data/repositories/alarm_repository.dart';
import 'package:washer/features/alarm/presentation/providers/alarm_provider.dart';
import 'package:washer/features/alarm/presentation/states/alarm_state.dart';
import 'package:washer/features/auth/data/repositories/auth_repository.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_status_remote_data_source.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/local/machine_model.dart';
import 'package:washer/features/reservation/data/models/remote/reservation_availability_response.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_sync_controller.dart';
import 'package:washer/features/user/data/data_sources/remote/user_remote_data_source.dart';
import 'package:washer/features/user/data/models/my_user_model.dart';
import 'package:washer/features/user/presentation/providers/my_user_provider.dart';
import 'package:washer/features/user/presentation/providers/withdraw_provider.dart';

/// 알림 조회 응답 시점을 테스트가 직접 제어하는 fake.
class _ControlledAlarmRepository implements AlarmRepository {
  final requests = <Completer<List<AlarmModel>>>[];

  @override
  void enableFcmRegistration() {}

  @override
  void enableFcmRegistrationForExistingSession() {}

  @override
  void disableFcmRegistration({bool blockUntilLogin = false}) {}

  @override
  Future<List<AlarmModel>> fetchAlarms() {
    final completer = Completer<List<AlarmModel>>();
    requests.add(completer);
    return completer.future;
  }

  @override
  Future<void> deleteAllNotifications() async {}

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

/// 호실 목록·내 예약 응답 시점을 테스트가 직접 제어하는 fake.
class _ControlledReservationDataSource
    implements ReservationStatusRemoteDataSource {
  final roomRequests = <Completer<List<ActiveReservationModel>>>[];
  final mineRequests = <Completer<ActiveReservationModel?>>[];

  @override
  Future<List<ActiveReservationModel>> getActiveReservations() {
    final completer = Completer<List<ActiveReservationModel>>();
    roomRequests.add(completer);
    return completer.future;
  }

  @override
  Future<ActiveReservationModel?> getMyActiveReservation() {
    final completer = Completer<ActiveReservationModel?>();
    mineRequests.add(completer);
    return completer.future;
  }

  @override
  Future<MachineStatusResponse> getMachineStatus() async =>
      const MachineStatusResponse(machines: [], totalCount: 0);

  @override
  Future<ReservationAvailabilityResponse> getReservationAvailability() async =>
      const ReservationAvailabilityResponse();
}

/// 내 정보 응답 시점을 테스트가 직접 제어하는 fake.
class _ControlledUserDataSource implements UserRemoteDataSource {
  final requests = <Completer<MyUserModel?>>[];

  @override
  Future<MyUserModel?> getMyUser() {
    final completer = Completer<MyUserModel?>();
    requests.add(completer);
    return completer.future;
  }

  @override
  Future<void> withdraw() async {}
}

/// 로그아웃 API를 호출하지 않는 fake. 탈퇴 성공 경로만 검증한다.
class _FakeAuthRepository implements AuthRepository {
  @override
  Future<void> login({
    required String authCode,
    required String redirectUri,
  }) async {}

  @override
  Future<void> logout() async {}
}

AlarmModel _alarm(String id) => AlarmModel(
  id: id,
  status: AlarmType.COMPLETION,
  time: '2026-09-30T21:00:00',
  description: '세탁이 완료되었습니다.',
);

ActiveReservationModel _reservation({required int id, required int userId}) {
  return ActiveReservationModel(
    id: id,
    userId: userId,
    userName: '사용자$userId',
    userRoomNumber: '420',
    machineId: id,
    machineName: 'Washer-4F-L1',
    status: 'RUNNING',
  );
}

const _previousUser = MyUserModel(id: 1, name: '이전 사용자', roomNumber: '420');
const _nextUser = MyUserModel(id: 2, name: '새 사용자', roomNumber: '301');

/// 다음 microtask까지 진행시켜, 대기 중인 요청이 시작될 기회를 준다.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _ControlledAlarmRepository alarmRepository;
  late _ControlledReservationDataSource reservationDataSource;
  late _ControlledUserDataSource userDataSource;
  late ProviderContainer container;

  setUp(() {
    alarmRepository = _ControlledAlarmRepository();
    reservationDataSource = _ControlledReservationDataSource();
    userDataSource = _ControlledUserDataSource();
    container = ProviderContainer(
      overrides: [
        alarmRepositoryProvider.overrideWithValue(alarmRepository),
        reservationStatusRemoteDataSourceProvider.overrideWithValue(
          reservationDataSource,
        ),
        userRemoteDataSourceProvider.overrideWithValue(userDataSource),
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      ],
    );
    addTearDown(() {
      container.read(reservationSyncControllerProvider).stopPolling();
      container.dispose();
    });
  });

  group('sessionGenerationProvider', () {
    test('authNotifier.logout()이 호출되면 세대가 오른다', () {
      expect(container.read(sessionGenerationProvider), 0);

      authNotifier.logout();

      expect(container.read(sessionGenerationProvider), 1);
    });
  });

  group('알림 목록', () {
    test('로그아웃하면 이전 사용자의 알림이 비워지고 다음 조회는 실제로 다시 요청한다', () async {
      final notifier = container.read(alarmProvider.notifier);
      final first = notifier.fetchAlarmList();
      alarmRepository.requests.single.complete([_alarm('old')]);
      await first;
      expect(container.read(alarmProvider).alarms, [_alarm('old')]);

      authNotifier.logout();

      // 새 응답이 오기 전에도 이전 사용자의 알림은 보이지 않는다.
      expect(container.read(alarmProvider), const AlarmState());

      final second = notifier.fetchAlarmList();
      expect(alarmRepository.requests, hasLength(2));
      alarmRepository.requests.last.complete([_alarm('new')]);
      await second;
      expect(container.read(alarmProvider).alarms, [_alarm('new')]);
    });

    test('세션이 바뀐 뒤 도착한 이전 세션의 응답은 반영하지 않는다', () async {
      final notifier = container.read(alarmProvider.notifier);
      final stale = notifier.fetchAlarmList();

      authNotifier.logout();
      alarmRepository.requests.single.complete([_alarm('old')]);
      await stale;

      expect(container.read(alarmProvider), const AlarmState());

      // 이전 세션 응답이 로드 플래그를 세우지 않아 새 세션에서 다시 조회한다.
      unawaited(notifier.fetchAlarmList());
      expect(alarmRepository.requests, hasLength(2));
    });
  });

  group('활성 예약 목록', () {
    List<ActiveReservationModel>? currentList() =>
        container.read(activeReservationProvider).value;

    test('로그아웃하면 목록이 비워지고 ensureLoaded가 새 사용자 목록을 다시 요청한다', () async {
      final initial = container.read(activeReservationProvider.future);
      await _settle();
      reservationDataSource.roomRequests.single.complete([
        _reservation(id: 10, userId: 1),
      ]);
      await initial;

      authNotifier.logout();
      expect(currentList(), isEmpty);

      final notifier = container.read(activeReservationProvider.notifier);
      final reload = notifier.ensureLoaded();
      expect(reservationDataSource.roomRequests, hasLength(2));
      reservationDataSource.roomRequests.last.complete([
        _reservation(id: 20, userId: 2),
      ]);
      await reload;

      expect(currentList(), [_reservation(id: 20, userId: 2)]);
    });

    test('세션이 바뀐 뒤 도착한 이전 세션의 목록·오류·polling 응답은 반영하지 않는다', () async {
      final initial = container.read(activeReservationProvider.future);
      await _settle();
      reservationDataSource.roomRequests.single.complete(const []);
      await initial;

      final notifier = container.read(activeReservationProvider.notifier);
      final controller = container.read(reservationSyncControllerProvider);
      final staleRefresh = notifier.refresh();
      final staleReload = notifier.reloadInBackground();
      final stalePoll = controller.syncActiveReservation();
      await _settle();

      authNotifier.logout();

      reservationDataSource.roomRequests[1].complete([
        _reservation(id: 10, userId: 1),
      ]);
      reservationDataSource.roomRequests[2].completeError(
        Exception('이전 세션 오류'),
      );
      reservationDataSource.mineRequests.single.complete(
        _reservation(id: 11, userId: 1),
      );
      await Future.wait([staleRefresh, staleReload, stalePoll]);

      expect(container.read(activeReservationProvider), isA<AsyncData>());
      expect(currentList(), isEmpty);
      expect(container.read(pollingErrorProvider), isNull);
    });

    test('로그아웃하면 polling이 멈추고 오류 안내가 비워진다', () {
      final controller = container.read(reservationSyncControllerProvider);
      controller.startPolling(reservationId: 10, userId: 1);
      container.read(pollingErrorProvider.notifier).state = AppException(
        message: '서버 상태가 지연되고 있습니다.',
      );

      authNotifier.logout();

      expect(controller.isPolling, isFalse);
      expect(container.read(pollingErrorProvider), isNull);
    });
  });

  group('내 정보', () {
    test('로그아웃하면 이전 사용자 정보가 비워진다', () async {
      container.read(myUserProvider.notifier).setUser(_previousUser);

      authNotifier.logout();

      expect(container.read(myUserProvider).value, isNull);
    });

    test('세션이 바뀐 뒤 도착한 이전 세션의 조회 응답은 반영하지 않는다', () async {
      final initial = container.read(myUserProvider.future);
      await _settle();
      userDataSource.requests.single.complete(_previousUser);
      await initial;

      final notifier = container.read(myUserProvider.notifier);
      final staleRefresh = notifier.refresh();
      await _settle();

      authNotifier.logout();
      notifier.setUser(_nextUser);
      userDataSource.requests.last.complete(_previousUser);
      await staleRefresh;

      expect(container.read(myUserProvider).value, _nextUser);
    });
  });

  group('내 정보 최초 조회와 세션 전환', () {
    test('최초 조회 중 세션이 바뀌면 늦게 온 이전 사용자 정보가 새 사용자를 덮어쓰지 않는다', () async {
      final initial = container.read(myUserProvider.future);
      await _settle();

      authNotifier.logout();
      container.read(myUserProvider.notifier).setUser(_nextUser);
      userDataSource.requests.single.complete(_previousUser);
      await initial;

      expect(container.read(myUserProvider).value, _nextUser);
    });

    test('최초 조회 중 세션이 바뀌면 이전 세션의 조회 오류가 새 사용자를 덮어쓰지 않는다', () async {
      final initial = container.read(myUserProvider.future);
      await _settle();

      authNotifier.logout();
      container.read(myUserProvider.notifier).setUser(_nextUser);
      userDataSource.requests.single.completeError(Exception('이전 세션 오류'));
      await initial;

      expect(container.read(myUserProvider), isA<AsyncData<MyUserModel?>>());
      expect(container.read(myUserProvider).value, _nextUser);
    });
  });

  group('회원 탈퇴', () {
    test('탈퇴에 성공하면 로그인 화면 이동 전에도 사용자별 상태를 비운다', () async {
      final alarms = container.read(alarmProvider.notifier);
      final fetch = alarms.fetchAlarmList();
      alarmRepository.requests.single.complete([_alarm('old')]);
      await fetch;
      final controller = container.read(reservationSyncControllerProvider);
      controller.startPolling(reservationId: 10, userId: 1);
      container.read(myUserProvider.notifier).setUser(_previousUser);

      final didWithdraw = await container
          .read(withdrawProvider.notifier)
          .withdraw();

      expect(didWithdraw, isTrue);
      expect(container.read(alarmProvider), const AlarmState());
      expect(controller.isPolling, isFalse);
      expect(container.read(myUserProvider).value, isNull);
    });
  });
}
