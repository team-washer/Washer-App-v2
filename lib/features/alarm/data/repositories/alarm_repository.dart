import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/errors/app_exception.dart';
import 'package:washer/core/notifications/fcm_sync_trigger.dart';
import 'package:washer/core/notifications/notification_service.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/alarm/data/data_sources/alarm_data_source.dart';
import 'package:washer/features/alarm/data/models/local/alarm_model.dart';

/// 알림 목록 조회/삭제와 FCM 토큰 등록/삭제를 담당하는 저장소.
///
/// 삭제·토큰 관련 실패는 로그만 남기고 예외를 밖으로 던지지 않는다.
class AlarmRepository {
  AlarmRepository(
    this._dataSource,
    this._notificationService, {
    Duration tokenPreparationRetryDelay = const Duration(seconds: 2),
    Duration registrationRetryDelay = const Duration(seconds: 1),
    int maxTokenPreparationRetries = 3,
    int maxRegistrationRetries = 2,
  }) : _tokenPreparationRetryDelay = tokenPreparationRetryDelay,
       _registrationRetryDelay = registrationRetryDelay,
       _maxTokenPreparationRetries = maxTokenPreparationRetries,
       _maxRegistrationRetries = maxRegistrationRetries;

  final AlarmDataSource _dataSource;
  final NotificationService _notificationService;
  final Duration _tokenPreparationRetryDelay;
  final Duration _registrationRetryDelay;
  final int _maxTokenPreparationRetries;
  final int _maxRegistrationRetries;

  bool _isFcmRegistrationEnabled = false;
  bool _isFcmRegistrationBlocked = false;
  String? _currentFcmToken;
  String? _lastRegisteredFcmToken;
  Future<void>? _tokenPreparationInFlight;
  Timer? _tokenPreparationRetryTimer;
  int _tokenPreparationRetryCount = 0;
  FcmSyncTrigger? _tokenPreparationRetryTrigger;
  Future<void>? _registrationInFlight;
  String? _registrationInFlightToken;
  Timer? _registrationRetryTimer;
  String? _retryToken;
  int _registrationRetryCount = 0;
  bool _registrationRetryForceServerSync = false;

  void enableFcmRegistration() {
    _isFcmRegistrationBlocked = false;
    _isFcmRegistrationEnabled = true;
    _currentFcmToken = null;
    _lastRegisteredFcmToken = null;
    _clearTokenPreparationRetry();
    _clearRegistrationRetry();
  }

  void enableFcmRegistrationForExistingSession() {
    if (_isFcmRegistrationBlocked) return;
    _isFcmRegistrationEnabled = true;
  }

  void disableFcmRegistration({bool blockUntilLogin = false}) {
    if (blockUntilLogin) {
      _isFcmRegistrationBlocked = true;
    }
    _isFcmRegistrationEnabled = false;
    _currentFcmToken = null;
    _lastRegisteredFcmToken = null;
    _clearTokenPreparationRetry();
    _clearRegistrationRetry();
  }

  /// 서버 알림 응답을 화면용 [AlarmModel] 목록으로 변환해 반환한다.
  Future<List<AlarmModel>> fetchAlarms() async {
    final response = await _dataSource.getAlarmList();
    return response.data
        .map(
          (notification) => AlarmModel(
            id: notification.id,
            status: notification.type,
            time: notification.createdAt,
            description: notification.message,
          ),
        )
        .toList();
  }

  /// 서버의 모든 알림을 삭제한다.
  Future<void> deleteAllNotifications() async {
    try {
      await _dataSource.deleteAllNotifications();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to delete all notifications.',
        name: 'AlarmRepository',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// 현재 기기의 FCM 토큰을 확보해 서버에 등록한다.
  Future<void> registerCurrentFcmToken({
    FcmSyncTrigger trigger = FcmSyncTrigger.manual,
  }) async {
    AppLogger.info(
      'registerCurrentFcmToken called. trigger=${trigger.name}, enabled=$_isFcmRegistrationEnabled',
      name: 'AlarmRepository',
    );
    if (!_isFcmRegistrationEnabled) {
      AppLogger.info(
        'registerCurrentFcmToken skipped because registration is disabled.',
        name: 'AlarmRepository',
      );
      return;
    }

    // login/app_start/resume/manual 호출은 각각 새로운 bounded retry cycle이다.
    _clearTokenPreparationRetry();
    await _startCurrentFcmTokenRegistration(
      trigger: trigger,
      forceServerSync: true,
    );
  }

  Future<void> _startCurrentFcmTokenRegistration({
    required FcmSyncTrigger trigger,
    required bool forceServerSync,
  }) async {
    final inFlight = _tokenPreparationInFlight;
    if (inFlight != null) {
      await inFlight;
      if (!_isFcmRegistrationEnabled) return;

      // A simultaneous explicit sync is satisfied by the POST already in
      // flight. If that attempt failed before registration, start a new one.
      final currentToken = _currentFcmToken;
      if (currentToken != null && _lastRegisteredFcmToken == currentToken) {
        return;
      }
      _clearTokenPreparationRetry();
    }

    final request = _prepareAndRegisterCurrentFcmToken(
      trigger: trigger,
      forceServerSync: forceServerSync,
    );
    _tokenPreparationInFlight = request;

    try {
      await request;
    } finally {
      if (identical(_tokenPreparationInFlight, request)) {
        _tokenPreparationInFlight = null;
      }
    }
  }

  Future<void> _prepareAndRegisterCurrentFcmToken({
    required FcmSyncTrigger trigger,
    required bool forceServerSync,
  }) async {
    String? fcmToken;
    try {
      fcmToken = await _notificationService.ensureFcmToken();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to prepare FCM token.',
        name: 'AlarmRepository',
        error: error,
        stackTrace: stackTrace,
      );
      _scheduleTokenPreparationRetry(
        trigger: trigger,
        forceServerSync: forceServerSync,
      );
      return;
    }

    if (!_isFcmRegistrationEnabled) return;
    if (fcmToken == null || fcmToken.isEmpty) {
      _scheduleTokenPreparationRetry(
        trigger: trigger,
        forceServerSync: forceServerSync,
      );
      return;
    }

    _clearTokenPreparationRetry();
    await registerFcmToken(
      fcmToken,
      trigger: trigger,
      forceServerSync: forceServerSync,
    );
  }

  Future<void> registerFcmToken(
    String fcmToken, {
    FcmSyncTrigger trigger = FcmSyncTrigger.tokenRefresh,
    bool forceServerSync = false,
  }) async {
    AppLogger.info(
      'registerFcmToken called. trigger=${trigger.name}, enabled=$_isFcmRegistrationEnabled, token=[REDACTED], length=${fcmToken.length}',
      name: 'AlarmRepository',
    );
    if (!_isFcmRegistrationEnabled || fcmToken.isEmpty) {
      return;
    }
    _clearTokenPreparationRetry();
    if (_currentFcmToken != fcmToken) {
      _clearRegistrationRetry();
      _currentFcmToken = fcmToken;
    } else if (forceServerSync) {
      _clearRegistrationRetry();
    } else if (_registrationRetryTimer == null &&
        _registrationRetryCount >= _maxRegistrationRetries) {
      _clearRegistrationRetry();
      AppLogger.info(
        'FCM server registration retry budget restarted by an external sync.',
        name: 'AlarmRepository',
      );
    }

    await _registerCurrentFcmToken(
      fcmToken,
      forceServerSync: forceServerSync,
    );
  }

  bool _scheduleTokenPreparationRetry({
    required FcmSyncTrigger trigger,
    required bool forceServerSync,
  }) {
    if (!_isFcmRegistrationEnabled ||
        _tokenPreparationRetryTimer != null ||
        _tokenPreparationRetryCount >= _maxTokenPreparationRetries) {
      return false;
    }

    _tokenPreparationRetryCount++;
    _tokenPreparationRetryTrigger = trigger;
    AppLogger.info(
      'FCM token preparation retry scheduled. attempt=$_tokenPreparationRetryCount/$_maxTokenPreparationRetries',
      name: 'AlarmRepository',
    );
    _tokenPreparationRetryTimer = Timer(
      _tokenPreparationRetryDelay * _tokenPreparationRetryCount,
      () {
        _tokenPreparationRetryTimer = null;
        unawaited(
          _startCurrentFcmTokenRegistration(
            trigger: _tokenPreparationRetryTrigger ?? trigger,
            forceServerSync: forceServerSync,
          ),
        );
      },
    );
    return true;
  }

  void _clearTokenPreparationRetry() {
    _tokenPreparationRetryTimer?.cancel();
    _tokenPreparationRetryTimer = null;
    _tokenPreparationRetryCount = 0;
    _tokenPreparationRetryTrigger = null;
  }

  Future<void> _registerCurrentFcmToken(
    String fcmToken, {
    required bool forceServerSync,
  }) async {
    if (!_isFcmRegistrationEnabled || _currentFcmToken != fcmToken) return;
    if (!forceServerSync && _lastRegisteredFcmToken == fcmToken) {
      return;
    }

    final inFlight = _registrationInFlight;
    if (inFlight != null) {
      final inFlightToken = _registrationInFlightToken;
      await inFlight;
      if (!_isFcmRegistrationEnabled || _currentFcmToken != fcmToken) {
        return;
      }
      if (inFlightToken == fcmToken) {
        if (_lastRegisteredFcmToken == fcmToken) {
          return;
        }
        if (!forceServerSync) return;

        // A failed token-refresh request may have scheduled its own retry.
        // An explicit sync owns a fresh retry cycle, so retry immediately
        // instead of inheriting its exhausted retry budget.
        _clearRegistrationRetry();
      }
      if (!forceServerSync && _lastRegisteredFcmToken == fcmToken) return;
    }

    final request = _registerFcmToken(
      fcmToken,
      forceServerSync: forceServerSync,
    );
    _registrationInFlight = request;
    _registrationInFlightToken = fcmToken;

    try {
      await request;
    } finally {
      if (identical(_registrationInFlight, request)) {
        _registrationInFlight = null;
        _registrationInFlightToken = null;
      }
    }
  }

  Future<void> _registerFcmToken(
    String fcmToken, {
    required bool forceServerSync,
  }) async {
    try {
      final statusCode = await _dataSource.registerFcmToken(fcmToken);
      if (!_isFcmRegistrationEnabled || _currentFcmToken != fcmToken) {
        AppLogger.info(
          'FCM token registration completed after the registration session ended; the result was ignored.',
          name: 'AlarmRepository',
        );
        return;
      }

      _lastRegisteredFcmToken = fcmToken;
      _clearRegistrationRetry();
      AppLogger.info(
        'FCM token registration completed. statusCode=$statusCode, token=[REDACTED], length=${fcmToken.length}',
        name: 'AlarmRepository',
      );
    } catch (error, stackTrace) {
      if (!_isFcmRegistrationEnabled || _currentFcmToken != fcmToken) {
        AppLogger.info(
          'FCM token registration failed after the registration session ended; retry was skipped.',
          name: 'AlarmRepository',
        );
        return;
      }

      final exception = AppException.from(error);
      final retryScheduled = _scheduleRegistrationRetry(
        fcmToken,
        error,
        forceServerSync: forceServerSync,
      );
      AppLogger.error(
        'Failed to register FCM token. statusCode=${exception.statusCode}, errorCode=${exception.errorCode}, retry=$retryScheduled',
        name: 'AlarmRepository',
        stackTrace: stackTrace,
      );
    }
  }

  bool _scheduleRegistrationRetry(
    String fcmToken,
    Object error, {
    required bool forceServerSync,
  }) {
    if (!_isFcmRegistrationEnabled ||
        _currentFcmToken != fcmToken ||
        !_isRetryableRegistrationError(error)) {
      return false;
    }

    if (_retryToken != fcmToken) {
      _clearRegistrationRetry();
      _retryToken = fcmToken;
    }
    if (_registrationRetryCount >= _maxRegistrationRetries) return false;

    _registrationRetryCount++;
    _registrationRetryForceServerSync = forceServerSync;
    AppLogger.info(
      'FCM server registration retry scheduled. attempt=$_registrationRetryCount/$_maxRegistrationRetries',
      name: 'AlarmRepository',
    );
    _registrationRetryTimer?.cancel();
    _registrationRetryTimer = Timer(
      _registrationRetryDelay * _registrationRetryCount,
      () {
        _registrationRetryTimer = null;
        unawaited(
          _registerCurrentFcmToken(
            fcmToken,
            forceServerSync: _registrationRetryForceServerSync,
          ),
        );
      },
    );
    return true;
  }

  bool _isRetryableRegistrationError(Object error) {
    if (error is! DioException) return false;

    final statusCode = error.response?.statusCode;
    return statusCode == 408 ||
        statusCode == 429 ||
        (statusCode != null && statusCode >= 500) ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout;
  }

  void _clearRegistrationRetry() {
    _registrationRetryTimer?.cancel();
    _registrationRetryTimer = null;
    _retryToken = null;
    _registrationRetryCount = 0;
    _registrationRetryForceServerSync = false;
  }

  /// 서버에서 FCM 토큰을 삭제하고, 로컬에 저장된 토큰도 함께 지운다.
  Future<void> deleteFcmToken() async {
    disableFcmRegistration(blockUntilLogin: true);

    final tokenPreparation = _tokenPreparationInFlight;
    if (tokenPreparation != null) {
      await tokenPreparation;
    }

    final inFlight = _registrationInFlight;
    if (inFlight != null) {
      await inFlight;
    }

    try {
      await _dataSource.deleteFcmToken();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to delete FCM token.',
        name: 'AlarmRepository',
        error: error,
        stackTrace: stackTrace,
      );
    }

    await _notificationService.deleteStoredFcmToken();
  }

  void dispose() {
    disableFcmRegistration(blockUntilLogin: true);
  }
}

final alarmRepositoryProvider = Provider<AlarmRepository>((ref) {
  final repository = AlarmRepository(
    ref.watch(alarmDataSourceProvider),
    ref.watch(notificationServiceProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
});
