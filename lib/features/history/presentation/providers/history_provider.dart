import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/network/error.dart';
import 'package:washer/features/history/data/data_sources/history_remote_data_source.dart';
import 'package:washer/features/history/data/models/machine_history_response.dart';
import 'package:washer/features/history/presentation/states/history_state.dart';

/// 기기 한 대([machineId])의 사용 기록 조회 상태.
///
/// 기기마다 상태를 따로 두고 다이얼로그가 닫히면 해제되므로,
/// 늦게 도착한 이전 기기의 응답이 다른 기기의 기록·오류를 덮지 않는다.
class HistoryNotifier extends Notifier<HistoryState> {
  HistoryNotifier(this.machineId);

  final int machineId;

  // 같은 기기를 다시 조회하면 이전 요청의 응답은 버리기 위한 요청 번호
  int _requestId = 0;

  @override
  HistoryState build() => const HistoryState();

  /// 기기의 최근 2일(전날 00:00 ~ 오늘 23:59) 사용 기록을 조회한다.
  ///
  /// 앱 주 사용 시간대가 PM 9:20 ~ 새벽이므로, 자정이 지난 후에도
  /// 전날 사용 기록을 확인할 수 있도록 조회 범위를 전날부터 시작한다.
  /// 페이지가 여러 개인 경우 모든 페이지를 순회해 전체 기록을 합쳐 반환한다.
  Future<void> fetchRecentHistory() async {
    final requestId = ++_requestId;
    state = state.copyWith(isLoading: true, error: null);

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final startDate = DateTime(
      yesterday.year,
      yesterday.month,
      yesterday.day,
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

    int page = 0;
    final allHistory = <HistoryContent>[];

    while (true) {
      final result = await guardApiCall(
        () => ref
            .read(historyRemoteDataSourceProvider)
            .getMachineHistory(
              machineId: machineId,
              startDate: startDate,
              endDate: endDate,
              page: page,
              size: 50,
            ),
        logName: 'HistoryNotifier',
      );

      // 다이얼로그가 닫혀 상태가 해제됐거나 더 최신 조회가 시작됐으면 버린다.
      if (!ref.mounted || requestId != _requestId) {
        return;
      }

      switch (result) {
        case ResultSuccess(:final value):
          allHistory.addAll(value.content);
          if (value.last) {
            state = state.copyWith(
              historyList: allHistory,
              isLoading: false,
            );
            return;
          }
          page++;
        case ResultFailure(:final error):
          state = state.copyWith(
            error: error,
            isLoading: false,
          );
          return;
      }
    }
  }
}

/// 기기 ID별 사용 기록 상태. 기록 다이얼로그가 닫히면 자동으로 해제된다.
final historyProvider = NotifierProvider.autoDispose
    .family<HistoryNotifier, HistoryState, int>(HistoryNotifier.new);
