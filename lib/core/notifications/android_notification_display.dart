import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';

/// Android foreground messages need an explicit notification; background
/// notification payloads are displayed by the Firebase SDK instead.
class AndroidNotificationDisplay {
  const AndroidNotificationDisplay({
    MethodChannel channel = const MethodChannel('washer/android-notifications'),
  }) : _channel = channel;

  final MethodChannel _channel;

  Future<void> initialize() {
    return _channel.invokeMethod<void>('createNotificationChannel');
  }

  Future<bool> show(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null ||
        ((notification.title?.trim().isEmpty ?? true) &&
            (notification.body?.trim().isEmpty ?? true))) {
      return false;
    }

    return await _channel.invokeMethod<bool>('showNotification', {
          'messageId': message.messageId,
          'title': notification.title,
          'body': notification.body,
        }) ??
        false;
  }
}
