import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_status_remote_data_source.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';

/// [ReservationSyncController] provider. dispose 시 polling을 정리한다.
final reservationSyncControllerProvider = Provider<ReservationSyncController>((
  ref,
) {
  final controller = ReservationSyncController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});

/// 활성 예약을 주기적으로 조회(polling)해 예약/기기 상태 provider와 동기화한다.
class ReservationSyncController {
  ReservationSyncController(this._ref);

  static const Duration _pollingInterval = Duration(seconds: 10);

  /// 활성 예약 조회가 연속으로 이 횟수만큼 실패하면 서버 장애로 간주하고
  /// polling을 중단한다(#276 리뷰: 실패 경로에 안전장치가 없던 문제).
  static const int _maxConsecutiveFailures = 5;

  final Ref _ref;
  Timer? _pollingTimer;
  int _consecutiveFailures = 0;

  bool get isPolling => _pollingTimer != null;

  // 서버가 활성 예약을 반환하는 한 완료가 확정되지 않은 것이므로, 정상적으로 긴
  // 세탁/건조 사이클이라도 시간 기반으로 polling을 조기 종료하지 않는다(#276).
  // 대신 조회 자체가 계속 실패하는 경우에는 아래 실패 카운터로 종료한다.
  /// polling을 (재)시작한다. 이미 돌고 있으면 정지 후 실패 카운터를 초기화해 다시 시작한다.
  void startPolling() {
    stopPolling();
    _consecutiveFailures = 0;

    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      unawaited(syncActiveReservation());
    });
  }

  /// 활성 예약을 한 번 조회해 변경이 있을 때만 상태를 갱신한다.
  /// 활성 예약이 없어지면 polling을 멈춘다. [forceMachineRefresh]는 변경이 없어도 기기 상태를 새로고침한다.
  Future<void> syncActiveReservation({
    bool forceMachineRefresh = false,
  }) async {
    try {
      final current = _ref
          .read(activeReservationProvider)
          .maybeWhen(
            data: (value) => value,
            orElse: () => const <ActiveReservationModel>[],
          );

      final latest = await _ref
          .read(reservationStatusRemoteDataSourceProvider)
          .getActiveReservations();
      _consecutiveFailures = 0;

      if (latest.isEmpty) {
        stopPolling();

        if (current.isNotEmpty) {
          _ref
              .read(activeReservationProvider.notifier)
              .setReservations(const <ActiveReservationModel>[]);
        }

        if (current.isNotEmpty || forceMachineRefresh) {
          await _ref.read(machineStatusProvider.notifier).refresh();
        }
        return;
      }

      final hasChanged = !_sameReservations(current, latest);

      if (hasChanged) {
        _ref.read(activeReservationProvider.notifier).setReservations(latest);
      }

      if (hasChanged || forceMachineRefresh) {
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

  /// polling 타이머를 정지한다.
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void dispose() {
    stopPolling();
  }

  bool _sameReservations(
    List<ActiveReservationModel> current,
    List<ActiveReservationModel> latest,
  ) {
    if (current.length != latest.length) {
      return false;
    }

    return listEquals(current, latest);
  }
}
