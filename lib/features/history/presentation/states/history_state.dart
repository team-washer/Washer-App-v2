import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:washer/core/network/error.dart';
import 'package:washer/features/history/data/models/machine_history_response.dart';

part 'history_state.freezed.dart';

@freezed
abstract class HistoryState with _$HistoryState {
  const factory HistoryState({
    @Default(false) bool isLoading,
    // 마지막 조회가 실패했을 때의 오류. 다시 조회를 시작하면 null로 비운다.
    AppException? error,
    @Default([]) List<HistoryContent> historyList,
  }) = _HistoryState;
}
