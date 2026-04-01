enum ReportActionStatus { idle, loading, success, error }

class ReportActionState {
  const ReportActionState({
    this.status = ReportActionStatus.idle,
    this.errorMessage,
  });

  final ReportActionStatus status;
  final String? errorMessage;
}
