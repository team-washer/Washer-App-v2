import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/report/data/data_sources/remote/report_remote_data_source.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';

class ReportNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

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

      try {
        await refreshReservationStatusProviders(ref);
      } catch (error, stackTrace) {
        AppLogger.error(
          '고장 신고 후 상태 새로고침 중 오류가 발생했습니다.',
          name: 'ReportNotifier',
          error: error,
          stackTrace: stackTrace,
        );
      }

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

  void reset() {
    state = const AsyncData(null);
  }
}

final reportProvider = AsyncNotifierProvider<ReportNotifier, void>(
  ReportNotifier.new,
);
