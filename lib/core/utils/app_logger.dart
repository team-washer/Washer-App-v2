import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// `dart:developer` 기반 로거. debug는 디버그 모드에서만 출력한다.
class AppLogger {
  const AppLogger._();

  /// 릴리즈 빌드에서도 기기 진단에 필요한 흐름을 남긴다.
  static void info(
    String message, {
    String name = 'App',
  }) {
    developer.log(message, name: name, level: 800);
  }

  static void debug(
    String message, {
    String name = 'App',
  }) {
    if (!kDebugMode) return;

    developer.log(message, name: name);
  }

  static void error(
    String message, {
    String name = 'App',
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }
}
