import 'package:washer/features/alarm/domain/entities/alarm_model.dart';

enum AlarmUiStatus { initial, loading, success, error }

class AlarmUiState {
  const AlarmUiState({
    this.status = AlarmUiStatus.initial,
    this.alarms = const [],
    this.errorMessage,
  });

  final AlarmUiStatus status;
  final List<AlarmModel> alarms;
  final String? errorMessage;

  AlarmUiState copyWith({
    AlarmUiStatus? status,
    List<AlarmModel>? alarms,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AlarmUiState(
      status: status ?? this.status,
      alarms: alarms ?? this.alarms,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }
}
