import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// `dart:developer` 기반 로거. debug는 디버그 모드에서만 출력한다.
class AppLogger {
  const AppLogger._();

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
