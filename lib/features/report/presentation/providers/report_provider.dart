import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/report/data/data_sources/remote/report_remote_data_source.dart';

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

String reportErrorMessage(Object? error) {
  const fallback = '고장 신고에 실패했습니다. 다시 시도해 주세요.';
  if (error is! DioException || error.response?.data == null) {
    return fallback;
  }

  final response = error.response!.data;
  if (response is Map<String, dynamic> &&
      response['message'] is String &&
      (response['message'] as String).isNotEmpty) {
    return response['message'] as String;
  }

  return fallback;
}

final reportProvider = AsyncNotifierProvider<ReportNotifier, void>(
  ReportNotifier.new,
);
