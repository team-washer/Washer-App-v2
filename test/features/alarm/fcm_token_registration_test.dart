import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/core/notifications/notification_service.dart';
import 'package:washer/features/alarm/data/data_sources/alarm_data_source.dart';
import 'package:washer/features/alarm/data/models/response/alarm_list_response.dart';
import 'package:washer/features/alarm/data/repositories/alarm_repository.dart';

class _FakeAlarmDataSource implements AlarmDataSource {
  final registeredTokens = <String>[];
  Completer<void>? registrationCompleter;
  int registrationFailuresRemaining = 0;
  var deleteCount = 0;

  @override
  Future<void> registerFcmToken(String token) async {
    registeredTokens.add(token);
    if (registrationFailuresRemaining > 0) {
      registrationFailuresRemaining--;
      throw DioException(
        requestOptions: RequestOptions(path: 'notifications/fcm-token'),
        type: DioExceptionType.connectionError,
      );
    }
    final completer = registrationCompleter;
    if (completer != null) {
      await completer.future;
    }
  }

  @override
  Future<void> deleteFcmToken() async {
    deleteCount++;
  }

  @override
  Future<void> deleteAllNotifications() async {}

  @override
  Future<AlarmListResponse> getAlarmList() {
    throw UnimplementedError();
  }
}

class _FakeNotificationService implements NotificationService {
  _FakeNotificationService({
    this.token,
    List<FutureOr<String?> Function()> tokenResponses = const [],
  }) : _tokenResponses = List.of(tokenResponses);

  String? token;
  final List<FutureOr<String?> Function()> _tokenResponses;
  var ensureCount = 0;
  var deleteCount = 0;

  @override
  Stream<String> get onTokenRefresh => const Stream<String>.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> ensureFcmToken() async {
    ensureCount++;
    if (_tokenResponses.isNotEmpty) {
      return Future<String?>.sync(_tokenResponses.removeAt(0));
    }
    return token;
  }

  @override
  Future<String?> getStoredFcmToken() async => token;

  @override
  Future<void> deleteStoredFcmToken() async {
    deleteCount++;
    token = null;
  }

  @override
  void dispose() {}
}

Future<void> _flushEventQueue() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('AlarmRepository FCM token registration', () {
    test('registers immediately when the current token is ready', () async {
      final dataSource = _FakeAlarmDataSource();
      final notificationService = _FakeNotificationService(
        token: 'ready-token',
      );
      final repository = AlarmRepository(dataSource, notificationService)
        ..enableFcmRegistration();

      await repository.registerCurrentFcmToken();

      expect(notificationService.ensureCount, 1);
      expect(dataSource.registeredTokens, ['ready-token']);
    });

    test(
      'login starts a new cycle after token retries are exhausted',
      () async {
        final dataSource = _FakeAlarmDataSource();
        final notificationService = _FakeNotificationService(
          tokenResponses: [() => null, () => null, () => 'login-token'],
        );
        final repository = AlarmRepository(
          dataSource,
          notificationService,
          tokenPreparationRetryDelay: Duration.zero,
          maxTokenPreparationRetries: 1,
        );

        repository.enableFcmRegistrationForExistingSession();
        await repository.registerCurrentFcmToken();
        await _flushEventQueue();
        expect(notificationService.ensureCount, 2);

        repository.enableFcmRegistration();
        await repository.registerCurrentFcmToken();

        expect(notificationService.ensureCount, 3);
        expect(dataSource.registeredTokens, ['login-token']);
      },
    );

    test('app start registers for an existing active session', () async {
      final dataSource = _FakeAlarmDataSource();
      final notificationService = _FakeNotificationService(
        token: 'startup-token',
      );
      final repository = AlarmRepository(dataSource, notificationService);

      repository.enableFcmRegistrationForExistingSession();
      await repository.registerCurrentFcmToken();

      expect(notificationService.ensureCount, 1);
      expect(dataSource.registeredTokens, ['startup-token']);
    });

    test('shares token preparation between startup and login calls', () async {
      final tokenCompleter = Completer<String?>();
      final dataSource = _FakeAlarmDataSource();
      final notificationService = _FakeNotificationService(
        tokenResponses: [() => tokenCompleter.future],
      );
      final repository = AlarmRepository(dataSource, notificationService)
        ..enableFcmRegistration();

      final startupRegistration = repository.registerCurrentFcmToken();
      final loginRegistration = repository.registerCurrentFcmToken();
      tokenCompleter.complete('shared-token');

      await Future.wait([startupRegistration, loginRegistration]);

      expect(notificationService.ensureCount, 1);
      expect(dataSource.registeredTokens, ['shared-token']);
    });

    test('retries token preparation when APNS/FCM is not ready yet', () async {
      final dataSource = _FakeAlarmDataSource();
      final notificationService = _FakeNotificationService(
        tokenResponses: [() => null, () => 'late-token'],
      );
      final repository = AlarmRepository(
        dataSource,
        notificationService,
        tokenPreparationRetryDelay: Duration.zero,
      )..enableFcmRegistration();

      await repository.registerCurrentFcmToken();
      await _flushEventQueue();

      expect(notificationService.ensureCount, 2);
      expect(dataSource.registeredTokens, ['late-token']);
    });

    test('retries after the initial token preparation throws', () async {
      final dataSource = _FakeAlarmDataSource();
      final notificationService = _FakeNotificationService(
        tokenResponses: [
          () => throw StateError('FCM token unavailable'),
          () => 'retry-token',
        ],
      );
      final repository = AlarmRepository(
        dataSource,
        notificationService,
        tokenPreparationRetryDelay: Duration.zero,
      )..enableFcmRegistration();

      await repository.registerCurrentFcmToken();
      await _flushEventQueue();

      expect(notificationService.ensureCount, 2);
      expect(dataSource.registeredTokens, ['retry-token']);
    });

    test('stops token preparation after the configured retry limit', () async {
      final dataSource = _FakeAlarmDataSource();
      final notificationService = _FakeNotificationService(
        tokenResponses: [() => null, () => null, () => null, () => null],
      );
      final repository = AlarmRepository(
        dataSource,
        notificationService,
        tokenPreparationRetryDelay: Duration.zero,
        maxTokenPreparationRetries: 2,
      )..enableFcmRegistration();

      await repository.registerCurrentFcmToken();
      await _flushEventQueue();

      expect(notificationService.ensureCount, 3);
      expect(dataSource.registeredTokens, isEmpty);
    });

    test(
      'resume starts a new cycle after token retries are exhausted',
      () async {
        final dataSource = _FakeAlarmDataSource();
        final notificationService = _FakeNotificationService(
          tokenResponses: [
            () => null,
            () => null,
            () => null,
            () => null,
            () => 'resume-token',
          ],
        );
        final repository = AlarmRepository(
          dataSource,
          notificationService,
          tokenPreparationRetryDelay: Duration.zero,
          maxTokenPreparationRetries: 2,
        )..enableFcmRegistrationForExistingSession();

        await repository.registerCurrentFcmToken();
        await _flushEventQueue();
        expect(notificationService.ensureCount, 3);

        await repository.registerCurrentFcmToken();
        await _flushEventQueue();

        expect(notificationService.ensureCount, 5);
        expect(dataSource.registeredTokens, ['resume-token']);
      },
    );

    test('retries a transient server registration failure', () async {
      final dataSource = _FakeAlarmDataSource()
        ..registrationFailuresRemaining = 1;
      final repository = AlarmRepository(
        dataSource,
        _FakeNotificationService(),
        registrationRetryDelay: Duration.zero,
      )..enableFcmRegistration();

      await repository.registerFcmToken('server-retry-token');
      await _flushEventQueue();

      expect(dataSource.registeredTokens, [
        'server-retry-token',
        'server-retry-token',
      ]);
    });

    test(
      'explicit sync restarts exhausted server registration retries',
      () async {
        final dataSource = _FakeAlarmDataSource()
          ..registrationFailuresRemaining = 3;
        final repository = AlarmRepository(
          dataSource,
          _FakeNotificationService(token: 'retry-cycle-token'),
          registrationRetryDelay: Duration.zero,
          maxRegistrationRetries: 1,
        )..enableFcmRegistration();

        await repository.registerCurrentFcmToken();
        await _flushEventQueue();
        expect(dataSource.registeredTokens, hasLength(2));

        await repository.registerCurrentFcmToken();
        await _flushEventQueue();

        expect(dataSource.registeredTokens, [
          'retry-cycle-token',
          'retry-cycle-token',
          'retry-cycle-token',
          'retry-cycle-token',
        ]);
      },
    );

    test('does not register a prepared token after logout starts', () async {
      final tokenCompleter = Completer<String?>();
      final dataSource = _FakeAlarmDataSource();
      final notificationService = _FakeNotificationService(
        tokenResponses: [() => tokenCompleter.future],
      );
      final repository = AlarmRepository(dataSource, notificationService)
        ..enableFcmRegistration();

      final registration = repository.registerCurrentFcmToken();
      await Future<void>.delayed(Duration.zero);
      final logout = repository.deleteFcmToken();
      tokenCompleter.complete('token-after-logout');

      await Future.wait([registration, logout]);

      expect(dataSource.registeredTokens, isEmpty);
      expect(dataSource.deleteCount, 1);
      expect(notificationService.deleteCount, 1);
    });

    test('registers a refreshed token once and skips its duplicate', () async {
      final dataSource = _FakeAlarmDataSource();
      final repository = AlarmRepository(
        dataSource,
        _FakeNotificationService(),
      )..enableFcmRegistration();

      await repository.registerFcmToken('initial-token');
      await repository.registerFcmToken('refreshed-token');
      await repository.registerFcmToken('refreshed-token');

      expect(dataSource.registeredTokens, [
        'initial-token',
        'refreshed-token',
      ]);
    });

    test('onTokenRefresh registers the latest token with the server', () async {
      final dataSource = _FakeAlarmDataSource();
      final repository = AlarmRepository(
        dataSource,
        _FakeNotificationService(),
      )..enableFcmRegistrationForExistingSession();

      await repository.registerFcmToken('token-from-refresh-stream');

      expect(dataSource.registeredTokens, ['token-from-refresh-stream']);
    });

    test('동일한 토큰의 동시 등록 요청은 서버에 한 번만 전송한다', () async {
      final dataSource = _FakeAlarmDataSource()
        ..registrationCompleter = Completer<void>();
      final repository = AlarmRepository(
        dataSource,
        _FakeNotificationService(),
      )..enableFcmRegistration();

      final first = repository.registerFcmToken('same-token');
      final second = repository.registerFcmToken('same-token');
      dataSource.registrationCompleter!.complete();

      await Future.wait([first, second]);

      expect(dataSource.registeredTokens, ['same-token']);
    });

    test('로그아웃이 시작되면 진행 중 등록 뒤에 삭제하고 재등록을 막는다', () async {
      final dataSource = _FakeAlarmDataSource()
        ..registrationCompleter = Completer<void>();
      final notificationService = _FakeNotificationService(
        token: 'stored-token',
      );
      final repository = AlarmRepository(dataSource, notificationService)
        ..enableFcmRegistration();

      final inFlightRegistration = repository.registerFcmToken('old-token');
      final logout = repository.deleteFcmToken();
      final refreshDuringLogout = repository.registerFcmToken('new-token');

      dataSource.registrationCompleter!.complete();
      await Future.wait([
        inFlightRegistration,
        logout,
        refreshDuringLogout,
      ]);

      expect(dataSource.registeredTokens, ['old-token']);
      expect(dataSource.deleteCount, 1);
      expect(notificationService.deleteCount, 1);
    });

    test('로그아웃 차단 상태는 앱 초기화로 풀리지 않고 새 로그인으로만 풀린다', () async {
      final dataSource = _FakeAlarmDataSource();
      final repository = AlarmRepository(
        dataSource,
        _FakeNotificationService(),
      )..enableFcmRegistration();

      await repository.deleteFcmToken();
      repository.enableFcmRegistrationForExistingSession();
      await repository.registerFcmToken('blocked-token');

      expect(dataSource.registeredTokens, isEmpty);

      repository.enableFcmRegistration();
      await repository.registerFcmToken('new-login-token');

      expect(dataSource.registeredTokens, ['new-login-token']);
    });
  });

  group('FCM token log sanitization', () {
    test('redacts FCM and auth tokens', () {
      const fcmToken = 'fcm-secret-token-value';
      const accessToken = 'access-secret-token-value';
      const message =
          '''
Authorization: Bearer $accessToken
{token: $fcmToken, machineId: 1}
''';

      final sanitized = sanitizeDioLog(message);

      expect(sanitized, isNot(contains(fcmToken)));
      expect(sanitized, isNot(contains(accessToken)));
      expect(sanitized, contains('Authorization: Bearer [REDACTED]'));
      expect(sanitized, contains('token: [REDACTED]'));
    });

    test('keeps non-sensitive request fields', () {
      const message = '{machineId: 12, status: RUNNING}';

      expect(sanitizeDioLog(message), message);
    });
  });
}
