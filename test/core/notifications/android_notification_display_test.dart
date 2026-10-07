import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/notifications/android_notification_display.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('washer/android-notifications');
  const display = AndroidNotificationDisplay();
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return call.method == 'showNotification' ? true : null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('requests native channel creation', () async {
    await display.initialize();
    expect(calls.single.method, 'createNotificationChannel');
  });

  test(
    'passes notification payload and stable message ID to Android',
    () async {
      final shown = await display.show(
        const RemoteMessage(
          messageId: 'message-1',
          notification: RemoteNotification(
            title: 'Laundry complete',
            body: 'Done',
          ),
          data: {'private': 'not forwarded'},
        ),
      );
      expect(shown, isTrue);
      expect(calls.single.method, 'showNotification');
      expect(calls.single.arguments, {
        'messageId': 'message-1',
        'title': 'Laundry complete',
        'body': 'Done',
      });
    },
  );

  test('does not turn data-only messages into notifications', () async {
    expect(
      await display.show(const RemoteMessage(data: {'type': 'done'})),
      isFalse,
    );
    expect(calls, isEmpty);
  });

  test('ignores empty notification payloads', () async {
    expect(
      await display.show(
        const RemoteMessage(
          notification: RemoteNotification(title: ' ', body: ''),
        ),
      ),
      isFalse,
    );
    expect(calls, isEmpty);
  });

  test('accepts body-only notifications', () async {
    expect(
      await display.show(
        const RemoteMessage(
          notification: RemoteNotification(body: 'Done'),
        ),
      ),
      isTrue,
    );
    expect((calls.single.arguments as Map)['body'], 'Done');
  });

  test('respects a native permission/channel denial', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => false);
    expect(
      await display.show(
        const RemoteMessage(
          notification: RemoteNotification(title: 'Done'),
        ),
      ),
      isFalse,
    );
  });
}
