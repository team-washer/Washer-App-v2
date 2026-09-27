import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/report/data/data_sources/remote/report_remote_data_source.dart';

/// 기기 고장 신고 요청과 그 진행 상태를 관리하는 Notifier.
///
/// 다른 feature(reservation)를 알지 않는다. 신고 후 화면 갱신이 필요하면
/// 호출한 쪽이 `ReportBrokenDialog.onReported` 콜백으로 처리한다.
class ReportNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// 고장 신고를 접수하고 성공 여부를 반환한다.
  Future<bool> createMalfunctionReport({
    required int machineId,
    required String description,
  }) async {
    state = const AsyncLoading();

    try {
      await ref
          .read(reportRemoteDataSourceProvider)
          .createMalfunctionReport(
            machineId: machineId,
            description: description,
          );

      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      AppLogger.error(
        '고장 신고 중 오류가 발생했습니다.',
        name: 'ReportNotifier',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  /// 신고 상태를 초기값으로 되돌린다.
  void reset() {
    state = const AsyncData(null);
  }
}

final reportProvider = AsyncNotifierProvider<ReportNotifier, void>(
  ReportNotifier.new,
);
