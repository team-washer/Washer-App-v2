import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_status_remote_data_source.dart';
import 'package:washer/features/reservation/presentation/providers/my_reservation_update.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';
import 'package:washer/features/user/presentation/providers/my_user_provider.dart';

/// [ReservationSyncController] provider. dispose 시 polling을 정리한다.
final reservationSyncControllerProvider = Provider<ReservationSyncController>((
  ref,
) {
  final controller = ReservationSyncController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});

/// 내 활성 예약(`reservations/active`)을 주기적으로 조회(polling)해
/// 예약/기기 상태 provider와 동기화한다.
///
/// 호실 전체 목록(`reservations/active/room`)은 홈 최초 진입 시에만 불러오므로,
/// polling에서는 내 예약 한 건만 조회하고 그 결과를 이미 불러온 호실 목록에
/// 반영(교체/제거)한다.
///
/// 요청은 시작할 때마다 순번(요청 id)을 받는다. 응답이 뒤바뀌어 도착하거나 호실 목록
/// 요청과 겹쳐도, 늦게 시작한 요청의 결과가 이기고 오래된 응답은 버려진다.
class ReservationSyncController {
  ReservationSyncController(this._ref);

  static const Duration _pollingInterval = Duration(seconds: 10);

  /// 활성 예약 조회가 연속으로 이 횟수만큼 실패하면 서버 장애로 간주하고
  /// polling을 중단한다(#276 리뷰: 실패 경로에 안전장치가 없던 문제).
  static const int _maxConsecutiveFailures = 5;

  /// 내 예약 polling이 이 횟수만큼 성공할 때마다 호실 목록도 백그라운드로 다시 맞춘다.
  /// (10초 x 6 = 약 60초.) 룸메이트 예약의 변화를 반영하기 위한 낮은 빈도의 동기화다.
  static const int _roomSyncEveryPolls = 6;

  final Ref _ref;
  Timer? _pollingTimer;
  int _consecutiveFailures = 0;

  /// 호실 목록에서 "내 예약"을 가리키는 예약 ID.
  /// 서버가 내 예약이 없다고(null) 응답할 때 목록에서 무엇을 지울지 알기 위해 보관한다.
  int? _trackedReservationId;

  /// 내 사용자 ID. 예약 ID를 모를 때도 호실 목록에서 내 예약을 식별하는 데 쓴다.
  int? _myUserId;

  /// 마지막 호실 목록 동기화 이후 성공한 polling 횟수.
  int _pollsSinceRoomSync = 0;

  bool get isPolling => _pollingTimer != null;

  /// polling을 (재)시작한다. 이미 돌고 있으면 정지 후 실패 카운터를 초기화해 다시 시작한다.
  ///
  /// 서버가 내 활성 예약을 반환하는 한 완료가 확정되지 않은 것이므로, 정상적으로 긴
  /// 세탁/건조 사이클이라도 시간 기반으로 polling을 조기 종료하지 않는다(#276).
  /// 대신 조회 자체가 계속 실패하는 경우에는 실패 카운터로 종료한다.
  /// [reservationId]/[userId]는 방금 생성한 내 예약의 ID와 소유자(나)의 ID다. 모르면
  /// 생략할 수 있고, 그때는 로그인한 사용자 정보와 polling 응답으로 내 예약을 식별한다.
  void startPolling({int? reservationId, int? userId}) {
    stopPolling();
    _consecutiveFailures = 0;
    _pollsSinceRoomSync = 0;
    _trackedReservationId = reservationId ?? _trackedReservationId;
    _myUserId = userId ?? _myUserId;

    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      unawaited(syncActiveReservation());
    });
  }

  /// 내 활성 예약을 한 번 조회해 변경이 있을 때만 상태를 갱신한다.
  /// 내 활성 예약이 없어지면(서버가 null 응답) 목록에서 제거하고 polling을 멈춘다.
  /// [forceMachineRefresh]는 변경이 없어도 기기 상태를 새로고침한다.
  Future<void> syncActiveReservation({
    bool forceMachineRefresh = false,
  }) async {
    try {
      final activeReservations = _ref.read(activeReservationProvider.notifier);
      // 요청을 시작한 순서를 기록한다. 응답 도착 순서와 무관하게 늦게 시작한 요청이 이긴다.
      final requestId = activeReservations.beginRequest();

      final mine = await _ref
          .read(reservationStatusRemoteDataSourceProvider)
          .getMyActiveReservation();
      _consecutiveFailures = 0;

      final result = activeReservations.applyMyReservation(
        MyReservationUpdate(
          requestId: requestId,
          mine: mine,
          trackedId: _trackedReservationId,
          userId: _currentUserId(),
        ),
      );
      // 더 최근에 시작한 요청의 결과가 이미 반영됐다. 이 응답은 버리고, 종료 판단에도
      // 쓰지 않는다(오래된 null이 최신 상태를 되돌리거나 polling을 끊으면 안 된다).
      if (result.isStale) {
        return;
      }

      if (mine == null) {
        // 서버가 내 활성 예약이 없다고 확정했으므로(완료/취소) polling을 끝낸다.
        final wasTracking = _trackedReservationId != null;
        _trackedReservationId = null;
        stopPolling();

        // 룸메이트 예약의 변화도 마지막으로 한 번 맞춘다.
        unawaited(activeReservations.reloadInBackground());

        // 예약이 끝나면 점유하던 기기 상태도 바뀌므로 함께 갱신한다.
        if (result.hasChanged || wasTracking || forceMachineRefresh) {
          await _ref.read(machineStatusProvider.notifier).refresh();
        }
        return;
      }

      _trackedReservationId = mine.id;
      _myUserId = mine.userId;

      // 내 예약만 조회하므로, 낮은 빈도로 호실 목록도 함께 맞춰 룸메이트 예약을 최신으로 둔다.
      _pollsSinceRoomSync += 1;
      if (_pollsSinceRoomSync >= _roomSyncEveryPolls) {
        _pollsSinceRoomSync = 0;
        unawaited(activeReservations.reloadInBackground());
      }

      if (result.hasChanged || forceMachineRefresh) {
        await _ref.read(machineStatusProvider.notifier).refresh();
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        '활성 예약 동기화 중 오류가 발생했습니다.',
        name: 'ReservationSyncController',
        error: error,
        stackTrace: stackTrace,
      );

      _consecutiveFailures += 1;
      if (_consecutiveFailures >= _maxConsecutiveFailures) {
        // 상세 원인(예외/스택트레이스/실패 횟수)은 로그에만 남기고, 사용자에게는
        // 짧은 안내 문구만 노출한다.
        AppLogger.error(
          '활성 예약 조회가 $_consecutiveFailures회 연속 실패해 polling을 중단합니다.',
          name: 'ReservationSyncController',
        );
        stopPolling();
        _ref.read(pollingErrorProvider.notifier).state = '서버 상태가 지연되고 있습니다.';
      }
    }
  }

  /// 내 사용자 ID. polling에서 알게 된 값을 우선하고, 없으면 이미 불러온 내 정보를 쓴다.
  /// (내 정보가 아직 만들어지지 않았으면 새로 요청하지 않고 null을 돌려준다.)
  int? _currentUserId() {
    if (_myUserId != null) {
      return _myUserId;
    }
    if (_ref.exists(myUserProvider)) {
      return _ref.read(myUserProvider).value?.id;
    }
    return null;
  }

  /// polling 타이머를 정지한다.
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void dispose() {
    stopPolling();
  }
}
