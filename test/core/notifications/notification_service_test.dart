import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/notifications/android_notification_display.dart';
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
  AuthorizationStatus permission = AuthorizationStatus.authorized;

  @override
  Stream<String> get onTokenRefresh => tokens.stream;

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
  const displayChannel = MethodChannel('washer/android-notifications');
  const firebaseChannel = MethodChannel(
    'plugins.flutter.io/firebase_messaging',
  );
  final displayCalls = <MethodCall>[];
  late _Messaging messaging;
  late NotificationService service;
  bool displayFails = false;

  Future<void> emitForeground() async {
    final completed = Completer<void>();
    binding.channelBuffers.push(
      firebaseChannel.name,
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall(
          'Messaging#onMessage',
          {
            'messageId': 'message-1',
            'notification': {'title': 'Laundry complete', 'body': 'Done'},
          },
        ),
      ),
      (_) => completed.complete(),
    );
    await completed.future;
    await Future<void>.delayed(Duration.zero);
  }

  setUp(() {
    messaging = _Messaging();
    FlutterSecureStorage.setMockInitialValues({});
    displayCalls.clear();
    displayFails = false;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      firebaseChannel,
      (_) async => <String, dynamic>{},
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(displayChannel, (
      call,
    ) async {
      displayCalls.add(call);
      if (displayFails) throw PlatformException(code: 'display_failed');
      return call.method == 'showNotification' ? true : null;
    });
    service = NotificationService(
      messaging,
      const FlutterSecureStorage(),
      null,
      const AndroidNotificationDisplay(),
    );
  });

  tearDown(() async {
    service.dispose();
    await messaging.tokens.close();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      displayChannel,
      null,
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      firebaseChannel,
      null,
    );
  });

  test(
    'concurrent/repeated initialization asks permission and creates channel once',
    () async {
      await Future.wait([service.initialize(), service.initialize()]);
      await service.initialize();
      expect(messaging.permissionRequests, 1);
      expect(messaging.autoInitRequests, 1);
      expect(messaging.presentationRequests, 1);
      expect(displayCalls.single.method, 'createNotificationChannel');
      await emitForeground();
      expect(
        displayCalls.where((call) => call.method == 'showNotification'),
        hasLength(1),
      );
    },
  );

  test('permission denial does not break FCM token acquisition', () async {
    messaging.permission = AuthorizationStatus.denied;
    expect(await service.ensureFcmToken(), 'current-token');
    expect(await service.getStoredFcmToken(), 'current-token');
    expect(messaging.permissionRequests, 1);
  });

  test(
    'channel setup failure does not block permission or token sync',
    () async {
      displayFails = true;
      expect(await service.ensureFcmToken(), 'current-token');
      expect(messaging.permissionRequests, 1);
    },
  );

  test(
    'foreground display failure is caught and token refresh storage survives',
    () async {
      await service.initialize();
      displayFails = true;
      await emitForeground();
      messaging.tokens.add('refreshed-token');
      await Future<void>.delayed(Duration.zero);
      expect(await service.getStoredFcmToken(), 'refreshed-token');
    },
  );

  test(
    'failed initialization retry does not add another foreground listener',
    () async {
      messaging.permissionFailures = 1;
      await expectLater(
        service.initialize(),
        throwsA(isA<PlatformException>()),
      );
      await service.initialize();
      await emitForeground();
      expect(
        displayCalls.where((call) => call.method == 'showNotification'),
        hasLength(1),
      );
    },
  );

  test('dispose removes the foreground listener', () async {
    await service.initialize();
    service.dispose();
    await emitForeground();
    expect(
      displayCalls.where((call) => call.method == 'showNotification'),
      isEmpty,
    );
  });

  test(
    'dispose during channel initialization does not leak a listener',
    () async {
      final channelReady = Completer<void>();
      binding.defaultBinaryMessenger.setMockMethodCallHandler(displayChannel, (
        call,
      ) async {
        displayCalls.add(call);
        if (call.method == 'createNotificationChannel') {
          await channelReady.future;
        }
        return null;
      });
      final initialization = service.initialize();
      await Future<void>.delayed(Duration.zero);
      expect(displayCalls.single.method, 'createNotificationChannel');
      service.dispose();
      channelReady.complete();
      await initialization;
      await emitForeground();
      expect(
        displayCalls.where((call) => call.method == 'showNotification'),
        isEmpty,
      );
    },
  );

  test(
    'non-Android initialization keeps presentation options without Android display',
    () async {
      service.dispose();
      service = NotificationService(messaging, const FlutterSecureStorage());
      await service.initialize();
      await emitForeground();
      expect(displayCalls, isEmpty);
      expect(messaging.presentationRequests, 1);
    },
  );
}
