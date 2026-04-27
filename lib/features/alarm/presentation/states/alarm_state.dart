import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:washer/core/states/presentation_state.dart';
import 'package:washer/features/alarm/data/models/local/alarm_model.dart';

part 'alarm_state.freezed.dart';

enum AlarmStatus { initial, loading, success, error }

@freezed
abstract class AlarmState with _$AlarmState implements PresentationState {
  const factory AlarmState({
    @Default(AlarmStatus.initial) AlarmStatus status,
    @Default([]) List<AlarmModel> alarms,
    String? errorMessage,
  }) = _AlarmState;
}
