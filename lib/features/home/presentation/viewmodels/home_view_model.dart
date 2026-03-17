import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:washer/core/notifications/notification_service.dart';
import 'package:washer/features/home/data/repositories/home_repository.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/local/laundry_machine_model.dart';

final clockProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

final pollingErrorProvider = StateProvider<String?>((ref) => null);

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
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode >= 500) {
        ref.read(pollingErrorProvider.notifier).state =
            '서버 오류가 발생했습니다. ($statusCode)';
      } else if (e.response == null) {
        ref.read(pollingErrorProvider.notifier).state = '네트워크 오류가 발생했습니다.';
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(homeRepositoryProvider).getMachineStatus(),
    );
  }
}

final activeReservationProvider =
    AsyncNotifierProvider<ActiveReservationNotifier, ActiveReservationModel?>(
      ActiveReservationNotifier.new,
    );

class ActiveReservationNotifier extends AsyncNotifier<ActiveReservationModel?> {
  @override
  Future<ActiveReservationModel?> build() async {
    ref.keepAlive();
    try {
      final reservation = await ref
          .read(homeRepositoryProvider)
          .getActiveReservation();
      await _syncReservationNotification(reservation);
      return reservation;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode >= 500) {
        ref.read(pollingErrorProvider.notifier).state =
            '서버 오류가 발생했습니다. ($statusCode)';
      } else if (e.response == null) {
        ref.read(pollingErrorProvider.notifier).state = '네트워크 오류가 발생했습니다.';
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final reservation = await ref
          .read(homeRepositoryProvider)
          .getActiveReservation();
      await _syncReservationNotification(reservation);
      return reservation;
    });
  }

  void setReservation(ActiveReservationModel? reservation) {
    state = AsyncData(reservation);
    unawaited(_syncReservationNotification(reservation));
  }

  Future<void> _syncReservationNotification(
    ActiveReservationModel? reservation,
  ) {
    return ref
        .read(notificationServiceProvider)
        .syncReservationCompletionNotification(reservation);
  }
}
