import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_remote_data_source.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_status_remote_data_source.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_sync_controller.dart';

/// 예약 요청 직전 GET으로 확인한 결과, 이미 예약/사용 중이라 예약할 수 없는 경우.
class AlreadyReservedException implements Exception {
  const AlreadyReservedException();
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
    state = const AsyncLoading();

    try {
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
String reserveFailureMessage(Object? error) => error is AlreadyReservedException
    ? '이미 예약된 기기입니다.'
    : '예약 실패: ${reservationActionErrorMessage(error, fallback: '예약에 실패했습니다. 다시 시도해주세요.')}';

final reservationActionProvider =
    AsyncNotifierProvider<ReservationActionNotifier, ActiveReservationModel?>(
      ReservationActionNotifier.new,
    );
