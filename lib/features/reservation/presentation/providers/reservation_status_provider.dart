import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/local/laundry_machine_model.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_status_remote_data_source.dart';

final clockProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

final pollingErrorProvider = StateProvider<String?>((ref) => null);

Future<void> refreshReservationStatusProviders(Ref ref) {
  return Future.wait([
    ref.read(machineStatusProvider.notifier).refresh(),
    ref.read(activeReservationProvider.notifier).refresh(),
  ]);
}

Future<void> refreshReservationStatusWidgets(WidgetRef ref) {
  return Future.wait([
    ref.read(machineStatusProvider.notifier).refresh(),
    ref.read(activeReservationProvider.notifier).refresh(),
  ]);
}

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
      return await ref.read(homeRemoteDataSourceProvider).getMachineStatus();
    } on DioException catch (e, st) {
      AppLogger.error(
        '기기 상태를 불러오는 중 오류가 발생했습니다.',
        name: 'MachineStatusNotifier',
        error: e,
        stackTrace: st,
      );
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
          .read(homeRemoteDataSourceProvider)
          .getMachineStatus();
      state = AsyncData(machineStatus);
    } on DioException catch (e, st) {
      AppLogger.error(
        '기기 상태를 새로고침하는 중 오류가 발생했습니다.',
        name: 'MachineStatusNotifier',
        error: e,
        stackTrace: st,
      );
      final message = _pollingErrorMessageFor(e);
      if (message != null) {
        ref.read(pollingErrorProvider.notifier).state = message;
      }
      state = AsyncError(e, st);
    } catch (e, st) {
      AppLogger.error(
        '기기 상태를 새로고침하는 중 오류가 발생했습니다.',
        name: 'MachineStatusNotifier',
        error: e,
        stackTrace: st,
      );
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
      return await ref
          .read(homeRemoteDataSourceProvider)
          .getActiveReservations();
    } on DioException catch (e, st) {
      AppLogger.error(
        '활성 예약을 불러오는 중 오류가 발생했습니다.',
        name: 'ActiveReservationNotifier',
        error: e,
        stackTrace: st,
      );
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
          .read(homeRemoteDataSourceProvider)
          .getActiveReservations();
      state = AsyncData(reservations);
    } on DioException catch (e, st) {
      AppLogger.error(
        '활성 예약을 새로고침하는 중 오류가 발생했습니다.',
        name: 'ActiveReservationNotifier',
        error: e,
        stackTrace: st,
      );
      final message = _pollingErrorMessageFor(e);
      if (message != null) {
        ref.read(pollingErrorProvider.notifier).state = message;
      }
      state = AsyncError(e, st);
    } catch (e, st) {
      AppLogger.error(
        '활성 예약을 새로고침하는 중 오류가 발생했습니다.',
        name: 'ActiveReservationNotifier',
        error: e,
        stackTrace: st,
      );
      state = AsyncError(e, st);
    }
  }

  void setReservations(List<ActiveReservationModel> reservations) {
    _hasFetched = true;
    state = AsyncData(reservations);
  }
}
