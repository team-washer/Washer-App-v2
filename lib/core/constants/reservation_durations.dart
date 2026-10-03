/// 예약 후 확정(이용 시작)하지 않으면 만료되는 시간(분).
const int reservationExpiryMinutes = 5;

/// [reservationExpiryMinutes]를 [Duration]으로 표현한 값.
const Duration reservationExpiryDuration = Duration(
  minutes: reservationExpiryMinutes,
);

/// 예약 직전 상태조회에서 기기가 사용 중으로 보일 때, 한 번 더 재확인하기 전 대기 시간.
/// 취소 직후 곧바로 재예약하는 경우 서버의 취소 반영 지연을 흡수하기 위함.
const Duration reservationAvailabilityRecheckDelay = Duration(
  milliseconds: 500,
);
