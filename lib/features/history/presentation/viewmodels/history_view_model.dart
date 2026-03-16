import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/features/history/data/models/machine_history_response.dart';
import 'package:washer/features/history/data/repositories/history_repository.dart';

class HistoryState {
  final bool isLoading;
  final String? errorMessage;
  final List<HistoryContent> historyList;

  const HistoryState({
    this.isLoading = false,
    this.errorMessage,
    this.historyList = const [],
  });

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

class HistoryViewModel extends Notifier<HistoryState> {
  @override
  HistoryState build() => const HistoryState();

  Future<void> fetchTodayHistory(int machineId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day, 0, 0, 0).toIso8601String();
      final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

      final response = await ref.read(historyRepositoryProvider).getMachineHistory(
        machineId: machineId,
        startDate: startDate,
        endDate: endDate,
        page: 0,
        size: 50,
      );

      state = state.copyWith(
        historyList: response.content,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: '사용 기록을 불러오는데 실패했습니다.',
        isLoading: false,
      );
    }
  }
}

final historyViewModelProvider = NotifierProvider<HistoryViewModel, HistoryState>(
  HistoryViewModel.new,
);
