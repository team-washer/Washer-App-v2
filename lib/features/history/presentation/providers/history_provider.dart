import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:washer/core/network/error.dart';
import 'package:washer/features/history/data/data_sources/history_remote_data_source.dart';
import 'package:washer/features/history/presentation/states/history_state.dart';

/// 사용 기록 조회 오류를 UI(스낵바)로 전달하기 위한 일회성 오류 상태
final historyErrorProvider = StateProvider<Object?>((ref) => null);

class HistoryNotifier extends Notifier<HistoryState> {
  @override
  HistoryState build() => const HistoryState();

  /// 기기의 오늘(00:00~23:59) 사용 기록을 조회한다.
  Future<void> fetchTodayHistory(int machineId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    ref.read(historyErrorProvider.notifier).state = null;

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

    final result = await guardApiCall(
      () => ref
          .read(historyRemoteDataSourceProvider)
          .getMachineHistory(
            machineId: machineId,
            startDate: startDate,
            endDate: endDate,
            page: 0,
            size: 50,
          ),
      logName: 'HistoryNotifier',
    );

    switch (result) {
      case ResultSuccess(:final value):
        state = state.copyWith(
          historyList: value.content,
          isLoading: false,
        );
      case ResultFailure(:final error):
        ref.read(historyErrorProvider.notifier).state = error;
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
