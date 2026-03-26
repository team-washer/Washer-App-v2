import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/enums/laundry_status.dart';
import 'package:washer/features/home/data/repositories/home_repository.dart';
import 'package:washer/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/repositories/reservation_repository.dart';

enum ReservationActionStatus { idle, loading, success, error }

class ReservationActionState {
  const ReservationActionState({
    this.status = ReservationActionStatus.idle,
    this.errorMessage,
    this.reservation,
  });

  final ReservationActionStatus status;
  final String? errorMessage;
  final ActiveReservationModel? reservation;
}

class ReservationViewModel extends Notifier<ReservationActionState> {
  static const Duration _reservationPollingInterval = Duration(seconds: 10);
  static const Duration _reservationPollingDuration = Duration(minutes: 3);
  static const Duration _finalSyncDelay = Duration(seconds: 1);

  Timer? _pollingTimer;
  Timer? _expiryTimer;
  Future<ReservationActionState>? _reserveRequest;
  Future<ReservationActionState>? _cancelRequest;

  @override
  ReservationActionState build() => const ReservationActionState();

  Future<ReservationActionState> reserve({required int machineId}) async {
    return _runSingleFlight(
      currentRequest: _reserveRequest,
      setRequest: (request) => _reserveRequest = request,
      action: () => _reserveInternal(machineId: machineId),
    );
  }

  Future<ReservationActionState> _reserveInternal({
    required int machineId,
  }) async {
    state = const ReservationActionState(
      status: ReservationActionStatus.loading,
    );

    try {
      final startTime = DateTime.now().toIso8601String();

      final createdReservation = await ref
          .read(reservationRepositoryProvider)
          .createReservation(
            machineId: machineId,
            startTime: startTime,
          );

      await _refreshReservationData();

      final nextState = ReservationActionState(
        status: ReservationActionStatus.success,
        reservation: createdReservation,
      );
      state = nextState;
      _startPollingReservation();
      return nextState;
    } catch (e) {
      var errorMessage = '예약에 실패했습니다. 다시 시도해주세요.';
      if (e is DioException && e.response?.data != null) {
        final response = e.response!.data;
        if (response is Map<String, dynamic> &&
            response.containsKey('message')) {
          errorMessage = response['message'] as String;
        }
      }

      final nextState = ReservationActionState(
        status: ReservationActionStatus.error,
        errorMessage: errorMessage,
      );
      state = nextState;
      return nextState;
    }
  }

  Future<ReservationActionState> cancel({required int reservationId}) async {
    return _runSingleFlight(
      currentRequest: _cancelRequest,
      setRequest: (request) => _cancelRequest = request,
      action: () => _cancelInternal(reservationId: reservationId),
    );
  }

  Future<ReservationActionState> _cancelInternal({
    required int reservationId,
  }) async {
    state = const ReservationActionState(
      status: ReservationActionStatus.loading,
    );

    try {
      _stopPolling();

      await ref
          .read(reservationRepositoryProvider)
          .cancelReservation(id: reservationId);

      await _refreshReservationData();

      const nextState = ReservationActionState(
        status: ReservationActionStatus.success,
      );
      state = nextState;
      return nextState;
    } catch (e) {
      var errorMessage = '예약 취소에 실패했습니다.';
      if (e is DioException && e.response?.data != null) {
        final response = e.response!.data;
        if (response is Map<String, dynamic> &&
            response.containsKey('message')) {
          errorMessage = response['message'] as String;
        }
      }

      final nextState = ReservationActionState(
        status: ReservationActionStatus.error,
        errorMessage: errorMessage,
      );
      state = nextState;
      return nextState;
    }
  }

  Future<void> _refreshReservationData() async {
    await ref.read(activeReservationProvider.notifier).refresh();
    await ref.read(machineStatusProvider.notifier).refresh();
  }

  void reset() {
    state = const ReservationActionState();
    _stopPolling();
  }

  void _startPollingReservation() {
    _stopPolling();

    _pollingTimer = Timer.periodic(_reservationPollingInterval, (_) {
      unawaited(_syncActiveReservation());
    });

    _expiryTimer = Timer(
      _reservationPollingDuration + _finalSyncDelay,
      () {
        _stopPolling();
        unawaited(_syncActiveReservation(forceMachineRefresh: true));
      },
    );
  }

  Future<void> _syncActiveReservation({
    bool forceMachineRefresh = false,
  }) async {
    try {
      final current = ref
          .read(activeReservationProvider)
          .maybeWhen(
            data: (value) => value,
            orElse: () => const <ActiveReservationModel>[],
          );

      final latest = await ref
          .read(homeRepositoryProvider)
          .getActiveReservations();
      if (latest.isEmpty) {
        _stopPolling();

        if (current.isNotEmpty) {
          ref
              .read(activeReservationProvider.notifier)
              .setReservations(
                const <ActiveReservationModel>[],
              );
        }

        if (current.isNotEmpty || forceMachineRefresh) {
          await ref.read(machineStatusProvider.notifier).refresh();
        }
        return;
      }

      final hasPendingReservation = latest.any(
        (reservation) => reservation.laundryStatus == LaundryStatus.reserved,
      );
      if (!hasPendingReservation) {
        _stopPolling();
      }

      final hasChanged = !_sameReservations(current, latest);

      if (hasChanged) {
        ref.read(activeReservationProvider.notifier).setReservations(latest);
      }

      if (hasChanged || forceMachineRefresh) {
        await ref.read(machineStatusProvider.notifier).refresh();
      }
    } catch (_) {}
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _expiryTimer?.cancel();
    _pollingTimer = null;
    _expiryTimer = null;
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

  Future<ReservationActionState> _runSingleFlight({
    required Future<ReservationActionState>? currentRequest,
    required void Function(Future<ReservationActionState>? request) setRequest,
    required Future<ReservationActionState> Function() action,
  }) {
    if (currentRequest != null) {
      return currentRequest;
    }

    final request = action();
    setRequest(request);
    request.whenComplete(() {
      if (identical(currentRequest, request)) {
        return;
      }

      setRequest(null);
    });
    return request;
  }
}

final reservationViewModelProvider =
    NotifierProvider<ReservationViewModel, ReservationActionState>(
      ReservationViewModel.new,
    );
