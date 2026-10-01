import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/core/notifications/apns_native_diagnostics.dart';
import 'package:washer/core/notifications/fcm_diagnostic.dart';
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
  NotificationService(
    this._messaging,
    this._storage, [
    this._diagnostics,
    ApnsNativeDiagnostics? apnsNativeDiagnostics,
  ]) : _apnsNativeDiagnostics =
           apnsNativeDiagnostics ?? const ApnsNativeDiagnostics();

  final FirebaseMessaging _messaging;
  final FlutterSecureStorage _storage;
  final FcmDiagnosticReporter? _diagnostics;
  final ApnsNativeDiagnostics _apnsNativeDiagnostics;

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

      // FCM is required after login. Explicitly restore auto-init in case a
      // previous runtime setting persisted it as disabled.
      await _messaging.setAutoInitEnabled(true);
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
  Future<String?> ensureFcmToken({int? diagnosticCycleId}) async {
    await initialize();
    final settings = await _messaging.getNotificationSettings();
    _record(
      diagnosticCycleId,
      FcmDiagnosticEvent(
        FcmDiagnosticEventType.permission,
        permission: _authorizationStatusName(settings.authorizationStatus),
        message: '알림 권한 상태를 확인했습니다.',
      ),
    );
    if (Platform.isIOS) {
      await _requestNativeApnsRegistration(diagnosticCycleId);
    }
    final storedToken = await getStoredFcmToken();
    final currentToken = await _fetchAndStoreFcmTokenWhenReady(
      diagnosticCycleId,
    );
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

  Future<NotificationSettings> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings;
  }

  Future<String?> _fetchAndStoreFcmToken(int? diagnosticCycleId) async {
    AppLogger.info(
      'FCM token acquisition started.',
      name: 'NotificationService',
    );
    _record(
      diagnosticCycleId,
      const FcmDiagnosticEvent(
        FcmDiagnosticEventType.fcmStarted,
        message: 'FCM 토큰 발급을 시작했습니다.',
      ),
    );
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      AppLogger.error(
        'FCM token acquisition failed: Firebase returned an empty token.',
        name: 'NotificationService',
      );
      _record(
        diagnosticCycleId,
        const FcmDiagnosticEvent(
          FcmDiagnosticEventType.fcmEmpty,
          failureStage: 'fcm_token',
          message: 'Firebase가 빈 FCM 토큰을 반환했습니다.',
        ),
      );
      return null;
    }

    await _storage.write(key: fcmTokenStorageKey, value: token);
    AppLogger.info(
      'FCM token acquired and stored. token=[REDACTED], length=${token.length}',
      name: 'NotificationService',
    );
    _record(
      diagnosticCycleId,
      const FcmDiagnosticEvent(
        FcmDiagnosticEventType.fcmSuccess,
        message: 'FCM 토큰을 확보했습니다.',
      ),
    );
    return token;
  }

  Future<String?> _fetchAndStoreFcmTokenWhenReady(
    int? diagnosticCycleId,
  ) async {
    if (Platform.isIOS) {
      final apnsTokenReady = await _waitForApnsToken(diagnosticCycleId);
      if (!apnsTokenReady) {
        AppLogger.error(
          'APNs token acquisition failed after $_apnsTokenMaxRetries attempts.',
          name: 'NotificationService',
        );
        return null;
      }
    }

    try {
      return await _fetchAndStoreFcmToken(diagnosticCycleId);
    } on FirebaseException catch (e) {
      if (_isApnsTokenNotSetError(e)) {
        AppLogger.error(
          'FCM token acquisition failed because the APNs token is not ready.',
          name: 'NotificationService',
        );
        _record(
          diagnosticCycleId,
          FcmDiagnosticEvent(
            FcmDiagnosticEventType.fcmFailed,
            firebaseExceptionCode: e.code,
            failureStage: 'fcm_token',
            message: 'APNs 토큰이 준비되지 않아 FCM 토큰 발급에 실패했습니다.',
          ),
        );
        return null;
      }
      AppLogger.error(
        'FCM token acquisition failed with a Firebase error. code=${e.code}',
        name: 'NotificationService',
        stackTrace: e.stackTrace,
      );
      _record(
        diagnosticCycleId,
        FcmDiagnosticEvent(
          FcmDiagnosticEventType.fcmFailed,
          firebaseExceptionCode: e.code,
          failureStage: 'fcm_token',
          message: 'Firebase 오류로 FCM 토큰 발급에 실패했습니다.',
        ),
      );
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error(
        'FCM token acquisition failed.',
        name: 'NotificationService',
        error: error,
        stackTrace: stackTrace,
      );
      _record(
        diagnosticCycleId,
        const FcmDiagnosticEvent(
          FcmDiagnosticEventType.fcmFailed,
          failureStage: 'fcm_token',
          message: 'FCM 토큰 발급 중 알 수 없는 오류가 발생했습니다.',
        ),
      );
      rethrow;
    }
  }

  /// iOS에서 FCM 토큰 발급 전 필요한 APNS 토큰을 재시도하며 기다린다.
  Future<bool> _waitForApnsToken(int? diagnosticCycleId) async {
    String? lastFirebaseErrorCode;
    for (var attempt = 0; attempt < _apnsTokenMaxRetries; attempt++) {
      final retryAttempt = attempt + 1;
      await _refreshNativeApnsDiagnostics(diagnosticCycleId);
      _record(
        diagnosticCycleId,
        FcmDiagnosticEvent(
          FcmDiagnosticEventType.apnsWaiting,
          retryAttempt: retryAttempt,
          message: 'APNs 토큰을 기다리는 중입니다.',
        ),
      );
      try {
        final token = await _messaging.getAPNSToken();
        if (token != null && token.isNotEmpty) {
          await _refreshNativeApnsDiagnostics(diagnosticCycleId);
          AppLogger.info(
            'APNs token acquired. token=[REDACTED], length=${token.length}, attempt=$retryAttempt',
            name: 'NotificationService',
          );
          _record(
            diagnosticCycleId,
            FcmDiagnosticEvent(
              FcmDiagnosticEventType.apnsSuccess,
              retryAttempt: retryAttempt,
              message: 'APNs 토큰을 확보했습니다.',
            ),
          );
          return true;
        }
      } on FirebaseException catch (e) {
        lastFirebaseErrorCode = e.code;
        if (!_isApnsTokenNotSetError(e)) {
          AppLogger.error(
            'APNs token acquisition failed with a Firebase error. code=${e.code}',
            name: 'NotificationService',
            stackTrace: e.stackTrace,
          );
          _record(
            diagnosticCycleId,
            FcmDiagnosticEvent(
              FcmDiagnosticEventType.apnsFailed,
              retryAttempt: retryAttempt,
              firebaseExceptionCode: e.code,
              failureStage: 'apns_token',
              message: 'Firebase 오류로 APNs 토큰 확인에 실패했습니다.',
            ),
          );
          rethrow;
        }
      }

      if (retryAttempt < _apnsTokenMaxRetries) {
        await Future<void>.delayed(_apnsTokenRetryDelay);
      }
    }

    await _refreshNativeApnsDiagnostics(diagnosticCycleId);
    _record(
      diagnosticCycleId,
      FcmDiagnosticEvent(
        FcmDiagnosticEventType.apnsFailed,
        retryAttempt: _apnsTokenMaxRetries,
        firebaseExceptionCode: lastFirebaseErrorCode,
        failureStage: 'apns_token',
        message: 'APNs 토큰 대기 횟수를 모두 소진했습니다.',
      ),
    );
    return false;
  }

  Future<void> _requestNativeApnsRegistration(int? diagnosticCycleId) async {
    try {
      final snapshot = await _apnsNativeDiagnostics
          .registerForRemoteNotifications();
      _recordNativeApnsSnapshot(diagnosticCycleId, snapshot);
      AppLogger.info(
        'Native APNs registration requested. calls=${snapshot.registerCallCount}, registered=${snapshot.isRegisteredForRemoteNotifications}, callback=${snapshot.callbackStatus}',
        name: 'NotificationService',
      );
    } on MissingPluginException catch (error) {
      _recordNativeApnsDiagnosticsUnavailable(
        diagnosticCycleId,
        'APNs 네이티브 진단 채널이 연결되지 않았습니다.',
      );
      AppLogger.error(
        'Native APNs diagnostic channel is unavailable.',
        name: 'NotificationService',
        error: error,
      );
    } on PlatformException catch (error, stackTrace) {
      _recordNativeApnsDiagnosticsUnavailable(
        diagnosticCycleId,
        'APNs 네이티브 등록 호출을 실행하지 못했습니다.',
      );
      AppLogger.error(
        'Native APNs registration request failed. code=${error.code}',
        name: 'NotificationService',
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      _recordNativeApnsDiagnosticsUnavailable(
        diagnosticCycleId,
        'APNs 네이티브 등록 진단 중 오류가 발생했습니다.',
      );
      AppLogger.error(
        'Unexpected native APNs diagnostic error.',
        name: 'NotificationService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _refreshNativeApnsDiagnostics(int? diagnosticCycleId) async {
    try {
      final snapshot = await _apnsNativeDiagnostics.getSnapshot();
      _recordNativeApnsSnapshot(diagnosticCycleId, snapshot);
    } on MissingPluginException {
      _recordNativeApnsDiagnosticsUnavailable(
        diagnosticCycleId,
        'APNs 네이티브 진단 채널이 연결되지 않았습니다.',
      );
    } on PlatformException catch (error, stackTrace) {
      _recordNativeApnsDiagnosticsUnavailable(
        diagnosticCycleId,
        'APNs 네이티브 진단 상태를 읽지 못했습니다.',
      );
      AppLogger.error(
        'Failed to read native APNs diagnostics. code=${error.code}',
        name: 'NotificationService',
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      _recordNativeApnsDiagnosticsUnavailable(
        diagnosticCycleId,
        'APNs 네이티브 진단 상태를 읽지 못했습니다.',
      );
      AppLogger.error(
        'Unexpected error while reading native APNs diagnostics.',
        name: 'NotificationService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _recordNativeApnsSnapshot(
    int? diagnosticCycleId,
    ApnsNativeDiagnosticSnapshot snapshot,
  ) {
    _record(
      diagnosticCycleId,
      FcmDiagnosticEvent(
        FcmDiagnosticEventType.nativeApnsSnapshot,
        nativeApnsSnapshot: snapshot,
      ),
    );
  }

  void _recordNativeApnsDiagnosticsUnavailable(
    int? diagnosticCycleId,
    String message,
  ) {
    _record(
      diagnosticCycleId,
      FcmDiagnosticEvent(
        FcmDiagnosticEventType.nativeApnsSnapshot,
        nativeApnsSnapshot: ApnsNativeDiagnosticSnapshot.unavailable(),
        message: message,
      ),
    );
  }

  String _authorizationStatusName(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
        return 'authorized';
      case AuthorizationStatus.denied:
        return 'denied';
      case AuthorizationStatus.notDetermined:
        return 'notDetermined';
      case AuthorizationStatus.provisional:
        return 'provisional';
    }
  }

  void _record(int? cycleId, FcmDiagnosticEvent event) {
    if (cycleId == null) return;
    _diagnostics?.record(cycleId, event);
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
    ref.watch(fcmDiagnosticProvider.notifier),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// 알림 초기화 1회 실행용 provider.
final notificationInitializationProvider = FutureProvider<void>((ref) async {
  await ref.watch(notificationServiceProvider).initialize();
});
