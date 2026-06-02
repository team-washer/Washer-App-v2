import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/history/data/data_sources/history_remote_data_source.dart';
import 'package:washer/features/history/presentation/states/history_state.dart';

class HistoryNotifier extends Notifier<HistoryState> {
  @override
  HistoryState build() => const HistoryState();

  Future<void> fetchTodayHistory(int machineId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final now = DateTime.now();
      final startDate = DateTime(
        now.year,
        now.month,
        now.day,
        0,
        0,
        0,
      ).toIso8601String();
      final endDate = DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
      ).toIso8601String();

      final response = await ref
          .read(historyRemoteDataSourceProvider)
          .getMachineHistory(
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
    } catch (error, stackTrace) {
      AppLogger.error(
        '사용 기록을 불러오는 중 오류가 발생했습니다.',
        name: 'HistoryNotifier',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        errorMessage: '사용 기록을 불러오는데 실패했습니다.',
        isLoading: false,
      );
    }
  }
}

final historyProvider = NotifierProvider<HistoryNotifier, HistoryState>(
  HistoryNotifier.new,
);
