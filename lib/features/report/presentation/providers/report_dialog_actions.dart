import 'package:washer/features/report/presentation/providers/report_provider.dart';
import 'package:washer/shared/ui/dialog/dialog_action.dart';

/// 고장 신고 비동기 액션 정의.
///
/// report feature가 다른 feature(reservation)를 몰라도 되도록, 신고 액션은
/// shared의 `LaundryDialogActions`가 아니라 여기서 정의한다.
abstract final class ReportDialogActions {
  /// 기기 고장 신고. 성공하면 true를 반환한다.
  static DialogAction<bool> reportBroken({
    required int machineId,
    required String description,
  }) {
    return DialogAction<bool>(
      run: (container) => container
          .read(reportProvider.notifier)
          .createMalfunctionReport(
            machineId: machineId,
            description: description,
          ),
      isSuccess: (didReport) => didReport,
      successMessage: '신고가 완료되었습니다.',
      fallbackMessage: '고장 신고에 실패했습니다. 다시 시도해 주세요.',
      failureError: (container) => container.read(reportProvider).error,
      logName: 'ReportBrokenAction',
    );
  }
}
