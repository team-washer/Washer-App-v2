import 'package:washer/features/history/data/models/machine_history_response.dart';

class HistoryState {
  const HistoryState({
    this.isLoading = false,
    this.errorMessage,
    this.historyList = const [],
  });

  final bool isLoading;
  final String? errorMessage;
  final List<HistoryContent> historyList;

  HistoryState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<HistoryContent>? historyList,
  }) {
    return HistoryState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      historyList: historyList ?? this.historyList,
    );
  }
}
