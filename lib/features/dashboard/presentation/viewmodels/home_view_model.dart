import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:washer/core/notifications/notification_service.dart';
import 'package:washer/features/dashboard/data/repositories/home_repository.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/local/laundry_machine_model.dart';

final clockProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

final pollingErrorProvider = StateProvider<String?>((ref) => null);

String? _pollingErrorMessageFor(DioException error) {
  final statusCode = error.response?.statusCode;
  if (statusCode != null && statusCode >= 500) {
    return '서버 오류가 발생했습니다. ($statusCode)';
  }

  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout) {
    return '서버 응답 시간이 초과되었습니다.';
  }

  if (error.type == DioExceptionType.connectionError) {
    final rawError = error.error;
    if (rawError is SocketException) {
      if (rawError.message.contains('Connection refused')) {
        return '서버 연결이 거부되었습니다. 서버 상태를 확인해주세요.';
      }
      return '네트워크 연결에 실패했습니다. 인터넷 또는 서버 상태를 확인해주세요.';
    }

    return '네트워크 연결에 실패했습니다.';
  }

  if (error.response == null) {
    return '네트워크 오류가 발생했습니다.';
  }

  return null;
}

final machineStatusProvider =
    AsyncNotifierProvider<MachineStatusNotifier, MachineStatusResponse>(
      MachineStatusNotifier.new,
    );

class MachineStatusNotifier extends AsyncNotifier<MachineStatusResponse> {
  @override
  Future<MachineStatusResponse> build() async {
    ref.keepAlive();
    try {
      return await ref.read(homeRepositoryProvider).getMachineStatus();
    } on DioException catch (e) {
      final message = _pollingErrorMessageFor(e);
      if (message != null) {
        ref.read(pollingErrorProvider.notifier).state = message;
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final machineStatus = await ref
          .read(homeRepositoryProvider)
          .getMachineStatus();
      state = AsyncData(machineStatus);
    } on DioException catch (e, st) {
      final message = _pollingErrorMessageFor(e);
      if (message != null) {
        ref.read(pollingErrorProvider.notifier).state = message;
      }
      state = AsyncError(e, st);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final activeReservationProvider =
    AsyncNotifierProvider<
      ActiveReservationNotifier,
      List<ActiveReservationModel>
    >(
      ActiveReservationNotifier.new,
    );

class ActiveReservationNotifier
    extends AsyncNotifier<List<ActiveReservationModel>> {
  bool _hasFetched = false;

  @override
  Future<List<ActiveReservationModel>> build() async {
    ref.keepAlive();
    try {
      _hasFetched = true;
      final reservations = await ref
          .read(homeRepositoryProvider)
          .getActiveReservations();
      unawaited(
        _syncReservationNotification(_notificationTarget(reservations)),
      );
      return reservations;
    } on DioException catch (e) {
      final message = _pollingErrorMessageFor(e);
      if (message != null) {
        ref.read(pollingErrorProvider.notifier).state = message;
      }
      rethrow;
    }
  }

  Future<void> ensureLoaded() async {
    if (_hasFetched || state.isLoading) {
      return;
    }

    await refresh();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      _hasFetched = true;
      final reservations = await ref
          .read(homeRepositoryProvider)
          .getActiveReservations();
      await _syncReservationNotification(
        _notificationTarget(reservations),
      );
      state = AsyncData(reservations);
    } on DioException catch (e, st) {
      final message = _pollingErrorMessageFor(e);
      if (message != null) {
        ref.read(pollingErrorProvider.notifier).state = message;
      }
      state = AsyncError(e, st);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void setReservations(List<ActiveReservationModel> reservations) {
    _hasFetched = true;
    state = AsyncData(reservations);
    unawaited(
      _syncReservationNotification(_notificationTarget(reservations)),
    );
  }

  ActiveReservationModel? _notificationTarget(
    List<ActiveReservationModel> reservations,
  ) {
    if (reservations.isEmpty) {
      return null;
    }

    return reservations.first;
  }

  Future<void> _syncReservationNotification(
    ActiveReservationModel? reservation,
  ) {
    return ref
        .read(notificationServiceProvider)
        .syncReservationCompletionNotification(reservation);
  }
}
