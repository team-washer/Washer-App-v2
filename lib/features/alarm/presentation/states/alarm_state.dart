import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:washer/features/alarm/data/models/local/alarm_model.dart';

part 'alarm_state.freezed.dart';

/// 알람 목록 조회 진행 상태
enum AlarmStatus { initial, loading, success, error }

/// 알림 화면의 상태 (조회 상태, 알람 목록, 오류 메시지)
@freezed
abstract class AlarmState with _$AlarmState {
  const factory AlarmState({
    @Default(AlarmStatus.initial) AlarmStatus status,
    @Default([]) List<AlarmModel> alarms,
    String? errorMessage,
  }) = _AlarmState;
}
