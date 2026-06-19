// ignore_for_file: constant_identifier_names

import 'package:freezed_annotation/freezed_annotation.dart';

enum AlarmType {
  @JsonValue('COMPLETION')
  COMPLETION,
  @JsonValue('MALFUNCTION')
  MALFUNCTION,
  @JsonValue('WARNING')
  WARNING,
  @JsonValue('INTERRUPTION')
  INTERRUPTION,
  @JsonValue('AUTO_CANCELLED')
  AUTO_CANCELLED,
  @JsonValue('PAUSE_TIMEOUT')
  PAUSE_TIMEOUT,
  @JsonValue('STARTED')
  STARTED,
  @JsonValue('TIMEOUT_WARNING')
  TIMEOUT_WARNING,
  @JsonValue('CANCELLATION_BLOCKED')
  CANCELLATION_BLOCKED,
  @JsonValue('CANCELLATION_BLOCK_EXTENDED')
  CANCELLATION_BLOCK_EXTENDED,
  // 서버가 추가한 알 수 없는 타입에 대한 폴백 값.
  unknown,
}
