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
    this.userId,
  });

  /// 요청을 시작한 순서. 클수록 나중에 시작한 요청이다.
  final int requestId;

  /// 서버가 내려준 내 활성 예약. 없으면 null(완료/취소).
  final ActiveReservationModel? mine;

  /// [mine]이 null일 때 목록에서 지울 내 예약 ID.
  final int? trackedId;

  /// 내 사용자 ID. 예약 ID를 모를 때도 목록에서 내 예약을 찾는 데 쓴다.
  ///
  /// 개인은 활성 예약을 1개만 가질 수 있으므로, 같은 사용자의 항목은 모두 "내 예약"이다.
  final int? userId;

  /// 호실 목록 [reservations]에 이 결과를 반영한 새 목록을 반환한다.
  ///
  /// [mine]이 있으면 내 예약을 교체(없으면 추가)하고, null이면 내 예약을 제거한다.
  /// 룸메이트 등 다른 사람의 예약은 그대로 둔다.
  List<ActiveReservationModel> applyTo(
    List<ActiveReservationModel> reservations,
  ) {
    final targetId = mine?.id ?? trackedId;
    final ownerId = mine?.userId ?? userId;
    bool isMine(ActiveReservationModel item) =>
        (targetId != null && item.id == targetId) ||
        (ownerId != null && item.userId == ownerId);

    final firstIndex = reservations.indexWhere(isMine);

    if (mine == null) {
      if (firstIndex < 0) {
        return reservations;
      }
      return reservations.where((item) => !isMine(item)).toList();
    }

    if (firstIndex < 0) {
      return [...reservations, mine!];
    }

    // 첫 번째 항목을 최신 값으로 교체하고, 같은 사용자의 오래된 중복 항목은 지운다.
    final result = <ActiveReservationModel>[];
    for (var i = 0; i < reservations.length; i++) {
      final item = reservations[i];
      if (i == firstIndex) {
        result.add(mine!);
      } else if (!isMine(item)) {
        result.add(item);
      }
    }
    return result;
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
