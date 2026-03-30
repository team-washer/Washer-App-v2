import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/features/dashboard/presentation/viewmodels/home_view_model.dart';
import 'package:washer/features/report/data/repositories/report_repository.dart';

enum ReportActionStatus { idle, loading, success, error }

class ReportActionState {
  const ReportActionState({
    this.status = ReportActionStatus.idle,
    this.errorMessage,
  });

  final ReportActionStatus status;
  final String? errorMessage;
}

class ReportViewModel extends Notifier<ReportActionState> {
  @override
  ReportActionState build() => const ReportActionState();

  Future<ReportActionState> createMalfunctionReport({
    required int machineId,
    required String description,
  }) async {
    state = const ReportActionState(status: ReportActionStatus.loading);

    try {
      await ref
          .read(reportRepositoryProvider)
          .createMalfunctionReport(
            machineId: machineId,
            description: description,
          );
      await ref.read(machineStatusProvider.notifier).refresh();
      await ref.read(activeReservationProvider.notifier).refresh();

      const nextState = ReportActionState(status: ReportActionStatus.success);
      state = nextState;
      return nextState;
    } catch (e) {
      var errorMessage = '고장 신고에 실패했습니다. 다시 시도해 주세요.';

      if (e is DioException && e.response?.data != null) {
        final response = e.response!.data;
        if (response is Map<String, dynamic> &&
            response['message'] is String &&
            (response['message'] as String).isNotEmpty) {
          errorMessage = response['message'] as String;
        }
      }

      final nextState = ReportActionState(
        status: ReportActionStatus.error,
        errorMessage: errorMessage,
      );
      state = nextState;
      return nextState;
    }
  }

  void reset() {
    state = const ReportActionState();
  }
}

final reportViewModelProvider =
    NotifierProvider<ReportViewModel, ReportActionState>(
      ReportViewModel.new,
    );
