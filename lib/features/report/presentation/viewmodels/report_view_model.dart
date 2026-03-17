import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:washer/features/report/data/repositories/report_repository.dart';

enum ReportActionStatus { idle, loading, success, error }

class ReportActionState {
  final ReportActionStatus status;
  final String? errorMessage;

  const ReportActionState({
    this.status = ReportActionStatus.idle,
    this.errorMessage,
  });

  ReportActionState copyWith({
    ReportActionStatus? status,
    String? errorMessage,
  }) {
    return ReportActionState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ReportViewModel extends Notifier<ReportActionState> {
  @override
  ReportActionState build() => const ReportActionState();

  Future<void> createMalfunctionReport({
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

      state = const ReportActionState(status: ReportActionStatus.success);
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

      state = ReportActionState(
        status: ReportActionStatus.error,
        errorMessage: errorMessage,
      );
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
