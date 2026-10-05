import 'package:flutter/services.dart';

class ApnsRegistration {
  const ApnsRegistration({
    MethodChannel channel = const MethodChannel('washer/apns-registration'),
  }) : _channel = channel;

  final MethodChannel _channel;

  Future<void> registerForRemoteNotifications() {
    return _channel.invokeMethod<void>('registerForRemoteNotifications');
  }
}
