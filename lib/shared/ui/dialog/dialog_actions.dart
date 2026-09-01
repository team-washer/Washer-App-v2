import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/constants/durations.dart';
import 'package:washer/shared/ui/dialog/dialog_action.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_action_provider.dart';
import 'package:washer/features/report/presentation/providers/report_provider.dart';

/// 다이얼로그/위젯에서 쓰는 비동기 액션 정의 모음.
///
/// 액션의 provider 호출·성공 판정·메시지를 여기 한 곳에서만 정의한다.
/// 동작이나 문구를 바꿀 때 이 파일만 고치면 모든 호출부에 반영된다.
abstract final class DialogActions {
  /// 기기 예약. 성공 시 생성된 예약 모델, 실패 시 null을 반환한다.
  static DialogAction<ActiveReservationModel?> reserve({
    required String machineName,
    required int machineId,
  }) {
    return DialogAction<ActiveReservationModel?>(
      run: (container) => container
          .read(reservationActionProvider.notifier)
          .reserve(
            machineId: machineId,
          ),
      isSuccess: (container) =>
          container.read(reservationActionProvider) is AsyncData,
      successMessage:
          '$machineName 예약이 완료되었습니다\n'
          '$reservationExpiryMinutes분 동안 기기 연결을 확인합니다',
      failureMessage: (container) => reserveFailureMessage(
        container.read(reservationActionProvider).error,
      ),
      logName: 'ReserveAction',
      showLoading: true,
    );
  }

  /// 예약 취소.
  static DialogAction<bool> cancelReservation({required int reservationId}) {
    return DialogAction<bool>(
      run: (container) => container
          .read(reservationActionProvider.notifier)
          .cancel(
            reservationId: reservationId,
          ),
      isSuccess: (container) =>
          container.read(reservationActionProvider) is AsyncData,
      successMessage: '예약이 취소되었습니다.',
      failureMessage: (container) => reservationActionErrorMessage(
        container.read(reservationActionProvider).error,
        fallback: '예약 취소에 실패했습니다.',
      ),
      failureError: (container) =>
          container.read(reservationActionProvider).error,
      logName: 'CancelReservationAction',
    );
  }

  /// 기기 고장 신고.
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
      isSuccess: (container) => container.read(reportProvider) is AsyncData,
      successMessage: '신고가 완료되었습니다.',
      failureMessage: (container) =>
          reportErrorMessage(container.read(reportProvider).error),
      logName: 'ReportBrokenAction',
    );
  }
}
