import 'package:washer/core/network/error.dart';

/// 예약 요청 직전 조회에서 이미 예약 또는 사용 중인 기기로 확인된 경우.
class AlreadyReservedException implements UserFacingException {
  const AlreadyReservedException();

  @override
  String get userMessage => '이미 예약된 기기입니다.';
}

/// 취소 패널티 기간이라 서버 요청 없이 예약을 막은 경우.
class ReservationPenaltyException implements UserFacingException {
  const ReservationPenaltyException(this.expiresAt);

  final DateTime expiresAt;

  @override
  String get userMessage {
    final remaining = expiresAt.difference(DateTime.now());
    final minutes = remaining.inMinutes;
    return minutes >= 1
        ? '예약이 제한된 상태입니다. 약 $minutes분 후 다시 시도해주세요.'
        : '예약이 제한된 상태입니다. 잠시 후 다시 시도해주세요.';
  }
}

/// 예약 생성·취소 실패 원인. 사용자가 취해야 할 다음 행동 기준으로 나눈다(#306).
///
/// UI는 문구 문자열을 비교하지 않고 이 값으로 분기한다.
enum ReservationErrorCause {
  /// 입력 검증 오류. 잘못된 필드를 고쳐 다시 요청한다.
  validation,

  /// 내 활성 예약이 이미 있다(1인 1예약). 기존 예약을 확인한다.
  activeReservationExists,

  /// 같은 호실에 같은 유형 기기 예약이 이미 있다. 다른 유형을 고르거나 기다린다.
  roomSameTypeReserved,

  /// 취소 패널티·쿨다운·예약 가능 시간 제한. 제한이 풀린 뒤 다시 시도한다.
  restricted,

  /// 서비스 이용 대상이 아니다(1~4층 기숙사생만 이용 가능). 기다려도 풀리지 않는다.
  notEligible,

  /// 다른 사용자가 이미 기기를 점유했다. 최신 상태를 보고 다른 기기를 고른다.
  machineOccupied,

  /// 동시 요청 충돌. 최신 상태를 확인하고 다시 시도한다.
  conflict,

  /// 이미 사용이 시작된 예약을 취소하려 했다.
  alreadyStarted,

  /// 위에 해당하지 않는 실패. 공통 [AppException] 문구를 따른다.
  unknown,
}

/// 원인([cause])이 분류된 예약 생성·취소 실패.
///
/// [AppException]을 상속하므로 공통 에러 토스트에 그대로 넘기면 된다.
class ReservationException extends AppException {
  ReservationException({
    required this.cause,
    required super.message,
    super.statusCode,
    super.debugMessage,
    super.errorCode,
    super.traceId,
    super.fieldErrors,
    super.serverMessage,
  });

  /// [base]의 추적 정보는 유지한 채 원인과 화면 문구만 바꾼다.
  ReservationException.from(
    AppException base, {
    required ReservationErrorCause cause,
    required String message,
  }) : this(
         cause: cause,
         message: message,
         statusCode: base.statusCode,
         debugMessage: base.debugMessage,
         errorCode: base.errorCode,
         traceId: base.traceId,
         fieldErrors: base.fieldErrors,
         serverMessage: base.serverMessage,
       );

  final ReservationErrorCause cause;

  static const Map<String, String> _fieldLabels = {
    'machineId': '기기',
    'reservationId': '예약',
    'id': '예약',
    'startTime': '시작 시간',
  };

  @override
  String? fieldLabel(String field) => _fieldLabels[field];
}
