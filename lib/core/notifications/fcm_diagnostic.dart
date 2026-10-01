import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/notifications/apns_native_diagnostics.dart';

enum FcmSyncTrigger { login, appStart, resume, tokenRefresh, manual }

enum FcmDiagnosticEventType {
  permission,
  apnsWaiting,
  apnsSuccess,
  apnsFailed,
  nativeApnsSnapshot,
  fcmStarted,
  fcmSuccess,
  fcmEmpty,
  fcmFailed,
  postStarted,
  postSuccess,
  postFailed,
  message,
}

class FcmDiagnosticEvent {
  const FcmDiagnosticEvent(
    this.type, {
    this.permission,
    this.retryAttempt,
    this.statusCode,
    this.errorCode,
    this.firebaseExceptionCode,
    this.failureStage,
    this.nativeApnsSnapshot,
    this.message,
  });

  final FcmDiagnosticEventType type;
  final String? permission;
  final int? retryAttempt;
  final int? statusCode;
  final String? errorCode;
  final String? firebaseExceptionCode;
  final String? failureStage;
  final ApnsNativeDiagnosticSnapshot? nativeApnsSnapshot;
  final String? message;
}

abstract interface class FcmDiagnosticReporter {
  int beginSync(
    FcmSyncTrigger trigger, {
    required bool registrationEnabled,
    required bool registrationBlocked,
  });

  void updateRegistrationState({
    required bool enabled,
    required bool blocked,
    String? message,
  });

  void record(int cycleId, FcmDiagnosticEvent event);

  void recordSessionUnavailable(FcmSyncTrigger trigger);

  void reportTerminalFailure(int cycleId, {required String message});
}

class FcmDiagnosticState {
  const FcmDiagnosticState({
    this.cycleId = 0,
    this.lastSyncTrigger,
    this.lastSyncTime,
    this.authorizationStatus = 'notDetermined',
    this.registrationEnabled = false,
    this.registrationBlocked = false,
    this.apnsTokenStatus = 'not_started',
    this.apnsRetryCount = 0,
    this.nativeApns = const ApnsNativeDiagnosticSnapshot(
      available: false,
      firebaseAppDelegateProxyEnabled: true,
      registerCallCount: 0,
      isRegisteredForRemoteNotifications: false,
      callbackStatus: 'not_started',
      didRegisterCallbackCount: 0,
      didFailCallbackCount: 0,
      callbackTimeoutCount: 0,
      applicationState: 'unknown',
    ),
    this.fcmTokenStatus = 'not_started',
    this.serverPostStatus = 'not_started',
    this.postSuccessStatusCode,
    this.failureStatusCode,
    this.errorCode,
    this.firebaseExceptionCode,
    this.failureStage,
    this.message = '진단 기록이 없습니다.',
  });

  final int cycleId;
  final FcmSyncTrigger? lastSyncTrigger;
  final DateTime? lastSyncTime;
  final String authorizationStatus;
  final bool registrationEnabled;
  final bool registrationBlocked;
  final String apnsTokenStatus;
  final int apnsRetryCount;
  final ApnsNativeDiagnosticSnapshot nativeApns;
  final String fcmTokenStatus;
  final String serverPostStatus;
  final int? postSuccessStatusCode;
  final int? failureStatusCode;
  final String? errorCode;
  final String? firebaseExceptionCode;
  final String? failureStage;
  final String message;

  static const _unset = Object();

  FcmDiagnosticState copyWith({
    int? cycleId,
    Object? lastSyncTrigger = _unset,
    Object? lastSyncTime = _unset,
    String? authorizationStatus,
    bool? registrationEnabled,
    bool? registrationBlocked,
    String? apnsTokenStatus,
    int? apnsRetryCount,
    ApnsNativeDiagnosticSnapshot? nativeApns,
    String? fcmTokenStatus,
    String? serverPostStatus,
    Object? postSuccessStatusCode = _unset,
    Object? failureStatusCode = _unset,
    Object? errorCode = _unset,
    Object? firebaseExceptionCode = _unset,
    Object? failureStage = _unset,
    String? message,
  }) {
    return FcmDiagnosticState(
      cycleId: cycleId ?? this.cycleId,
      lastSyncTrigger: identical(lastSyncTrigger, _unset)
          ? this.lastSyncTrigger
          : lastSyncTrigger as FcmSyncTrigger?,
      lastSyncTime: identical(lastSyncTime, _unset)
          ? this.lastSyncTime
          : lastSyncTime as DateTime?,
      authorizationStatus: authorizationStatus ?? this.authorizationStatus,
      registrationEnabled: registrationEnabled ?? this.registrationEnabled,
      registrationBlocked: registrationBlocked ?? this.registrationBlocked,
      apnsTokenStatus: apnsTokenStatus ?? this.apnsTokenStatus,
      apnsRetryCount: apnsRetryCount ?? this.apnsRetryCount,
      nativeApns: nativeApns ?? this.nativeApns,
      fcmTokenStatus: fcmTokenStatus ?? this.fcmTokenStatus,
      serverPostStatus: serverPostStatus ?? this.serverPostStatus,
      postSuccessStatusCode: identical(postSuccessStatusCode, _unset)
          ? this.postSuccessStatusCode
          : postSuccessStatusCode as int?,
      failureStatusCode: identical(failureStatusCode, _unset)
          ? this.failureStatusCode
          : failureStatusCode as int?,
      errorCode: identical(errorCode, _unset)
          ? this.errorCode
          : errorCode as String?,
      firebaseExceptionCode: identical(firebaseExceptionCode, _unset)
          ? this.firebaseExceptionCode
          : firebaseExceptionCode as String?,
      failureStage: identical(failureStage, _unset)
          ? this.failureStage
          : failureStage as String?,
      message: message ?? this.message,
    );
  }

  String toDiagnosticText() {
    return <String>[
      'FCM 진단 (#251)',
      'trigger: ${lastSyncTrigger?.name ?? 'none'}',
      'time: ${lastSyncTime?.toIso8601String() ?? 'none'}',
      'permission: $authorizationStatus',
      'registrationEnabled: $registrationEnabled',
      'registrationBlocked: $registrationBlocked',
      'apnsToken: $apnsTokenStatus',
      'apnsRetryCount: $apnsRetryCount',
      'nativeDiagnosticsAvailable: ${nativeApns.available}',
      'firebaseAppDelegateProxyEnabled: ${nativeApns.firebaseAppDelegateProxyEnabled}',
      'registerForRemoteNotificationsCallCount: ${nativeApns.registerCallCount}',
      'lastRegisterForRemoteNotificationsCallAt: ${nativeApns.lastRegisterCallAt ?? 'none'}',
      'isRegisteredForRemoteNotifications: ${nativeApns.isRegisteredForRemoteNotifications}',
      'apnsNativeCallbackStatus: ${nativeApns.callbackStatus}',
      'didRegisterCallbackCount: ${nativeApns.didRegisterCallbackCount}',
      'didFailCallbackCount: ${nativeApns.didFailCallbackCount}',
      'callbackTimeoutCount: ${nativeApns.callbackTimeoutCount}',
      'lastDidRegisterCallbackAt: ${nativeApns.lastDidRegisterCallbackAt ?? 'none'}',
      'lastDidFailCallbackAt: ${nativeApns.lastDidFailCallbackAt ?? 'none'}',
      'lastCallbackTimeoutAt: ${nativeApns.lastCallbackTimeoutAt ?? 'none'}',
      'apnsDeviceTokenLength: ${nativeApns.deviceTokenLength ?? 'none'}',
      'apnsErrorDomain: ${nativeApns.errorDomain ?? 'none'}',
      'apnsErrorCode: ${nativeApns.errorCode ?? 'none'}',
      'apnsErrorDescription: ${nativeApns.errorDescription ?? 'none'}',
      'applicationState: ${nativeApns.applicationState}',
      'fcmToken: $fcmTokenStatus',
      'serverPost: $serverPostStatus',
      'postSuccessStatusCode: ${postSuccessStatusCode ?? 'none'}',
      'failureStatusCode: ${failureStatusCode ?? 'none'}',
      'errorCode: ${errorCode ?? 'none'}',
      'firebaseExceptionCode: ${firebaseExceptionCode ?? 'none'}',
      'failureStage: ${failureStage ?? 'none'}',
      'message: $message',
    ].join('\n');
  }
}

class FcmDiagnosticNotifier extends Notifier<FcmDiagnosticState>
    implements FcmDiagnosticReporter {
  final Set<int> _reportedFailureCycles = <int>{};

  @override
  FcmDiagnosticState build() => const FcmDiagnosticState();

  @override
  int beginSync(
    FcmSyncTrigger trigger, {
    required bool registrationEnabled,
    required bool registrationBlocked,
  }) {
    final cycleId = state.cycleId + 1;
    state = FcmDiagnosticState(
      cycleId: cycleId,
      lastSyncTrigger: trigger,
      lastSyncTime: DateTime.now(),
      authorizationStatus: state.authorizationStatus,
      nativeApns: state.nativeApns,
      registrationEnabled: registrationEnabled,
      registrationBlocked: registrationBlocked,
      message: 'FCM 동기화를 시작했습니다.',
    );
    return cycleId;
  }

  @override
  void updateRegistrationState({
    required bool enabled,
    required bool blocked,
    String? message,
  }) {
    state = state.copyWith(
      registrationEnabled: enabled,
      registrationBlocked: blocked,
      message: message,
    );
  }

  @override
  void record(int cycleId, FcmDiagnosticEvent event) {
    if (state.cycleId != cycleId) return;

    switch (event.type) {
      case FcmDiagnosticEventType.permission:
        state = state.copyWith(
          authorizationStatus: event.permission,
          message: event.message,
        );
      case FcmDiagnosticEventType.apnsWaiting:
        state = state.copyWith(
          apnsTokenStatus: 'waiting',
          apnsRetryCount: event.retryAttempt,
          failureStage: null,
          firebaseExceptionCode: null,
          message: event.message,
        );
      case FcmDiagnosticEventType.apnsSuccess:
        state = state.copyWith(
          apnsTokenStatus: 'success',
          apnsRetryCount: event.retryAttempt,
          failureStage: null,
          firebaseExceptionCode: null,
          message: event.message,
        );
      case FcmDiagnosticEventType.apnsFailed:
        state = state.copyWith(
          apnsTokenStatus: 'failed',
          apnsRetryCount: event.retryAttempt,
          failureStage: event.failureStage ?? 'apns_token',
          firebaseExceptionCode: event.firebaseExceptionCode,
          message: event.message,
        );
      case FcmDiagnosticEventType.nativeApnsSnapshot:
        state = state.copyWith(
          nativeApns: event.nativeApnsSnapshot,
          message: event.message,
        );
      case FcmDiagnosticEventType.fcmStarted:
        state = state.copyWith(
          fcmTokenStatus: 'not_started',
          failureStage: null,
          firebaseExceptionCode: null,
          message: event.message,
        );
      case FcmDiagnosticEventType.fcmSuccess:
        state = state.copyWith(
          fcmTokenStatus: 'success',
          failureStage: null,
          firebaseExceptionCode: null,
          message: event.message,
        );
      case FcmDiagnosticEventType.fcmEmpty:
        state = state.copyWith(
          fcmTokenStatus: 'empty',
          failureStage: event.failureStage ?? 'fcm_token',
          message: event.message,
        );
      case FcmDiagnosticEventType.fcmFailed:
        state = state.copyWith(
          fcmTokenStatus: 'failed',
          failureStage: event.failureStage ?? 'fcm_token',
          firebaseExceptionCode: event.firebaseExceptionCode,
          message: event.message,
        );
      case FcmDiagnosticEventType.postStarted:
        state = state.copyWith(
          serverPostStatus: 'started',
          postSuccessStatusCode: null,
          failureStatusCode: null,
          errorCode: null,
          failureStage: null,
          message: event.message,
        );
      case FcmDiagnosticEventType.postSuccess:
        state = state.copyWith(
          serverPostStatus: 'success',
          postSuccessStatusCode: event.statusCode,
          failureStatusCode: null,
          errorCode: null,
          failureStage: null,
          message: event.message,
        );
      case FcmDiagnosticEventType.postFailed:
        state = state.copyWith(
          serverPostStatus: 'failed',
          failureStatusCode: event.statusCode,
          errorCode: event.errorCode,
          failureStage: event.failureStage ?? 'server_post',
          message: event.message,
        );
      case FcmDiagnosticEventType.message:
        state = event.failureStage == null
            ? state.copyWith(message: event.message)
            : state.copyWith(
                failureStage: event.failureStage,
                message: event.message,
              );
    }
  }

  @override
  void recordSessionUnavailable(FcmSyncTrigger trigger) {
    final cycleId = beginSync(
      trigger,
      registrationEnabled: state.registrationEnabled,
      registrationBlocked: state.registrationBlocked,
    );
    if (state.cycleId != cycleId) return;
    state = state.copyWith(
      failureStage: 'active_session',
      message: '활성 로그인 세션이 없어 동기화를 실행하지 않았습니다.',
    );
  }

  @override
  void reportTerminalFailure(int cycleId, {required String message}) {
    if (state.cycleId != cycleId) return;
    state = state.copyWith(message: message);
    if (!_reportedFailureCycles.add(cycleId) || kDebugMode) return;
    unawaited(_recordCrashlyticsFailure(state));
  }

  Future<void> _recordCrashlyticsFailure(FcmDiagnosticState snapshot) async {
    try {
      final crashlytics = FirebaseCrashlytics.instance;
      await Future.wait<void>([
        crashlytics.setCustomKey(
          'fcm_sync_trigger',
          snapshot.lastSyncTrigger?.name ?? 'none',
        ),
        crashlytics.setCustomKey(
          'fcm_stage',
          snapshot.failureStage ?? 'unknown',
        ),
        crashlytics.setCustomKey(
          'fcm_permission',
          snapshot.authorizationStatus,
        ),
        crashlytics.setCustomKey(
          'fcm_apns_ready',
          snapshot.apnsTokenStatus == 'success',
        ),
        crashlytics.setCustomKey(
          'fcm_apns_register_calls',
          snapshot.nativeApns.registerCallCount,
        ),
        crashlytics.setCustomKey(
          'fcm_apns_system_registered',
          snapshot.nativeApns.isRegisteredForRemoteNotifications,
        ),
        crashlytics.setCustomKey(
          'fcm_apns_callback',
          snapshot.nativeApns.callbackStatus,
        ),
        crashlytics.setCustomKey(
          'fcm_apns_error_domain',
          snapshot.nativeApns.errorDomain ?? 'none',
        ),
        crashlytics.setCustomKey(
          'fcm_apns_error_code',
          snapshot.nativeApns.errorCode ?? -1,
        ),
        crashlytics.setCustomKey(
          'fcm_token_ready',
          snapshot.fcmTokenStatus == 'success',
        ),
        crashlytics.setCustomKey(
          'fcm_post_started',
          snapshot.serverPostStatus != 'not_started',
        ),
        crashlytics.setCustomKey(
          'fcm_post_status',
          snapshot.failureStatusCode ?? snapshot.postSuccessStatusCode ?? -1,
        ),
        crashlytics.setCustomKey(
          'fcm_error_code',
          snapshot.errorCode ?? snapshot.firebaseExceptionCode ?? 'none',
        ),
      ]);
      crashlytics.log(
        'FCM sync failed at ${snapshot.failureStage ?? 'unknown'} '
        '(trigger=${snapshot.lastSyncTrigger?.name ?? 'none'})',
      );
      await crashlytics.recordError(
        FcmDiagnosticFailure(snapshot.failureStage ?? 'unknown'),
        StackTrace.current,
        reason: 'FCM diagnostic cycle failed',
        fatal: false,
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to record FCM diagnostics: $error\n$stackTrace');
    }
  }
}

class FcmDiagnosticFailure implements Exception {
  const FcmDiagnosticFailure(this.stage);

  final String stage;

  @override
  String toString() => 'FCM diagnostic failure at $stage';
}

final fcmDiagnosticProvider =
    NotifierProvider<FcmDiagnosticNotifier, FcmDiagnosticState>(
      FcmDiagnosticNotifier.new,
    );
