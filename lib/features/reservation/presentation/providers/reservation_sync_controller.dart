import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_status_remote_data_source.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';

final reservationSyncControllerProvider = Provider<ReservationSyncController>((
  ref,
) {
  final controller = ReservationSyncController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});

class ReservationSyncController {
  ReservationSyncController(this._ref);

  static const Duration _pollingInterval = Duration(seconds: 10);

  final Ref _ref;
  Timer? _pollingTimer;

  bool get isPolling => _pollingTimer != null;

  // 서버가 활성 예약을 반환하는 한 완료가 확정되지 않은 것이므로, 정상적으로 긴
  // 세탁/건조 사이클이라도 시간 기반으로 polling을 조기 종료하지 않는다(#276).
  void startPolling() {
    stopPolling();

    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      unawaited(syncActiveReservation());
    });
  }

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
          .read(homeRemoteDataSourceProvider)
          .getActiveReservations();
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
    }
  }

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
