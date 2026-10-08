import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/notifications/notification_service.dart';

class _Settings extends Fake implements NotificationSettings {
  _Settings(this.authorizationStatus);

  @override
  final AuthorizationStatus authorizationStatus;
}

class _Messaging extends Fake implements FirebaseMessaging {
  final tokens = StreamController<String>.broadcast();
  int permissionRequests = 0;
  int presentationRequests = 0;
  int autoInitRequests = 0;
  int permissionFailures = 0;
  int tokenRefreshSubscriptions = 0;
  AuthorizationStatus permission = AuthorizationStatus.authorized;

  @override
  Stream<String> get onTokenRefresh {
    tokenRefreshSubscriptions++;
    return tokens.stream;
  }

  @override
  Future<void> setAutoInitEnabled(bool enabled) async {
    expect(enabled, isTrue);
    autoInitRequests++;
  }

  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
    bool providesAppNotificationSettings = false,
  }) async {
    expect([alert, badge, sound], everyElement(isTrue));
    permissionRequests++;
    if (permissionFailures > 0) {
      permissionFailures--;
      throw PlatformException(code: 'permission_failed');
    }
    return _Settings(permission);
  }

  @override
  Future<void> setForegroundNotificationPresentationOptions({
    bool alert = false,
    bool badge = false,
    bool sound = false,
  }) async {
    expect([alert, badge, sound], everyElement(isTrue));
    presentationRequests++;
  }

  @override
  Future<String?> getToken({String? vapidKey}) async => 'current-token';
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const firebaseChannel = MethodChannel(
    'plugins.flutter.io/firebase_messaging',
  );
  late _Messaging messaging;
  late NotificationService service;

  setUp(() {
    messaging = _Messaging();
    FlutterSecureStorage.setMockInitialValues({});
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      firebaseChannel,
      (_) async => <String, dynamic>{},
    );
    service = NotificationService(messaging, const FlutterSecureStorage());
  });

  tearDown(() async {
    service.dispose();
    await messaging.tokens.close();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      firebaseChannel,
      null,
    );
  });

  test('concurrent/repeated initialization runs setup once', () async {
    await Future.wait([service.initialize(), service.initialize()]);
    await service.initialize();
    expect(messaging.permissionRequests, 1);
    expect(messaging.autoInitRequests, 1);
    expect(messaging.presentationRequests, 1);
    expect(messaging.tokenRefreshSubscriptions, 1);
    expect(messaging.tokens.hasListener, isTrue);
  });

  test('permission denial does not break FCM token acquisition', () async {
    messaging.permission = AuthorizationStatus.denied;
    expect(await service.ensureFcmToken(), 'current-token');
    expect(await service.getStoredFcmToken(), 'current-token');
    expect(messaging.permissionRequests, 1);
  });

  test(
    'failed initialization retries without duplicating subscriptions',
    () async {
      messaging.permissionFailures = 1;
      await expectLater(
        service.initialize(),
        throwsA(isA<PlatformException>()),
      );
      await service.initialize();
      expect(messaging.permissionRequests, 2);
      expect(messaging.presentationRequests, 1);
      expect(messaging.tokenRefreshSubscriptions, 1);
      messaging.tokens.add('refreshed-token');
      await Future<void>.delayed(Duration.zero);
      expect(await service.getStoredFcmToken(), 'refreshed-token');
      service.dispose();
      expect(messaging.tokens.hasListener, isFalse);
    },
  );

  test('token refresh updates secure storage', () async {
    await service.initialize();
    messaging.tokens.add('refreshed-token');
    await Future<void>.delayed(Duration.zero);
    expect(await service.getStoredFcmToken(), 'refreshed-token');
  });

  test('dispose cancels token refresh storage subscription', () async {
    FlutterSecureStorage.setMockInitialValues({
      fcmTokenStorageKey: 'old-token',
    });
    await service.initialize();
    service.dispose();
    expect(messaging.tokens.hasListener, isFalse);
    messaging.tokens.add('late-token');
    await Future<void>.delayed(Duration.zero);
    expect(await service.getStoredFcmToken(), 'old-token');
  });

  test(
    'ensureFcmToken replaces stale storage with the Firebase token',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        fcmTokenStorageKey: 'old-token',
      });
      expect(await service.ensureFcmToken(), 'current-token');
      expect(await service.getStoredFcmToken(), 'current-token');
    },
  );
}
