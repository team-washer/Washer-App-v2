import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/notifications/notification_service.dart';
import 'package:washer/features/alarm/data/data_sources/alarm_data_source.dart';
import 'package:washer/features/alarm/data/models/response/alarm_list_response.dart';
import 'package:washer/features/alarm/data/repositories/alarm_repository.dart';

class _FakeAlarmDataSource implements AlarmDataSource {
  final registeredTokens = <String>[];
  Completer<void>? registrationCompleter;
  var deleteCount = 0;

  @override
  Future<void> registerFcmToken(String token) async {
    registeredTokens.add(token);
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
  _FakeNotificationService({this.token});

  String? token;
  var deleteCount = 0;

  @override
  Stream<String> get onTokenRefresh => const Stream<String>.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> ensureFcmToken() async => token;

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

void main() {
  group('AlarmRepository FCM token registration', () {
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
}
