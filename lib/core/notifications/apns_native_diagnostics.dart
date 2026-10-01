import 'package:flutter/services.dart';

class ApnsNativeDiagnosticSnapshot {
  const ApnsNativeDiagnosticSnapshot({
    required this.available,
    required this.firebaseAppDelegateProxyEnabled,
    required this.registerCallCount,
    required this.isRegisteredForRemoteNotifications,
    required this.callbackStatus,
    required this.didRegisterCallbackCount,
    required this.didFailCallbackCount,
    required this.callbackTimeoutCount,
    required this.applicationState,
    this.lastRegisterCallAt,
    this.lastDidRegisterCallbackAt,
    this.lastDidFailCallbackAt,
    this.lastCallbackTimeoutAt,
    this.deviceTokenLength,
    this.errorDomain,
    this.errorCode,
    this.errorDescription,
  });

  factory ApnsNativeDiagnosticSnapshot.fromMap(
    Map<Object?, Object?>? map,
  ) {
    return ApnsNativeDiagnosticSnapshot(
      available: map?['available'] == true,
      firebaseAppDelegateProxyEnabled:
          map?['firebaseAppDelegateProxyEnabled'] == true,
      registerCallCount: _readInt(
        map,
        'registerForRemoteNotificationsCallCount',
      ),
      lastRegisterCallAt: _readString(
        map,
        'lastRegisterForRemoteNotificationsCallAt',
      ),
      isRegisteredForRemoteNotifications:
          map?['isRegisteredForRemoteNotifications'] == true,
      callbackStatus: _readString(map, 'callbackStatus') ?? 'unavailable',
      didRegisterCallbackCount: _readInt(map, 'didRegisterCallbackCount'),
      didFailCallbackCount: _readInt(map, 'didFailCallbackCount'),
      callbackTimeoutCount: _readInt(map, 'callbackTimeoutCount'),
      lastDidRegisterCallbackAt: _readString(
        map,
        'lastDidRegisterCallbackAt',
      ),
      lastDidFailCallbackAt: _readString(map, 'lastDidFailCallbackAt'),
      lastCallbackTimeoutAt: _readString(map, 'lastCallbackTimeoutAt'),
      deviceTokenLength: _readNullableInt(map, 'deviceTokenLength'),
      errorDomain: _readString(map, 'errorDomain'),
      errorCode: _readNullableInt(map, 'errorCode'),
      errorDescription: _readString(map, 'errorDescription'),
      applicationState: _readString(map, 'applicationState') ?? 'unknown',
    );
  }

  factory ApnsNativeDiagnosticSnapshot.unavailable() {
    return const ApnsNativeDiagnosticSnapshot(
      available: false,
      firebaseAppDelegateProxyEnabled: true,
      registerCallCount: 0,
      isRegisteredForRemoteNotifications: false,
      callbackStatus: 'unavailable',
      didRegisterCallbackCount: 0,
      didFailCallbackCount: 0,
      callbackTimeoutCount: 0,
      applicationState: 'unknown',
    );
  }

  final bool available;
  final bool firebaseAppDelegateProxyEnabled;
  final int registerCallCount;
  final String? lastRegisterCallAt;
  final bool isRegisteredForRemoteNotifications;
  final String callbackStatus;
  final int didRegisterCallbackCount;
  final int didFailCallbackCount;
  final int callbackTimeoutCount;
  final String? lastDidRegisterCallbackAt;
  final String? lastDidFailCallbackAt;
  final String? lastCallbackTimeoutAt;
  final int? deviceTokenLength;
  final String? errorDomain;
  final int? errorCode;
  final String? errorDescription;
  final String applicationState;

  static int _readInt(Map<Object?, Object?>? map, String key) {
    return _readNullableInt(map, key) ?? 0;
  }

  static int? _readNullableInt(Map<Object?, Object?>? map, String key) {
    final value = map?[key];
    return value is num ? value.toInt() : null;
  }

  static String? _readString(Map<Object?, Object?>? map, String key) {
    final value = map?[key];
    return value is String && value.isNotEmpty ? value : null;
  }
}

class ApnsNativeDiagnostics {
  const ApnsNativeDiagnostics({
    MethodChannel channel = const MethodChannel('washer/apns-diagnostics'),
  }) : _channel = channel;

  final MethodChannel _channel;

  Future<ApnsNativeDiagnosticSnapshot> registerForRemoteNotifications() {
    return _invoke('registerForRemoteNotifications');
  }

  Future<ApnsNativeDiagnosticSnapshot> getSnapshot() {
    return _invoke('getSnapshot');
  }

  Future<ApnsNativeDiagnosticSnapshot> _invoke(String method) async {
    final result = await _channel.invokeMapMethod<Object?, Object?>(method);
    return ApnsNativeDiagnosticSnapshot.fromMap(result);
  }
}
