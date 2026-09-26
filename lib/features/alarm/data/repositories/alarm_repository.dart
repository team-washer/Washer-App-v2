import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/notifications/notification_service.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/alarm/data/data_sources/alarm_data_source.dart';
import 'package:washer/features/alarm/data/models/local/alarm_model.dart';

/// 알림 목록 조회/삭제와 FCM 토큰 등록/삭제를 담당하는 저장소.
///
/// 삭제·토큰 관련 실패는 로그만 남기고 예외를 밖으로 던지지 않는다.
class AlarmRepository {
  AlarmRepository(this._dataSource, this._notificationService);

  static const _maxRegistrationRetries = 2;
  static const _registrationRetryDelay = Duration(seconds: 1);

  final AlarmDataSource _dataSource;
  final NotificationService _notificationService;

  bool _isFcmRegistrationEnabled = false;
  bool _isFcmRegistrationBlocked = false;
  String? _currentFcmToken;
  String? _lastRegisteredFcmToken;
  Future<void>? _registrationInFlight;
  Timer? _registrationRetryTimer;
  String? _retryToken;
  int _registrationRetryCount = 0;

  void enableFcmRegistration() {
    _isFcmRegistrationBlocked = false;
    _isFcmRegistrationEnabled = true;
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
  Future<void> registerCurrentFcmToken() async {
    if (!_isFcmRegistrationEnabled) return;

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
      return;
    }

    if (fcmToken == null || fcmToken.isEmpty) {
      return;
    }

    await registerFcmToken(fcmToken);
  }

  Future<void> registerFcmToken(String fcmToken) async {
    if (!_isFcmRegistrationEnabled || fcmToken.isEmpty) return;
    if (_currentFcmToken != fcmToken) {
      _clearRegistrationRetry();
      _currentFcmToken = fcmToken;
    }

    await _registerCurrentFcmToken(fcmToken);
  }

  Future<void> _registerCurrentFcmToken(String fcmToken) async {
    if (!_isFcmRegistrationEnabled || _currentFcmToken != fcmToken) return;
    if (_lastRegisteredFcmToken == fcmToken) return;

    final inFlight = _registrationInFlight;
    if (inFlight != null) {
      await inFlight;
      if (!_isFcmRegistrationEnabled ||
          _currentFcmToken != fcmToken ||
          _lastRegisteredFcmToken == fcmToken) {
        return;
      }
    }

    final request = _registerFcmToken(fcmToken);
    _registrationInFlight = request;

    try {
      await request;
    } finally {
      if (identical(_registrationInFlight, request)) {
        _registrationInFlight = null;
      }
    }
  }

  Future<void> _registerFcmToken(String fcmToken) async {
    try {
      await _dataSource.registerFcmToken(fcmToken);
      if (_isFcmRegistrationEnabled && _currentFcmToken == fcmToken) {
        _lastRegisteredFcmToken = fcmToken;
        _clearRegistrationRetry();
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to register FCM token.',
        name: 'AlarmRepository',
        error: error,
        stackTrace: stackTrace,
      );
      _scheduleRegistrationRetry(fcmToken, error);
    }
  }

  void _scheduleRegistrationRetry(String fcmToken, Object error) {
    if (!_isFcmRegistrationEnabled ||
        _currentFcmToken != fcmToken ||
        !_isRetryableRegistrationError(error)) {
      return;
    }

    if (_retryToken != fcmToken) {
      _clearRegistrationRetry();
      _retryToken = fcmToken;
    }
    if (_registrationRetryCount >= _maxRegistrationRetries) return;

    _registrationRetryCount++;
    _registrationRetryTimer?.cancel();
    _registrationRetryTimer = Timer(
      _registrationRetryDelay * _registrationRetryCount,
      () {
        _registrationRetryTimer = null;
        unawaited(_registerCurrentFcmToken(fcmToken));
      },
    );
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
  }

  /// 서버에서 FCM 토큰을 삭제하고, 로컬에 저장된 토큰도 함께 지운다.
  Future<void> deleteFcmToken() async {
    disableFcmRegistration(blockUntilLogin: true);

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
