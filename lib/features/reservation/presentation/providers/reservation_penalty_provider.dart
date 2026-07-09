import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 예약 취소 패널티 만료시각을 현재 세션 동안 메모리에 보관한다.
///
/// 패널티 기간에는 서버가 예약 요청을 거부하므로, 만료시각을 들고 있다가
/// 그 사이의 예약 시도는 서버로 보내지 않고 클라이언트에서 곧바로 막는다.
/// 앱을 재시작하면 초기화되며, 재시작 후에는 서버 응답으로 다시 차단된다.
class ReservationPenaltyNotifier extends AsyncNotifier<DateTime?> {
  @override
  Future<DateTime?> build() async => null;

  /// 서버가 알려준 패널티 만료시각을 기록한다.
  Future<void> record(DateTime expiresAt) async {
    state = AsyncData(expiresAt);
  }

  /// 만료된 패널티를 비운다.
  Future<void> clear() async {
    state = const AsyncData(null);
  }
}

final reservationPenaltyProvider =
    AsyncNotifierProvider<ReservationPenaltyNotifier, DateTime?>(
      ReservationPenaltyNotifier.new,
    );
