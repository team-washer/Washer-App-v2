import 'package:washer/core/errors/app_exception.dart';

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
