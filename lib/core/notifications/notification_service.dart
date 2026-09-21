import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/firebase_options.dart';

/// FCM 토큰을 secure storage에 저장할 때 쓰는 키.
const fcmTokenStorageKey = 'fcm_token';
const _apnsTokenRetryDelay = Duration(seconds: 1);
const _apnsTokenMaxRetries = 10;

/// 백그라운드/종료 상태에서 FCM 메시지를 받을 때 호출되는 핸들러.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

/// FCM 권한 요청과 토큰 저장/갱신을 담당하는 서비스.
class NotificationService {
  NotificationService(this._messaging, this._storage);

  final FirebaseMessaging _messaging;
  final FlutterSecureStorage _storage;

  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _isInitialized = false;

  /// 권한 요청, 토큰 저장, 토큰 갱신 구독을 한 번만 수행한다.
  Future<void> initialize() async {
    if (_isInitialized) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestPermissions();
    await _saveFcmTokenWhenReady();

    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((token) {
      unawaited(_storage.write(key: fcmTokenStorageKey, value: token));
      AppLogger.debug(
        'FCM token refreshed: $token',
        name: 'NotificationService',
      );
    });

    _isInitialized = true;
  }

  Future<String?> getStoredFcmToken() {
    return _storage.read(key: fcmTokenStorageKey);
  }

  /// 저장된 토큰이 없으면 발급을 시도한 뒤 토큰을 반환한다.
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
    AppLogger.debug('FCM token: $token', name: 'NotificationService');
  }

  Future<void> _saveFcmTokenWhenReady() async {
    if (Platform.isIOS) {
      final apnsTokenReady = await _waitForApnsToken();
      if (!apnsTokenReady) {
        AppLogger.debug(
          'APNS token is not ready yet. Skipping initial FCM token save.',
          name: 'NotificationService',
        );
        return;
      }
    }

    try {
      await _saveFcmToken();
    } on FirebaseException catch (e) {
      if (_isApnsTokenNotSetError(e)) {
        AppLogger.debug(
          'FCM token skipped until APNS token is available.',
          name: 'NotificationService',
        );
        return;
      }
      AppLogger.error(
        'FCM 토큰 저장 중 Firebase 오류가 발생했습니다.',
        name: 'NotificationService',
        error: e,
        stackTrace: e.stackTrace,
      );
      rethrow;
    }
  }

  /// iOS에서 FCM 토큰 발급 전 필요한 APNS 토큰을 재시도하며 기다린다.
  Future<bool> _waitForApnsToken() async {
    for (var attempt = 0; attempt < _apnsTokenMaxRetries; attempt++) {
      try {
        final token = await _messaging.getAPNSToken();
        if (token != null && token.isNotEmpty) {
          AppLogger.debug(
            'APNS token received.',
            name: 'NotificationService',
          );
          return true;
        }
      } on FirebaseException catch (e) {
        if (!_isApnsTokenNotSetError(e)) {
          AppLogger.error(
            'APNS 토큰 확인 중 Firebase 오류가 발생했습니다.',
            name: 'NotificationService',
            error: e,
            stackTrace: e.stackTrace,
          );
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

/// [NotificationService] provider.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService(
    FirebaseMessaging.instance,
    ref.watch(secureStorageProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// 알림 초기화 1회 실행용 provider.
final notificationInitializationProvider = FutureProvider<void>((ref) async {
  await ref.watch(notificationServiceProvider).initialize();
});
