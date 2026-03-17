import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

Future<T> runInBackground<T>(FutureOr<T> Function() task) {
  if (kIsWeb) {
    return Future<T>.value(task());
  }

  return Isolate.run<T>(task);
}