import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_remote_data_source.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_sync_controller.dart';

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

final reservationActionProvider =
    AsyncNotifierProvider<ReservationActionNotifier, ActiveReservationModel?>(
      ReservationActionNotifier.new,
    );
