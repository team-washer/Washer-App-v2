import 'dart:async';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/core/utils/date_time_formatter.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_remote_data_source.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_status_remote_data_source.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_penalty_provider.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_sync_controller.dart';

/// 예약 요청 직전 GET으로 확인한 결과, 이미 예약/사용 중이라 예약할 수 없는 경우.
class AlreadyReservedException implements Exception {
  const AlreadyReservedException();
}

/// 취소 패널티 기간이라 서버 요청 없이 클라이언트에서 예약을 막은 경우.
class ReservationPenaltyException implements Exception {
  const ReservationPenaltyException(this.expiresAt);

  final DateTime expiresAt;
}

class ReservationActionNotifier extends AsyncNotifier<ActiveReservationModel?> {
  Future<ActiveReservationModel?>? _reserveRequest;
  Future<bool>? _cancelRequest;

  @override
  Future<ActiveReservationModel?> build() async => null;

  Future<ActiveReservationModel?> reserve({required int machineId}) {
    return _runSingleFlight(
      currentRequest: _reserveRequest,
      setRequest: (request) => _reserveRequest = request,
      action: () => _reserveInternal(machineId: machineId),
    );
  }

  Future<ActiveReservationModel?> _reserveInternal({
    required int machineId,
  }) async {
    // build()이 끝난 뒤 상태를 바꿔야, 동기 경로에서 던진 예외 상태가
    // 뒤늦게 끝난 build 결과(null)로 덮이지 않는다.
    await future;
    state = const AsyncLoading();

    try {
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
      final latestStatus = await ref
          .read(homeRemoteDataSourceProvider)
          .getMachineStatus();
      final targetMachine = latestStatus.machines.firstWhereOrNull(
        (machine) => machine.machineId == machineId,
      );
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

  Future<bool> cancel({required int reservationId}) {
    return _runSingleFlight(
      currentRequest: _cancelRequest,
      setRequest: (request) => _cancelRequest = request,
      action: () => _cancelInternal(reservationId: reservationId),
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

  Future<T> _runSingleFlight<T>({
    required Future<T>? currentRequest,
    required void Function(Future<T>? request) setRequest,
    required Future<T> Function() action,
  }) {
    if (currentRequest != null) {
      return currentRequest;
    }

    final request = action();
    setRequest(request);
    request.whenComplete(() => setRequest(null));
    return request;
  }
}

String reservationActionErrorMessage(
  Object? error, {
  required String fallback,
}) {
  if (error is! DioException || error.response?.data == null) {
    return fallback;
  }

  final response = error.response!.data;
  if (response is Map<String, dynamic> &&
      response['message'] is String &&
      (response['message'] as String).isNotEmpty) {
    return response['message'] as String;
  }

  return fallback;
}

/// 예약 시도 실패를 사용자에게 보여줄 문구로 변환합니다.
///
/// 사전 조회 단계에서 이미 예약/사용 중으로 확인된 경우는 별도 안내로,
/// 그 외에는 서버 메시지(없으면 기본 문구)를 사용합니다.
String reserveFailureMessage(Object? error) {
  if (error is ReservationPenaltyException) {
    final remaining = error.expiresAt.difference(DateTime.now());
    final minutes = remaining.inMinutes;
    return minutes >= 1
        ? '예약이 제한된 상태입니다. 약 $minutes분 후 다시 시도해주세요.'
        : '예약이 제한된 상태입니다. 잠시 후 다시 시도해주세요.';
  }
  if (error is AlreadyReservedException) {
    return '이미 예약된 기기입니다.';
  }
  return '예약 실패: ${reservationActionErrorMessage(error, fallback: '예약에 실패했습니다. 다시 시도해주세요.')}';
}

final reservationActionProvider =
    AsyncNotifierProvider<ReservationActionNotifier, ActiveReservationModel?>(
      ReservationActionNotifier.new,
    );
