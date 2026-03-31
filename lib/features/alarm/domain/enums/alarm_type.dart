// ignore_for_file: constant_identifier_names

import 'package:freezed_annotation/freezed_annotation.dart';

enum AlarmType {
  @JsonValue('washComplete')
  COMPLETION,
  @JsonValue('washerError')
  MALFUNCTION,
  @JsonValue('usageWarning')
  WARNING,
  @JsonValue('interruption')
  INTERRUPTION,
  @JsonValue('autoCancelled')
  AUTO_CANCELLED,
  @JsonValue('pauseTimeout')
  PAUSE_TIMEOUT,
  @JsonValue('started')
  STARTED,
}
