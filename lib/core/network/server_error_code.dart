/// 서버 오류 응답의 `data.errorCode` 값(서버 `ErrorCode`, 백엔드 #196).
///
/// 서버는 사람이 읽는 `message`와 앱이 분기할 `errorCode`를 분리해 내려준다.
/// 앱은 문구가 아닌 이 코드로 원인을 분기한다. 코드 이름은 서버 응답 계약이라
/// 바뀌지 않는다. 원인별 코드를 쓰지 않는 서버 예외는 HTTP 상태 이름
/// (`BAD_REQUEST`, `CONFLICT` 등)을 코드로 내려준다.
abstract final class ServerErrorCode {
  // 요청 검증
  static const validationFailed = 'VALIDATION_FAILED';
  static const invalidRequestBody = 'INVALID_REQUEST_BODY';
  static const typeMismatch = 'TYPE_MISMATCH';
  static const missingParameter = 'MISSING_PARAMETER';

  // 인증·권한
  static const authenticationRequired = 'AUTHENTICATION_REQUIRED';
  static const accessTokenExpired = 'ACCESS_TOKEN_EXPIRED';
  static const accessTokenInvalid = 'ACCESS_TOKEN_INVALID';
  static const refreshTokenExpired = 'REFRESH_TOKEN_EXPIRED';
  static const refreshTokenInvalid = 'REFRESH_TOKEN_INVALID';
  static const withdrawnRejoinRestricted = 'WITHDRAWN_REJOIN_RESTRICTED';
  static const forbidden = 'FORBIDDEN';

  // 대상 없음
  static const userNotFound = 'USER_NOT_FOUND';
  static const reservationNotFound = 'RESERVATION_NOT_FOUND';
  static const machineNotFound = 'MACHINE_NOT_FOUND';
  static const roomNotFound = 'ROOM_NOT_FOUND';

  // 이용 제한
  static const roomWashingBanned = 'ROOM_WASHING_BANNED';
  static const userFloorRestricted = 'USER_FLOOR_RESTRICTED';
  static const userPenaltyActive = 'USER_PENALTY_ACTIVE';
  static const reservationCooldownActive = 'RESERVATION_COOLDOWN_ACTIVE';
  static const roomReservationRestricted = 'ROOM_RESERVATION_RESTRICTED';
  static const reservationTimeRestricted = 'RESERVATION_TIME_RESTRICTED';

  // 예약·기기 충돌
  static const userActiveReservation = 'USER_ACTIVE_RESERVATION';
  static const roomMachineTypeReserved = 'ROOM_MACHINE_TYPE_RESERVED';
  static const machineUnavailable = 'MACHINE_UNAVAILABLE';
  static const machineAlreadyReserved = 'MACHINE_ALREADY_RESERVED';
  static const machineInUse = 'MACHINE_IN_USE';
  static const machineShutdownInProgress = 'MACHINE_SHUTDOWN_IN_PROGRESS';
  static const reservationCancellationConflict =
      'RESERVATION_CANCELLATION_CONFLICT';
  static const reservationStateInvalid = 'RESERVATION_STATE_INVALID';
  static const reservationAccessDenied = 'RESERVATION_ACCESS_DENIED';

  /// 동시 요청(낙관적 락 등) 충돌. 원인별 코드가 없는 409의 상태 이름이기도 해서
  /// 이 코드만으로는 원인을 단정할 수 없다.
  static const conflict = 'CONFLICT';

  /// 입력 검증 오류 코드. 이 코드면 `data.fieldErrors`로 잘못된 필드를 안내한다.
  static const Set<String> validation = {
    validationFailed,
    invalidRequestBody,
    typeMismatch,
    missingParameter,
  };
}
