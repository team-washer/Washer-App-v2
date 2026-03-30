import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/firebase_options.dart';

const fcmTokenStorageKey = 'fcm_token';
const _apnsTokenRetryDelay = Duration(seconds: 1);
const _apnsTokenMaxRetries = 10;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

class NotificationService {
  NotificationService(this._messaging, this._storage);

  final FirebaseMessaging _messaging;
  final FlutterSecureStorage _storage;

  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestPermissions();
    await _saveFcmTokenWhenReady();

    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((token) {
      unawaited(_storage.write(key: fcmTokenStorageKey, value: token));
      if (kDebugMode) {
        debugPrint('FCM token refreshed: $token');
      }
    });

    _isInitialized = true;
  }

  Future<String?> getStoredFcmToken() {
    return _storage.read(key: fcmTokenStorageKey);
  }

  Future<String?> ensureFcmToken() async {
    await initialize();

    final storedToken = await getStoredFcmToken();
    if (storedToken != null && storedToken.isNotEmpty) {
      return storedToken;
    }

    await _saveFcmTokenWhenReady();
    return getStoredFcmToken();
  }

  Future<void> deleteStoredFcmToken() {
    return _storage.delete(key: fcmTokenStorageKey);
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _saveFcmToken() async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    await _storage.write(key: fcmTokenStorageKey, value: token);
    if (kDebugMode) {
      debugPrint('FCM token: $token');
    }
  }

  Future<void> _saveFcmTokenWhenReady() async {
    if (Platform.isIOS) {
      final apnsTokenReady = await _waitForApnsToken();
      if (!apnsTokenReady) {
        if (kDebugMode) {
          debugPrint(
            'APNS token is not ready yet. Skipping initial FCM token save.',
          );
        }
        return;
      }
    }

    try {
      await _saveFcmToken();
    } on FirebaseException catch (e) {
      if (_isApnsTokenNotSetError(e)) {
        if (kDebugMode) {
          debugPrint('FCM token skipped until APNS token is available.');
        }
        return;
      }
      rethrow;
    }
  }

  Future<bool> _waitForApnsToken() async {
    for (var attempt = 0; attempt < _apnsTokenMaxRetries; attempt++) {
      try {
        final token = await _messaging.getAPNSToken();
        if (token != null && token.isNotEmpty) {
          if (kDebugMode) {
            debugPrint('APNS token received.');
          }
          return true;
        }
      } on FirebaseException catch (e) {
        if (!_isApnsTokenNotSetError(e)) {
          rethrow;
        }
      }

      await Future<void>.delayed(_apnsTokenRetryDelay);
    }

    return false;
  }

  bool _isApnsTokenNotSetError(FirebaseException error) {
    return error.plugin == 'firebase_messaging' &&
        error.code == 'apns-token-not-set';
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService(
    FirebaseMessaging.instance,
    ref.watch(secureStorageProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final notificationInitializationProvider = FutureProvider<void>((ref) async {
  await ref.watch(notificationServiceProvider).initialize();
});
