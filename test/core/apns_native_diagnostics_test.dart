import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/notifications/apns_native_diagnostics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('washer/test-apns-diagnostics');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test(
    'register request parses native APNs diagnostics without token bytes',
    () async {
      String? invokedMethod;
      messenger.setMockMethodCallHandler(channel, (call) async {
        invokedMethod = call.method;
        return <String, Object?>{
          'available': true,
          'firebaseAppDelegateProxyEnabled': true,
          'registerForRemoteNotificationsCallCount': 1,
          'lastRegisterForRemoteNotificationsCallAt':
              '2026-10-01T12:00:00.000Z',
          'isRegisteredForRemoteNotifications': true,
          'callbackStatus': 'success',
          'didRegisterCallbackCount': 1,
          'didFailCallbackCount': 0,
          'callbackTimeoutCount': 0,
          'lastDidRegisterCallbackAt': '2026-10-01T12:00:01.000Z',
          'deviceTokenLength': 32,
          'applicationState': 'active',
        };
      });

      final diagnostics = ApnsNativeDiagnostics(channel: channel);
      final snapshot = await diagnostics.registerForRemoteNotifications();

      expect(invokedMethod, 'registerForRemoteNotifications');
      expect(snapshot.available, isTrue);
      expect(snapshot.firebaseAppDelegateProxyEnabled, isTrue);
      expect(snapshot.registerCallCount, 1);
      expect(snapshot.isRegisteredForRemoteNotifications, isTrue);
      expect(snapshot.callbackStatus, 'success');
      expect(snapshot.deviceTokenLength, 32);
    },
  );

  test('failure snapshot preserves NSError diagnostics', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      return <String, Object?>{
        'available': true,
        'firebaseAppDelegateProxyEnabled': true,
        'registerForRemoteNotificationsCallCount': 2,
        'isRegisteredForRemoteNotifications': false,
        'callbackStatus': 'failure',
        'didRegisterCallbackCount': 0,
        'didFailCallbackCount': 1,
        'callbackTimeoutCount': 0,
        'errorDomain': 'NSCocoaErrorDomain',
        'errorCode': 3000,
        'errorDescription': 'No valid aps-environment entitlement string found',
        'applicationState': 'active',
      };
    });

    final diagnostics = ApnsNativeDiagnostics(channel: channel);
    final snapshot = await diagnostics.getSnapshot();

    expect(snapshot.callbackStatus, 'failure');
    expect(snapshot.didFailCallbackCount, 1);
    expect(snapshot.errorDomain, 'NSCocoaErrorDomain');
    expect(snapshot.errorCode, 3000);
    expect(
      snapshot.errorDescription,
      'No valid aps-environment entitlement string found',
    );
  });

  test('timeout snapshot distinguishes a missing native callback', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      return <String, Object?>{
        'available': true,
        'firebaseAppDelegateProxyEnabled': true,
        'registerForRemoteNotificationsCallCount': 1,
        'isRegisteredForRemoteNotifications': false,
        'callbackStatus': 'timeout',
        'didRegisterCallbackCount': 0,
        'didFailCallbackCount': 0,
        'callbackTimeoutCount': 1,
        'lastCallbackTimeoutAt': '2026-10-01T12:00:15.000Z',
        'applicationState': 'active',
      };
    });

    final diagnostics = ApnsNativeDiagnostics(channel: channel);
    final snapshot = await diagnostics.getSnapshot();

    expect(snapshot.callbackStatus, 'timeout');
    expect(snapshot.callbackTimeoutCount, 1);
    expect(snapshot.didRegisterCallbackCount, 0);
    expect(snapshot.didFailCallbackCount, 0);
    expect(snapshot.lastCallbackTimeoutAt, '2026-10-01T12:00:15.000Z');
  });
}
