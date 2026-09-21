import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/constants/reservation_durations.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/core/utils/date_time_formatter.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_remote_data_source.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_status_remote_data_source.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/local/machine_model.dart';
import 'package:washer/features/reservation/data/models/remote/reservation_availability_response.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_exceptions.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_sync_controller.dart';

/// 예약 생성/취소 요청을 실행하고 진행 상태(로딩/성공/실패)를 노출한다.
///
/// 상태 값은 마지막으로 생성된 예약이며, 실패는 [AsyncError]로 전달된다.
class ReservationActionNotifier extends AsyncNotifier<ActiveReservationModel?> {
  /// 진행 중인 요청을 대상(기기/예약) 단위로 보관한다.
  /// 키 없이 단일 슬롯에 담으면 다른 대상의 요청에 합류해 그 결과가
  /// 이 호출의 반환값이 된다(#261).
  final Map<String, Future<Object?>> _inflight = {};
  bool _didWaitForBuild = false;

  @override
  Future<ActiveReservationModel?> build() async => null;

  /// 기기 예약을 요청한다. 실패하면 상태를 에러로 두고 null을 반환한다.
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

      // 취소 패널티 기간이면 예약 요청을 보내지 않고 곧바로 안내한다.
      await _ensureNotPenalized();

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
      ref
          .read(reservationSyncControllerProvider)
          .startPolling(reservationId: createdReservation.id);
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

  /// build() 완료를 최초 한 번만 기다린다.
  Future<void> _waitForInitialBuild() async {
    if (_didWaitForBuild) {
      return;
    }

    await future;
    _didWaitForBuild = true;
  }

  /// 서버의 예약 가능 상태를 조회해 패널티 중이면 [ReservationPenaltyException]을 던진다.
  ///
  /// 패널티는 앱이 기록하지 않고 서버 상태(`reservations/availability`)를 따른다.
  /// 예약 불가(`canReserve=false`)이면서 만료 시각이 아직 남았을 때만 막는다.
  /// 그 외 예약 불가 사유(호실 금지, 시간 제한 등)는 서버가 예약 요청에서
  /// 메시지로 응답하므로 여기서 막지 않는다. 조회 자체가 실패해도 서버가 예약
  /// 요청에서 최종 검증하므로 예약은 그대로 진행한다.
  Future<void> _ensureNotPenalized() async {
    final ReservationAvailabilityResponse availability;
    try {
      availability = await ref
          .read(reservationStatusRemoteDataSourceProvider)
          .getReservationAvailability();
    } catch (error, stackTrace) {
      AppLogger.error(
        '예약 가능 상태 조회에 실패해 서버 검증에 맡기고 진행합니다.',
        name: 'ReservationActionNotifier',
        error: error,
        stackTrace: stackTrace,
      );
      return;
    }

    final expiresAt = DateTimeFormatter.parseServerDateTime(
      availability.penaltyExpiresAt,
    );
    if (!availability.canReserve &&
        expiresAt != null &&
        DateTime.now().isBefore(expiresAt)) {
      throw ReservationPenaltyException(expiresAt);
    }
  }

  /// 서버에서 최신 기기 상태를 조회해 대상 기기를 찾는다.
  Future<MachineModel?> _findMachine(int machineId) async {
    final latestStatus = await ref
        .read(reservationStatusRemoteDataSourceProvider)
        .getMachineStatus();
    return latestStatus.machines.firstWhereOrNull(
      (machine) => machine.machineId == machineId,
    );
  }

  /// 예약을 취소한다. 성공 여부를 반환한다. 패널티는 서버가 관리하므로 앱은 기록하지 않는다.
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

      await ref
          .read(reservationRemoteDataSourceProvider)
          .cancelReservation(id: reservationId);

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

  /// 상태를 초기화하고 활성 예약 polling을 멈춘다.
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
    unawaited(
      request.then<void>(
        (_) => _inflight.remove(key),
        onError: (Object _, StackTrace __) {
          _inflight.remove(key);
        },
      ),
    );
    return request;
  }
}

/// 예약 생성/취소 액션 provider.
final reservationActionProvider =
    AsyncNotifierProvider<ReservationActionNotifier, ActiveReservationModel?>(
      ReservationActionNotifier.new,
    );
