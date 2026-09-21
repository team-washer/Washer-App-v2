import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';

/// polling으로 확인한 "내 활성 예약" 조회 결과 한 건.
///
/// 호실 목록에 반영할 때 [requestId]로 요청을 시작한 순서를 비교해, 더 늦게 시작한
/// 요청의 결과가 오래된 결과를 이기게 한다. 응답이 뒤바뀌어 도착해도 상태가
/// 과거로 되돌아가지 않는다.
class MyReservationUpdate {
  const MyReservationUpdate({
    required this.requestId,
    required this.mine,
    required this.trackedId,
  });

  /// 요청을 시작한 순서. 클수록 나중에 시작한 요청이다.
  final int requestId;

  /// 서버가 내려준 내 활성 예약. 없으면 null(완료/취소).
  final ActiveReservationModel? mine;

  /// [mine]이 null일 때 목록에서 지울 내 예약 ID.
  final int? trackedId;

  /// 호실 목록 [reservations]에 이 결과를 반영한 새 목록을 반환한다.
  ///
  /// [mine]이 있으면 같은 예약을 교체(없으면 추가)하고, null이면 내 예약을 제거한다.
  /// 룸메이트 등 다른 사람의 예약은 그대로 둔다.
  List<ActiveReservationModel> applyTo(
    List<ActiveReservationModel> reservations,
  ) {
    final targetId = mine?.id ?? trackedId;
    final index = reservations.indexWhere((item) => item.id == targetId);

    if (mine == null) {
      if (index < 0) {
        return reservations;
      }
      return [...reservations]..removeAt(index);
    }

    if (index < 0) {
      return [...reservations, mine!];
    }
    return [...reservations]..[index] = mine!;
  }
}

/// [MyReservationUpdate]를 호실 목록에 반영한 결과.
class MyReservationApplyResult {
  const MyReservationApplyResult({
    required this.isStale,
    required this.hasChanged,
  });

  /// 더 최근에 시작한 요청의 결과가 이미 반영돼 이 결과를 버렸는지 여부.
  final bool isStale;

  /// 반영 결과 목록이 이전과 달라졌는지(또는 호실 목록 응답 대기 중이라 알 수 없는지) 여부.
  final bool hasChanged;
}
