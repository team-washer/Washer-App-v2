import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/enums/machine_state.dart';
import 'package:washer/core/utils/date_time_formatter.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_status_remote_data_source.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/local/laundry_machine_model.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_remote_data_source.dart';
import 'package:washer/features/reservation/data/models/remote/cancel_reservation_response.dart';
import 'package:washer/features/reservation/data/models/remote/confirm_reservation_response.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_action_provider.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_penalty_provider.dart';

class FakeReservationRemoteDataSource implements ReservationRemoteDataSource {
  FakeReservationRemoteDataSource({
    this.createdReservation = _reservedReservation,
    this.createdReservationBuilder,
    this.cancelError,
    this.cancelResponse = _noPenaltyCancel,
  });

  final ActiveReservationModel createdReservation;

  /// machineId 별로 다른 예약을 돌려줘야 하는 테스트용.
  final ActiveReservationModel Function(int machineId)?
  createdReservationBuilder;
  final Object? cancelError;
  final CancelReservationResponse cancelResponse;
  int? lastMachineId;
  String? lastStartTime;
  int? cancelledId;
  final List<int> createdMachineIds = [];
  final List<int> cancelledIds = [];

  @override
  Future<ActiveReservationModel> createReservation({
    required int machineId,
    required String startTime,
  }) async {
    lastMachineId = machineId;
    lastStartTime = startTime;
    createdMachineIds.add(machineId);
    return createdReservationBuilder?.call(machineId) ?? createdReservation;
  }

  @override
  Future<CancelReservationResponse> cancelReservation({required int id}) async {
    cancelledId = id;
    cancelledIds.add(id);
    final nextError = cancelError;
    if (nextError != null) {
      throw nextError;
    }
    return cancelResponse;
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

const _noPenaltyCancel = CancelReservationResponse(
  success: true,
  message: '예약이 취소되었습니다.',
  penaltyApplied: false,
  penaltyExpiresAt: '',
);

/// 예약 패널티 상태를 storage 없이 메모리로만 다루는 테스트용 notifier.
class FakeReservationPenaltyNotifier extends ReservationPenaltyNotifier {
  FakeReservationPenaltyNotifier([this.initialExpiry]);

  final DateTime? initialExpiry;
  DateTime? recorded;

  @override
  DateTime? build() => initialExpiry;

  @override
  void record(DateTime expiresAt) {
    recorded = expiresAt;
    state = expiresAt;
  }

  @override
  void clear() {
    state = null;
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

    test('server UNAVAILABLE stays in use even if SmartThings reports finished', () {
      // #228: 운전중 판정은 서버 availability가 기준. operatingState는 판정에 쓰지 않는다.
      const model = MachineModel(
        machineId: 1,
        name: 'Dryer-4F-R2',
        type: 'DRYER',
        status: 'NORMAL',
        availability: 'UNAVAILABLE',
        operatingState: 'FINISHED',
      );

      expect(model.isInUse, isTrue);
      expect(model.isAvailable, isFalse);
    });

    test('server AVAILABLE is reservable even if SmartThings reports running', () {
      // #228: availability가 AVAILABLE이면 예약 가능. operatingState는 무시한다.
      const model = MachineModel(
        machineId: 1,
        name: 'Washer-3F-L1',
        type: 'WASHER',
        status: 'NORMAL',
        availability: 'AVAILABLE',
        operatingState: 'RUN',
      );

      expect(model.isInUse, isFalse);
      expect(model.isReserved, isFalse);
      expect(model.isAvailable, isTrue);
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
          reservationPenaltyProvider.overrideWith(
            FakeReservationPenaltyNotifier.new,
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

    test('#261: 다른 기기를 연달아 누르면 각각 별도 요청이 나간다', () async {
      final reservationDataSource = FakeReservationRemoteDataSource(
        createdReservationBuilder: (machineId) =>
            _reservedReservation.copyWith(machineId: machineId),
      );
      final container = ProviderContainer(
        overrides: [
          reservationRemoteDataSourceProvider.overrideWith(
            (ref) => reservationDataSource,
          ),
          reservationPenaltyProvider.overrideWith(
            FakeReservationPenaltyNotifier.new,
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

      final notifier = container.read(reservationActionProvider.notifier);
      // 83 이 아직 진행 중인 상태에서 84 를 누른다.
      final first = notifier.reserve(machineId: 83);
      final second = notifier.reserve(machineId: 84);
      final results = await Future.wait([first, second]);

      expect(reservationDataSource.createdMachineIds, [83, 84]);
      expect(results[0]?.machineId, 83);
      // 키가 없으면 84 호출이 83 의 결과를 그대로 받아 성공으로 처리된다.
      expect(results[1]?.machineId, 84);
    });

    test('#261: 같은 기기를 연달아 누르면 요청은 한 번만 나간다', () async {
      final reservationDataSource = FakeReservationRemoteDataSource();
      final container = ProviderContainer(
        overrides: [
          reservationRemoteDataSourceProvider.overrideWith(
            (ref) => reservationDataSource,
          ),
          reservationPenaltyProvider.overrideWith(
            FakeReservationPenaltyNotifier.new,
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

      final notifier = container.read(reservationActionProvider.notifier);
      final results = await Future.wait([
        notifier.reserve(machineId: 83),
        notifier.reserve(machineId: 83),
      ]);

      expect(reservationDataSource.createdMachineIds, [83]);
      expect(results[0], results[1]);
    });

    test('#261: 다른 예약을 연달아 취소하면 각각 별도 요청이 나간다', () async {
      final reservationDataSource = FakeReservationRemoteDataSource();
      final container = ProviderContainer(
        overrides: [
          reservationRemoteDataSourceProvider.overrideWith(
            (ref) => reservationDataSource,
          ),
          reservationPenaltyProvider.overrideWith(
            FakeReservationPenaltyNotifier.new,
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

      final notifier = container.read(reservationActionProvider.notifier);
      await Future.wait([
        notifier.cancel(reservationId: 114),
        notifier.cancel(reservationId: 115),
      ]);

      expect(reservationDataSource.cancelledIds, [114, 115]);
    });

    test('예약 전 조회 결과 이미 예약된 기기면 요청을 보내지 않고 예외를 담는다', () async {
      final reservationDataSource = FakeReservationRemoteDataSource();
      final container = ProviderContainer(
        overrides: [
          reservationRemoteDataSourceProvider.overrideWith(
            (ref) => reservationDataSource,
          ),
          reservationPenaltyProvider.overrideWith(
            FakeReservationPenaltyNotifier.new,
          ),
          homeRemoteDataSourceProvider.overrideWith(
            (ref) => FakeHomeRemoteDataSource(
              machineStatusLoader: () async => const MachineStatusResponse(
                machines: [
                  MachineModel(
                    machineId: 83,
                    name: 'Washer-4F-L1',
                    type: 'WASHER',
                    status: 'NORMAL',
                    availability: 'RESERVED',
                    reservationId: 114,
                  ),
                ],
                totalCount: 1,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(reservationActionProvider.notifier)
          .reserve(machineId: 83);

      expect(result, isNull);
      expect(reservationDataSource.lastMachineId, isNull);
      expect(
        container.read(reservationActionProvider).error,
        isA<AlreadyReservedException>(),
      );
    });

    test('#256: 첫 조회에서만 사용중으로 보이면 재확인 후 예약을 진행한다', () async {
      var callCount = 0;
      const reservedResponse = MachineStatusResponse(
        machines: [
          MachineModel(
            machineId: 83,
            name: 'Washer-4F-L1',
            type: 'WASHER',
            status: 'NORMAL',
            availability: 'RESERVED',
            reservationId: 114,
          ),
        ],
        totalCount: 1,
      );
      const availableResponse = MachineStatusResponse(
        machines: [
          MachineModel(
            machineId: 83,
            name: 'Washer-4F-L1',
            type: 'WASHER',
            status: 'NORMAL',
            availability: 'AVAILABLE',
          ),
        ],
        totalCount: 1,
      );
      final reservationDataSource = FakeReservationRemoteDataSource();
      final container = ProviderContainer(
        overrides: [
          reservationRemoteDataSourceProvider.overrideWith(
            (ref) => reservationDataSource,
          ),
          reservationPenaltyProvider.overrideWith(
            FakeReservationPenaltyNotifier.new,
          ),
          homeRemoteDataSourceProvider.overrideWith(
            (ref) => FakeHomeRemoteDataSource(
              // 첫 조회는 사용중, 그 이후로는 계속 사용 가능으로 응답한다.
              // (재확인 이후 refreshReservationStatusProviders가 추가로 상태를 조회한다)
              machineStatusLoader: () async {
                callCount += 1;
                return callCount == 1 ? reservedResponse : availableResponse;
              },
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

      expect(callCount, greaterThanOrEqualTo(2));
      expect(reservationDataSource.lastMachineId, 83);
      expect(result, _reservedReservation);
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
          reservationPenaltyProvider.overrideWith(
            FakeReservationPenaltyNotifier.new,
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

    test('취소 패널티 기간이면 요청을 보내지 않고 예외를 담는다', () async {
      final reservationDataSource = FakeReservationRemoteDataSource();
      final expiry = DateTime.now().add(const Duration(minutes: 5));
      final container = ProviderContainer(
        overrides: [
          reservationRemoteDataSourceProvider.overrideWith(
            (ref) => reservationDataSource,
          ),
          reservationPenaltyProvider.overrideWith(
            () => FakeReservationPenaltyNotifier(expiry),
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
          .reserve(machineId: 83);

      expect(result, isNull);
      // 서버 조회(GET)·예약(POST) 요청이 나가지 않아야 한다.
      expect(reservationDataSource.lastMachineId, isNull);
      expect(
        container.read(reservationActionProvider).error,
        isA<ReservationPenaltyException>(),
      );
    });

    test('취소 시 패널티가 부과되면 만료시각을 로컬에 기록한다', () async {
      final reservationDataSource = FakeReservationRemoteDataSource(
        cancelResponse: const CancelReservationResponse(
          success: true,
          message: '취소되었으나 패널티가 부과되었습니다.',
          penaltyApplied: true,
          penaltyExpiresAt: '2999-01-01T00:00:00',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          reservationRemoteDataSourceProvider.overrideWith(
            (ref) => reservationDataSource,
          ),
          reservationPenaltyProvider.overrideWith(
            FakeReservationPenaltyNotifier.new,
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

      expect(result, isTrue);
      expect(
        container.read(reservationPenaltyProvider),
        DateTimeFormatter.parseServerDateTime('2999-01-01T00:00:00'),
      );
    });
  });
}
