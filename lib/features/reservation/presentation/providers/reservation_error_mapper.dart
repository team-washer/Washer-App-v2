import 'package:washer/core/network/error.dart';
import 'package:washer/core/network/server_error_code.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_exceptions.dart';
import 'package:washer/shared/theme/washer_error_message.dart';

/// 실패한 예약 액션의 종류. 원인별 코드가 없을 때 같은 상태 코드라도 액션에 따라
/// 원인이 다르다.
enum ReservationAction { reserve, cancel }

/// 예약 생성·취소 실패를 원인([ReservationErrorCause])이 분류된 [AppException]으로
/// 정규화한다(#306).
///
/// 분류 순서:
/// 1. 앱이 직접 던진 도메인 예외(사전 조회로 막은 경우)
/// 2. 서버의 원인별 `errorCode`(백엔드 #196)
/// 3. 원인별 코드가 없는 400/409(구버전 서버·상태 이름 코드)는 상태 코드와 [action]
///
/// 그 밖의 오류(401/404/451/502/503 등)는 공통 문구를 그대로 쓴다.
AppException reservationErrorToAppException(
  Object? error, {
  required ReservationAction action,
}) {
  switch (error) {
    case ReservationException():
      return error;
    case AlreadyReservedException():
      return ReservationException(
        cause: ReservationErrorCause.machineOccupied,
        message: WasherErrorMessage.machineTaken,
        debugMessage: error.toString(),
      );
    case ReservationPenaltyException():
      return ReservationException(
        cause: ReservationErrorCause.restricted,
        message: error.userMessage,
        debugMessage: error.toString(),
      );
  }

  final base = AppException.from(error);

  final codeCause = _causeByErrorCode[base.errorCode];
  if (codeCause != null) {
    return ReservationException.from(
      base,
      cause: codeCause,
      message: base.message,
    );
  }

  return switch (base.statusCode) {
    409 when action == ReservationAction.cancel => ReservationException.from(
      base,
      cause: ReservationErrorCause.alreadyStarted,
      message: WasherErrorMessage.reservationAlreadyStarted,
    ),
    409 => ReservationException.from(
      base,
      cause: ReservationErrorCause.conflict,
      message: base.message,
    ),
    // 원인을 모르는 400을 입력 오류로 단정하지 않고 서버의 사람이 읽는 문구를 쓴다.
    400 => ReservationException.from(
      base,
      cause: ReservationErrorCause.unknown,
      message: base.serverMessage ?? WasherErrorMessage.unprocessable,
    ),
    _ => base,
  };
}

/// 서버 원인별 코드 → 사용자가 취할 다음 행동 기준의 원인.
const Map<String, ReservationErrorCause> _causeByErrorCode = {
  ServerErrorCode.validationFailed: ReservationErrorCause.validation,
  ServerErrorCode.invalidRequestBody: ReservationErrorCause.validation,
  ServerErrorCode.typeMismatch: ReservationErrorCause.validation,
  ServerErrorCode.missingParameter: ReservationErrorCause.validation,
  ServerErrorCode.userActiveReservation:
      ReservationErrorCause.activeReservationExists,
  ServerErrorCode.roomMachineTypeReserved:
      ReservationErrorCause.roomSameTypeReserved,
  ServerErrorCode.userPenaltyActive: ReservationErrorCause.restricted,
  ServerErrorCode.reservationCooldownActive: ReservationErrorCause.restricted,
  ServerErrorCode.roomReservationRestricted: ReservationErrorCause.restricted,
  ServerErrorCode.reservationTimeRestricted: ReservationErrorCause.restricted,
  ServerErrorCode.roomWashingBanned: ReservationErrorCause.restricted,
  ServerErrorCode.machineAlreadyReserved: ReservationErrorCause.machineOccupied,
  ServerErrorCode.machineInUse: ReservationErrorCause.machineOccupied,
  ServerErrorCode.machineUnavailable: ReservationErrorCause.machineOccupied,
  ServerErrorCode.machineShutdownInProgress: ReservationErrorCause.conflict,
  ServerErrorCode.reservationStateInvalid: ReservationErrorCause.conflict,
  ServerErrorCode.conflict: ReservationErrorCause.conflict,
  ServerErrorCode.reservationCancellationConflict:
      ReservationErrorCause.alreadyStarted,
};
