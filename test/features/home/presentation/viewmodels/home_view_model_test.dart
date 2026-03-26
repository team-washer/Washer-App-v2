import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/features/home/data/repositories/home_repository.dart';
import 'package:washer/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/local/laundry_machine_model.dart';

class FakeHomeRepository implements HomeRepository {
  FakeHomeRepository({
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
          homeRepositoryProvider.overrideWith(
            (ref) => FakeHomeRepository(
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
          homeRepositoryProvider.overrideWith(
            (ref) => FakeHomeRepository(
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
          homeRepositoryProvider.overrideWith(
            (ref) => FakeHomeRepository(
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
}
