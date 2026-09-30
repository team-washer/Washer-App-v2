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
  Future<void>? _initializationFuture;
  bool _isInitialized = false;

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// 권한 요청, 토큰 저장, 토큰 갱신 구독을 한 번만 수행한다.
  Future<void> initialize() {
    if (_isInitialized) return Future<void>.value();
    return _initializationFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen(
        (token) async {
          try {
            await _storage.write(key: fcmTokenStorageKey, value: token);
            AppLogger.info(
              'FCM token refreshed and stored. token=[REDACTED], length=${token.length}',
              name: 'NotificationService',
            );
          } catch (error, stackTrace) {
            AppLogger.error(
              'Failed to store refreshed FCM token.',
              name: 'NotificationService',
              error: error,
              stackTrace: stackTrace,
            );
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          AppLogger.error(
            'FCM token refresh stream failed.',
            name: 'NotificationService',
            error: error,
            stackTrace: stackTrace,
          );
        },
      );

      await _requestPermissions();

      _isInitialized = true;
    } catch (_) {
      _initializationFuture = null;
      rethrow;
    }
  }

  Future<String?> getStoredFcmToken() {
    return _storage.read(key: fcmTokenStorageKey);
  }

  /// Firebase의 현재 토큰을 확인해 저장한 뒤 반환한다.
  ///
  /// iOS Keychain에는 앱 재설치 뒤에도 값이 남을 수 있으므로 저장된 값만으로
  /// 현재 앱 인스턴스의 토큰을 판단하지 않는다.
  Future<String?> ensureFcmToken() async {
    await initialize();
    final storedToken = await getStoredFcmToken();
    final currentToken = await _fetchAndStoreFcmTokenWhenReady();
    if (currentToken != null) {
      AppLogger.info(
        storedToken == currentToken
            ? 'Firebase confirmed the stored FCM token is current.'
            : 'Stored FCM token was replaced with the current Firebase token.',
        name: 'NotificationService',
      );
    }
    return currentToken;
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

  Future<String?> _fetchAndStoreFcmToken() async {
    AppLogger.info(
      'FCM token acquisition started.',
      name: 'NotificationService',
    );
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      AppLogger.error(
        'FCM token acquisition failed: Firebase returned an empty token.',
        name: 'NotificationService',
      );
      return null;
    }

    await _storage.write(key: fcmTokenStorageKey, value: token);
    AppLogger.info(
      'FCM token acquired and stored. token=[REDACTED], length=${token.length}',
      name: 'NotificationService',
    );
    return token;
  }

  Future<String?> _fetchAndStoreFcmTokenWhenReady() async {
    if (Platform.isIOS) {
      final apnsTokenReady = await _waitForApnsToken();
      if (!apnsTokenReady) {
        AppLogger.error(
          'APNs token acquisition failed after $_apnsTokenMaxRetries attempts.',
          name: 'NotificationService',
        );
        return null;
      }
    }

    try {
      return await _fetchAndStoreFcmToken();
    } on FirebaseException catch (e) {
      if (_isApnsTokenNotSetError(e)) {
        AppLogger.error(
          'FCM token acquisition failed because the APNs token is not ready.',
          name: 'NotificationService',
        );
        return null;
      }
      AppLogger.error(
        'FCM token acquisition failed with a Firebase error. code=${e.code}',
        name: 'NotificationService',
        stackTrace: e.stackTrace,
      );
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error(
        'FCM token acquisition failed.',
        name: 'NotificationService',
        error: error,
        stackTrace: stackTrace,
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
          AppLogger.info(
            'APNs token acquired. token=[REDACTED], length=${token.length}, attempt=${attempt + 1}',
            name: 'NotificationService',
          );
          return true;
        }
      } on FirebaseException catch (e) {
        if (!_isApnsTokenNotSetError(e)) {
          AppLogger.error(
            'APNs token acquisition failed with a Firebase error. code=${e.code}',
            name: 'NotificationService',
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
