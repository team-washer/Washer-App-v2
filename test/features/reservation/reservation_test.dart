import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/enums/machine_state.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_status_remote_data_source.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/local/laundry_machine_model.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_remote_data_source.dart';
import 'package:washer/features/reservation/data/models/remote/confirm_reservation_response.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_action_provider.dart';

class FakeReservationRemoteDataSource implements ReservationRemoteDataSource {
  FakeReservationRemoteDataSource({
    this.createdReservation = _reservedReservation,
    this.cancelError,
  });

  final ActiveReservationModel createdReservation;
  final Object? cancelError;
  int? lastMachineId;
  String? lastStartTime;
  int? cancelledId;

  @override
  Future<ActiveReservationModel> createReservation({
    required int machineId,
    required String startTime,
  }) async {
    lastMachineId = machineId;
    lastStartTime = startTime;
    return createdReservation;
  }

  @override
  Future<void> cancelReservation({required int id}) async {
    cancelledId = id;
    final nextError = cancelError;
    if (nextError != null) {
      throw nextError;
    }
  }

  @override
  Future<ConfirmReservationResponse> confirmReservation({
    required int id,
  }) async {
    return const ConfirmReservationResponse(
      status: 'success',
      code: 200,
      message: '확정되었습니다.',
    );
  }
}

const _reservedReservation = ActiveReservationModel(
  id: 114,
  userId: 15,
  userName: '이주언',
  userRoomNumber: '420',
  userStudentId: '3413',
  machineId: 83,
  machineName: 'Washer-4F-L1',
  reservedAt: '2026-04-09T15:28:44.436305512',
  expectedCompletionTime: null,
  status: 'RESERVED',
);

class FakeHomeRemoteDataSource implements HomeRemoteDataSource {
  FakeHomeRemoteDataSource({
    required this.machineStatusLoader,
    this.activeReservationsLoader,
  });

  final Future<MachineStatusResponse> Function() machineStatusLoader;
  final Future<List<ActiveReservationModel>> Function()?
  activeReservationsLoader;

  @override
  Future<List<ActiveReservationModel>> getActiveReservations() {
    return activeReservationsLoader?.call() ?? Future.value(const []);
  }

  @override
  Future<MachineStatusResponse> getMachineStatus() {
    return machineStatusLoader();
  }
}

void main() {
  group('MachineModel placement', () {
    test('parses floor side and number from machine name', () {
      const model = MachineModel(
        machineId: 1,
        name: 'Washer-3F-L1',
        type: 'WASHER',
        status: 'NORMAL',
        availability: 'AVAILABLE',
      );

      expect(model.placement, isNotNull);
      expect(model.placement!.floor, '3F');
      expect(model.placement!.side, MachineSide.left);
      expect(model.placement!.number, 1);
      expect(model.floorNumber, 3);
    });

    test('returns null placement for unexpected name', () {
      const model = MachineModel(
        machineId: 1,
        name: 'Laundry Room A',
        type: 'WASHER',
        status: 'NORMAL',
        availability: 'AVAILABLE',
      );

      expect(model.placement, isNull);
      expect(model.floorNumber, isNull);
    });
  });

  group('MachineModel state helpers', () {
    test('treats reserved machine as unavailable for use', () {
      const model = MachineModel(
        machineId: 1,
        name: 'Washer-3F-L1',
        type: 'WASHER',
        status: 'NORMAL',
        availability: 'RESERVED',
        reservationId: 100,
      );

      expect(model.hasReservation, isTrue);
      expect(model.isAvailable, isFalse);
      expect(model.isReserved, isTrue);
      expect(model.isInUse, isFalse);
    });

    test('treats running machine as in use', () {
      const model = MachineModel(
        machineId: 1,
        name: 'Dryer-4F-R2',
        type: 'DRYER',
        status: 'NORMAL',
        availability: 'UNAVAILABLE',
        operatingState: 'RUN',
      );

      expect(model.machineState, MachineState.run);
      expect(model.isUnavailable, isFalse);
      expect(model.isAvailable, isFalse);
      expect(model.isInUse, isTrue);
    });

    test('treats finished machine as not in use', () {
      const model = MachineModel(
        machineId: 1,
        name: 'Dryer-4F-R2',
        type: 'DRYER',
        status: 'NORMAL',
        availability: 'UNAVAILABLE',
        operatingState: 'FINISHED',
      );

      expect(model.machineState, MachineState.finished);
      expect(model.isInUse, isFalse);
    });

    test(
      'treats unavailable status as not in use even without operating state',
      () {
        const model = MachineModel(
          machineId: 1,
          name: 'Dryer-4F-R2',
          type: 'DRYER',
          status: 'ERROR',
          availability: 'UNAVAILABLE',
        );

        expect(model.isUnavailable, isTrue);
        expect(model.isInUse, isFalse);
      },
    );
  });

  group('machineStatusProvider', () {
    test('loads machine status successfully', () async {
      final response = MachineStatusResponse(
        machines: const [
          MachineModel(
            machineId: 1,
            name: 'Washer-3F-L1',
            type: 'WASHER',
            status: 'NORMAL',
            availability: 'AVAILABLE',
          ),
        ],
        totalCount: 1,
      );

      final container = ProviderContainer(
        overrides: [
          homeRemoteDataSourceProvider.overrideWith(
            (ref) => FakeHomeRemoteDataSource(
              machineStatusLoader: () async => response,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(machineStatusProvider.future);

      expect(result, response);
      expect(container.read(pollingErrorProvider), isNull);
    });

    test('stores polling error message when server is unavailable', () async {
      final error = DioException(
        requestOptions: RequestOptions(path: '/machines'),
        type: DioExceptionType.connectionError,
        error: const SocketException('Connection refused'),
      );

      final container = ProviderContainer(
        overrides: [
          homeRemoteDataSourceProvider.overrideWith(
            (ref) => FakeHomeRemoteDataSource(
              machineStatusLoader: () =>
                  Future<MachineStatusResponse>.error(error),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final errorState = Completer<AsyncValue<MachineStatusResponse>>();
      final subscription = container.listen<AsyncValue<MachineStatusResponse>>(
        machineStatusProvider,
        (_, next) {
          if (next.hasError && !errorState.isCompleted) {
            errorState.complete(next);
          }
        },
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      final state = await errorState.future.timeout(const Duration(seconds: 5));

      expect(state.error, isA<DioException>());
      expect(
        container.read(pollingErrorProvider),
        '서버 연결이 거부되었습니다. 서버 상태를 확인해주세요.',
      );
    });

    test('refresh replaces state with latest machine status', () async {
      var callCount = 0;
      final firstResponse = MachineStatusResponse(
        machines: const [
          MachineModel(
            machineId: 1,
            name: 'Washer-3F-L1',
            type: 'WASHER',
            status: 'NORMAL',
            availability: 'AVAILABLE',
          ),
        ],
        totalCount: 1,
      );
      final secondResponse = MachineStatusResponse(
        machines: const [
          MachineModel(
            machineId: 2,
            name: 'Dryer-3F-R1',
            type: 'DRYER',
            status: 'NORMAL',
            availability: 'UNAVAILABLE',
          ),
        ],
        totalCount: 1,
      );

      final container = ProviderContainer(
        overrides: [
          homeRemoteDataSourceProvider.overrideWith(
            (ref) => FakeHomeRemoteDataSource(
              machineStatusLoader: () async {
                callCount += 1;
                return callCount == 1 ? firstResponse : secondResponse;
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(machineStatusProvider.future);
      await container.read(machineStatusProvider.notifier).refresh();

      expect(container.read(machineStatusProvider).value, secondResponse);
    });
  });

  group('ReservationActionNotifier', () {
    test('예약 성공 시 생성된 예약을 상태에 담고 상태 데이터를 갱신한다', () async {
      final reservationDataSource = FakeReservationRemoteDataSource();
      final container = ProviderContainer(
        overrides: [
          reservationRemoteDataSourceProvider.overrideWith(
            (ref) => reservationDataSource,
          ),
          homeRemoteDataSourceProvider.overrideWith(
            (ref) => FakeHomeRemoteDataSource(
              machineStatusLoader: () async =>
                  const MachineStatusResponse(machines: [], totalCount: 0),
              activeReservationsLoader: () async => const [
                _reservedReservation,
              ],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(reservationActionProvider.notifier)
          .reserve(machineId: 83);

      expect(reservationDataSource.lastMachineId, 83);
      expect(reservationDataSource.lastStartTime, isNotNull);
      expect(result, _reservedReservation);
      expect(container.read(activeReservationProvider).value, const [
        _reservedReservation,
      ]);
    });

    test('예약 취소 실패 시 서버 메시지를 상태에 담는다', () async {
      final error = DioException(
        requestOptions: RequestOptions(path: '/reservations/114'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/reservations/114'),
          data: {'message': '예약 취소 시간이 지났습니다.'},
        ),
      );
      final reservationDataSource = FakeReservationRemoteDataSource(
        cancelError: error,
      );
      final container = ProviderContainer(
        overrides: [
          reservationRemoteDataSourceProvider.overrideWith(
            (ref) => reservationDataSource,
          ),
          homeRemoteDataSourceProvider.overrideWith(
            (ref) => FakeHomeRemoteDataSource(
              machineStatusLoader: () async =>
                  const MachineStatusResponse(machines: [], totalCount: 0),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(reservationActionProvider.notifier)
          .cancel(reservationId: 114);

      expect(reservationDataSource.cancelledId, 114);
      expect(result, isFalse);
      expect(
        reservationActionErrorMessage(
          container.read(reservationActionProvider).error,
          fallback: '예약 취소에 실패했습니다.',
        ),
        '예약 취소 시간이 지났습니다.',
      );
    });
  });
}
