import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/notifications/apns_registration.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('washer/test-apns-registration');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('requests native remote notification registration', () async {
    String? invokedMethod;
    messenger.setMockMethodCallHandler(channel, (call) async {
      invokedMethod = call.method;
      return null;
    });

    final registration = ApnsRegistration(channel: channel);
    await registration.registerForRemoteNotifications();

    expect(invokedMethod, 'registerForRemoteNotifications');
  });
}
