import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:washer/features/history/data/models/machine_history_response.dart';

part 'history_state.freezed.dart';

@freezed
abstract class HistoryState with _$HistoryState {
  const factory HistoryState({
    @Default(false) bool isLoading,
    String? errorMessage,
    @Default([]) List<HistoryContent> historyList,
  }) = _HistoryState;
}
