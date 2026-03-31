import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:washer/features/alarm/domain/entities/alarm_model.dart';

part 'alarm_state.freezed.dart';

enum AlarmStatus { initial, loading, success, error }

@freezed
abstract class AlarmState with _$AlarmState {
  const factory AlarmState({
    @Default(AlarmStatus.initial) AlarmStatus status,
    @Default([]) List<AlarmModel> alarms,
    String? errorMessage,
  }) = _AlarmState;
}
