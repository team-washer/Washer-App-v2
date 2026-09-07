import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/constants/durations.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/core/utils/date_time_formatter.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_remote_data_source.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_status_remote_data_source.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/local/laundry_machine_model.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_exceptions.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_penalty_provider.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_sync_controller.dart';

class ReservationActionNotifier extends AsyncNotifier<ActiveReservationModel?> {
  /// 진행 중인 요청을 대상(기기/예약) 단위로 보관한다.
  /// 키 없이 단일 슬롯에 담으면 다른 대상의 요청에 합류해 그 결과가
  /// 이 호출의 반환값이 된다(#261).
  final Map<String, Future<Object?>> _inflight = {};
  bool _didWaitForBuild = false;

  @override
  Future<ActiveReservationModel?> build() async => null;

  Future<ActiveReservationModel?> reserve({required int machineId}) {
    return _runSingleFlight(
      'reserve:$machineId',
      () => _reserveInternal(machineId: machineId),
    );
  }

  Future<ActiveReservationModel?> _reserveInternal({
    required int machineId,
  }) async {
    try {
      // build()이 끝난 뒤 상태를 바꿔야, 동기 경로에서 던진 예외 상태가
      // 뒤늦게 끝난 build 결과(null)로 덮이지 않는다.
      await _waitForInitialBuild();
      state = const AsyncLoading();

      // 취소 패널티 기간이면 서버로 요청을 보내지 않고 클라이언트에서 곧바로 막는다.
      final penaltyExpiry = ref.read(reservationPenaltyProvider);
      if (penaltyExpiry != null) {
        if (DateTime.now().isBefore(penaltyExpiry)) {
          throw ReservationPenaltyException(penaltyExpiry);
        }
        // 이미 만료된 패널티면 정리만 하고 정상 진행한다.
        ref.read(reservationPenaltyProvider.notifier).clear();
      }

      // 예약 요청 전, 최신 기기 상태를 GET으로 불러와 예약 가능 여부를 비교합니다.
      // 취소 직후 곧바로 재예약하는 경우 서버의 취소 반영이 상태조회에 아직
      // 반영되지 않았을 수 있어, 사용 중으로 보이면 한 번 더 재확인합니다.
      var targetMachine = await _findMachine(machineId);
      if (targetMachine != null && !targetMachine.isAvailable) {
        await Future.delayed(reservationAvailabilityRecheckDelay);
        targetMachine = await _findMachine(machineId);
      }
      if (targetMachine != null && !targetMachine.isAvailable) {
        throw const AlreadyReservedException();
      }

      final startTime = DateTime.now().toIso8601String();

      final createdReservation = await ref
          .read(reservationRemoteDataSourceProvider)
          .createReservation(
            machineId: machineId,
            startTime: startTime,
          );

      await refreshReservationStatusProviders(ref);

      state = AsyncData(createdReservation);
      ref.read(reservationSyncControllerProvider).startPolling();
      return createdReservation;
    } catch (error, stackTrace) {
      AppLogger.error(
        '예약 생성 중 오류가 발생했습니다.',
        name: 'ReservationActionNotifier',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  Future<void> _waitForInitialBuild() async {
    if (_didWaitForBuild) {
      return;
    }

    await future;
    _didWaitForBuild = true;
  }

  Future<MachineModel?> _findMachine(int machineId) async {
    final latestStatus = await ref
        .read(homeRemoteDataSourceProvider)
        .getMachineStatus();
    return latestStatus.machines.firstWhereOrNull(
      (machine) => machine.machineId == machineId,
    );
  }

  Future<bool> cancel({required int reservationId}) {
    return _runSingleFlight(
      'cancel:$reservationId',
      () => _cancelInternal(reservationId: reservationId),
    );
  }

  Future<bool> _cancelInternal({required int reservationId}) async {
    state = const AsyncLoading();

    try {
      ref.read(reservationSyncControllerProvider).stopPolling();

      final result = await ref
          .read(reservationRemoteDataSourceProvider)
          .cancelReservation(id: reservationId);

      // 패널티가 부과됐으면 만료시각을 로컬에 저장해, 이후 예약 시도를 클라에서 막는다.
      if (result.penaltyApplied) {
        final expiry = DateTimeFormatter.parseServerDateTime(
          result.penaltyExpiresAt,
        );
        if (expiry != null) {
          ref.read(reservationPenaltyProvider.notifier).record(expiry);
        }
      }

      await refreshReservationStatusProviders(ref);

      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      AppLogger.error(
        '예약 취소 중 오류가 발생했습니다.',
        name: 'ReservationActionNotifier',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  void reset() {
    state = const AsyncData(null);
    ref.read(reservationSyncControllerProvider).stopPolling();
  }

  /// 같은 [key] 로 들어온 중복 요청만 하나로 합친다.
  ///
  /// 키가 다르면(다른 기기 예약, 다른 예약 취소) 각자 요청을 보낸다.
  /// 합쳐 버리면 누르지 않은 대상의 결과가 반환값이 되어 호출부가 그것을
  /// 성공으로 처리한다(#261).
  Future<T> _runSingleFlight<T>(String key, Future<T> Function() action) {
    final currentRequest = _inflight[key];
    if (currentRequest != null) {
      return currentRequest.then((value) => value as T);
    }

    final request = action();
    _inflight[key] = request;
    request.whenComplete(() => _inflight.remove(key));
    return request;
  }
}

final reservationActionProvider =
    AsyncNotifierProvider<ReservationActionNotifier, ActiveReservationModel?>(
      ReservationActionNotifier.new,
    );
