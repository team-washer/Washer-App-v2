import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/errors/app_exception.dart';
import 'package:washer/core/notifications/fcm_diagnostic.dart';
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
    FcmDiagnosticReporter? diagnostics,
  }) : _tokenPreparationRetryDelay = tokenPreparationRetryDelay,
       _registrationRetryDelay = registrationRetryDelay,
       _maxTokenPreparationRetries = maxTokenPreparationRetries,
       _maxRegistrationRetries = maxRegistrationRetries,
       _diagnostics = diagnostics;

  final AlarmDataSource _dataSource;
  final NotificationService _notificationService;
  final Duration _tokenPreparationRetryDelay;
  final Duration _registrationRetryDelay;
  final int _maxTokenPreparationRetries;
  final int _maxRegistrationRetries;
  final FcmDiagnosticReporter? _diagnostics;

  bool _isFcmRegistrationEnabled = false;
  bool _isFcmRegistrationBlocked = false;
  String? _currentFcmToken;
  String? _lastRegisteredFcmToken;
  Future<void>? _tokenPreparationInFlight;
  Timer? _tokenPreparationRetryTimer;
  int _tokenPreparationRetryCount = 0;
  int? _tokenPreparationRetryCycleId;
  FcmSyncTrigger? _tokenPreparationRetryTrigger;
  Future<void>? _registrationInFlight;
  String? _registrationInFlightToken;
  Timer? _registrationRetryTimer;
  String? _retryToken;
  int _registrationRetryCount = 0;
  int? _registrationRetryCycleId;
  bool _registrationRetryForceServerSync = false;
  int? _lastRegistrationStatusCode;

  void enableFcmRegistration() {
    _isFcmRegistrationBlocked = false;
    _isFcmRegistrationEnabled = true;
    _currentFcmToken = null;
    _lastRegisteredFcmToken = null;
    _lastRegistrationStatusCode = null;
    _clearTokenPreparationRetry();
    _clearRegistrationRetry();
    _updateDiagnosticRegistrationState('새 로그인 FCM 등록 세션을 시작했습니다.');
  }

  void enableFcmRegistrationForExistingSession() {
    if (_isFcmRegistrationBlocked) return;
    _isFcmRegistrationEnabled = true;
    _updateDiagnosticRegistrationState('기존 로그인 세션의 FCM 등록을 활성화했습니다.');
  }

  void disableFcmRegistration({bool blockUntilLogin = false}) {
    if (blockUntilLogin) {
      _isFcmRegistrationBlocked = true;
    }
    _isFcmRegistrationEnabled = false;
    _currentFcmToken = null;
    _lastRegisteredFcmToken = null;
    _lastRegistrationStatusCode = null;
    _clearTokenPreparationRetry();
    _clearRegistrationRetry();
    _updateDiagnosticRegistrationState('FCM 등록을 중지하고 로컬 등록 상태를 초기화했습니다.');
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
    final cycleId = _diagnostics?.beginSync(
      trigger,
      registrationEnabled: _isFcmRegistrationEnabled,
      registrationBlocked: _isFcmRegistrationBlocked,
    );
    AppLogger.info(
      'registerCurrentFcmToken called. trigger=${trigger.name}, enabled=$_isFcmRegistrationEnabled',
      name: 'AlarmRepository',
    );
    if (!_isFcmRegistrationEnabled) {
      AppLogger.info(
        'registerCurrentFcmToken skipped because registration is disabled.',
        name: 'AlarmRepository',
      );
      _recordDiagnostic(
        cycleId,
        const FcmDiagnosticEvent(
          FcmDiagnosticEventType.message,
          message: 'FCM 등록이 비활성화되어 동기화를 건너뛰었습니다.',
        ),
      );
      return;
    }

    // login/app_start/resume/manual 호출은 각각 새로운 bounded retry cycle이다.
    _clearTokenPreparationRetry();
    await _startCurrentFcmTokenRegistration(
      cycleId: cycleId,
      trigger: trigger,
      forceServerSync: true,
    );
  }

  Future<void> _startCurrentFcmTokenRegistration({
    required int? cycleId,
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
        _recordDiagnostic(
          cycleId,
          FcmDiagnosticEvent(
            FcmDiagnosticEventType.postSuccess,
            statusCode: _lastRegistrationStatusCode,
            message: '동시에 실행된 FCM 서버 등록 요청이 성공했습니다.',
          ),
        );
        return;
      }
      _clearTokenPreparationRetry();
    }

    final request = _prepareAndRegisterCurrentFcmToken(
      cycleId: cycleId,
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
    required int? cycleId,
    required FcmSyncTrigger trigger,
    required bool forceServerSync,
  }) async {
    String? fcmToken;
    try {
      fcmToken = await _notificationService.ensureFcmToken(
        diagnosticCycleId: cycleId,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to prepare FCM token.',
        name: 'AlarmRepository',
        error: error,
        stackTrace: stackTrace,
      );
      final retryScheduled = _scheduleTokenPreparationRetry(
        cycleId: cycleId,
        trigger: trigger,
        forceServerSync: forceServerSync,
      );
      if (!retryScheduled) {
        _reportTerminalFailure(
          cycleId,
          'FCM 토큰 준비 오류 후 재시도 횟수를 모두 소진했습니다.',
        );
      }
      return;
    }

    if (!_isFcmRegistrationEnabled) return;
    if (fcmToken == null || fcmToken.isEmpty) {
      final retryScheduled = _scheduleTokenPreparationRetry(
        cycleId: cycleId,
        trigger: trigger,
        forceServerSync: forceServerSync,
      );
      if (!retryScheduled) {
        _reportTerminalFailure(
          cycleId,
          'APNs/FCM 토큰 준비 재시도 횟수를 모두 소진했습니다.',
        );
      }
      return;
    }

    _clearTokenPreparationRetry();
    await registerFcmToken(
      fcmToken,
      trigger: trigger,
      forceServerSync: forceServerSync,
      diagnosticCycleId: cycleId,
    );
  }

  Future<void> registerFcmToken(
    String fcmToken, {
    FcmSyncTrigger trigger = FcmSyncTrigger.tokenRefresh,
    bool forceServerSync = false,
    int? diagnosticCycleId,
  }) async {
    final cycleId =
        diagnosticCycleId ??
        _diagnostics?.beginSync(
          trigger,
          registrationEnabled: _isFcmRegistrationEnabled,
          registrationBlocked: _isFcmRegistrationBlocked,
        );
    AppLogger.info(
      'registerFcmToken called. trigger=${trigger.name}, enabled=$_isFcmRegistrationEnabled, token=[REDACTED], length=${fcmToken.length}',
      name: 'AlarmRepository',
    );
    if (!_isFcmRegistrationEnabled || fcmToken.isEmpty) {
      _recordDiagnostic(
        cycleId,
        const FcmDiagnosticEvent(
          FcmDiagnosticEventType.message,
          message: 'FCM 등록이 비활성화되었거나 토큰이 비어 있습니다.',
        ),
      );
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
      cycleId: cycleId,
      forceServerSync: forceServerSync,
    );
  }

  bool _scheduleTokenPreparationRetry({
    required int? cycleId,
    required FcmSyncTrigger trigger,
    required bool forceServerSync,
  }) {
    if (!_isFcmRegistrationEnabled ||
        _tokenPreparationRetryTimer != null ||
        _tokenPreparationRetryCount >= _maxTokenPreparationRetries) {
      return false;
    }

    _tokenPreparationRetryCount++;
    _tokenPreparationRetryCycleId = cycleId;
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
            cycleId: _tokenPreparationRetryCycleId,
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
    _tokenPreparationRetryCycleId = null;
    _tokenPreparationRetryTrigger = null;
  }

  Future<void> _registerCurrentFcmToken(
    String fcmToken, {
    required int? cycleId,
    required bool forceServerSync,
  }) async {
    if (!_isFcmRegistrationEnabled || _currentFcmToken != fcmToken) return;
    if (!forceServerSync && _lastRegisteredFcmToken == fcmToken) {
      _recordDiagnostic(
        cycleId,
        FcmDiagnosticEvent(
          FcmDiagnosticEventType.postSuccess,
          statusCode: _lastRegistrationStatusCode,
          message: '같은 token refresh가 이미 서버에 반영되어 중복 등록을 생략했습니다.',
        ),
      );
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
          _recordDiagnostic(
            cycleId,
            FcmDiagnosticEvent(
              FcmDiagnosticEventType.postSuccess,
              statusCode: _lastRegistrationStatusCode,
              message: '동시에 실행된 동일 토큰 등록 요청이 성공했습니다.',
            ),
          );
          return;
        }
        if (!forceServerSync) return;

        // A failed token-refresh request may have scheduled its own retry.
        // An explicit sync owns a fresh retry cycle, so retry immediately
        // under the current diagnostic cycle instead of inheriting it.
        _clearRegistrationRetry();
      }
      if (!forceServerSync && _lastRegisteredFcmToken == fcmToken) return;
    }

    final request = _registerFcmToken(
      fcmToken,
      cycleId: cycleId,
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
    required int? cycleId,
    required bool forceServerSync,
  }) async {
    _recordDiagnostic(
      cycleId,
      const FcmDiagnosticEvent(
        FcmDiagnosticEventType.postStarted,
        message: 'FCM 토큰 서버 등록 요청을 시작했습니다.',
      ),
    );
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
      _lastRegistrationStatusCode = statusCode;
      _clearRegistrationRetry();
      AppLogger.info(
        'FCM token registration completed. token=[REDACTED], length=${fcmToken.length}',
        name: 'AlarmRepository',
      );
      _recordDiagnostic(
        cycleId,
        FcmDiagnosticEvent(
          FcmDiagnosticEventType.postSuccess,
          statusCode: statusCode,
          message: 'FCM 토큰 서버 등록에 성공했습니다.',
        ),
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
      _recordDiagnostic(
        cycleId,
        FcmDiagnosticEvent(
          FcmDiagnosticEventType.postFailed,
          statusCode: exception.statusCode,
          errorCode: exception.errorCode,
          failureStage: 'server_post',
          message: 'FCM 토큰 서버 등록 요청에 실패했습니다.',
        ),
      );
      final retryScheduled = _scheduleRegistrationRetry(
        fcmToken,
        error,
        cycleId: cycleId,
        forceServerSync: forceServerSync,
      );
      AppLogger.error(
        'Failed to register FCM token. statusCode=${exception.statusCode}, errorCode=${exception.errorCode}, retry=$retryScheduled',
        name: 'AlarmRepository',
        stackTrace: stackTrace,
      );
      if (!retryScheduled) {
        _reportTerminalFailure(
          cycleId,
          'FCM 토큰 서버 등록에 실패했고 추가 재시도를 예약하지 못했습니다.',
        );
      }
    }
  }

  bool _scheduleRegistrationRetry(
    String fcmToken,
    Object error, {
    required int? cycleId,
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
    _registrationRetryCycleId = cycleId;
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
            cycleId: _registrationRetryCycleId,
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
    _registrationRetryCycleId = null;
    _registrationRetryForceServerSync = false;
  }

  void _updateDiagnosticRegistrationState(String message) {
    _diagnostics?.updateRegistrationState(
      enabled: _isFcmRegistrationEnabled,
      blocked: _isFcmRegistrationBlocked,
      message: message,
    );
  }

  void _recordDiagnostic(int? cycleId, FcmDiagnosticEvent event) {
    if (cycleId == null) return;
    _diagnostics?.record(cycleId, event);
  }

  void _reportTerminalFailure(int? cycleId, String message) {
    if (cycleId == null) return;
    _diagnostics?.reportTerminalFailure(cycleId, message: message);
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
    diagnostics: ref.watch(fcmDiagnosticProvider.notifier),
  );
  ref.onDispose(repository.dispose);
  return repository;
});
