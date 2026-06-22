import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/enums/machine_state.dart';
import 'package:washer/features/reservation/data/data_sources/remote/smartthings_machine_status_overlay.dart';
import 'package:washer/features/reservation/data/data_sources/remote/smartthings_status_remote_data_source.dart';
import 'package:washer/features/reservation/data/data_sources/remote/smartthings_token_remote_data_source.dart';
import 'package:washer/features/reservation/data/models/local/laundry_machine_model.dart';
import 'package:washer/features/reservation/data/models/remote/smartthings_device_status.dart';
import 'package:washer/features/reservation/data/models/remote/smartthings_token_model.dart';

class _FakeTokenDataSource implements SmartThingsTokenRemoteDataSource {
  int callCount = 0;

  @override
  Future<SmartThingsTokenModel> getToken() async {
    callCount += 1;
    return SmartThingsTokenModel(accessToken: 'token-$callCount');
  }
}

class _FakeStatusDataSource implements SmartThingsStatusRemoteDataSource {
  _FakeStatusDataSource(this.byDeviceId);

  final Map<String, SmartThingsDeviceStatus> byDeviceId;
  final List<String> requestedDeviceIds = [];

  @override
  Future<SmartThingsDeviceStatus> getDeviceStatus(
    String deviceId,
    String accessToken,
  ) async {
    requestedDeviceIds.add(deviceId);
    return byDeviceId[deviceId] ?? const SmartThingsDeviceStatus();
  }
}

void main() {
  group('SmartThingsDeviceStatus.fromJson', () {
    test('extracts washer operating state from components.main', () {
      final status = SmartThingsDeviceStatus.fromJson({
        'components': {
          'main': {
            'washerOperatingState': {
              'machineState': {'value': 'run'},
              'washerJobState': {'value': 'rinse'},
              'completionTime': {'value': '2026-06-22T13:50:18.364Z'},
            },
            'switch': {
              'switch': {'value': 'on'},
            },
          },
        },
      });

      expect(status.machineState, 'run');
      expect(status.jobState, 'rinse');
      expect(status.switchStatus, 'on');
      expect(status.completionTime, '2026-06-22T13:50:18.364Z');
      expect(status.isEmpty, isFalse);
    });

    test('returns empty status when capabilities are missing', () {
      final status = SmartThingsDeviceStatus.fromJson({
        'components': {'main': <String, dynamic>{}},
      });

      expect(status.isEmpty, isTrue);
    });
  });

  group('SmartThingsMachineStatusOverlay', () {
    ProviderContainer buildContainer({
      required SmartThingsTokenRemoteDataSource tokenDataSource,
      required SmartThingsStatusRemoteDataSource statusDataSource,
    }) {
      final container = ProviderContainer(
        overrides: [
          smartThingsTokenStoreProvider.overrideWithValue(
            SmartThingsTokenStore(tokenDataSource),
          ),
          smartThingsStatusRemoteDataSourceProvider.overrideWithValue(
            statusDataSource,
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('overlays operating state from SmartThings, keeps server fields', () async {
      final tokenDataSource = _FakeTokenDataSource();
      final statusDataSource = _FakeStatusDataSource({
        'device-1': const SmartThingsDeviceStatus(
          machineState: 'run',
          jobState: 'wash',
          switchStatus: 'on',
          completionTime: '2026-06-22T13:50:18.364Z',
        ),
      });
      final container = buildContainer(
        tokenDataSource: tokenDataSource,
        statusDataSource: statusDataSource,
      );

      const base = MachineStatusResponse(
        machines: [
          MachineModel(
            machineId: 1,
            name: 'Washer-3F-L1',
            type: 'WASHER',
            status: 'NORMAL',
            availability: 'RESERVED',
            reservationId: 99,
            smartThingsDeviceId: 'device-1',
          ),
        ],
        totalCount: 1,
      );

      final result = await container
          .read(smartThingsMachineStatusOverlayProvider)
          .apply(base);

      final machine = result.machines.single;
      // 운전 상태는 SmartThings 값으로 덮어쓴다.
      expect(machine.machineState, MachineState.wash);
      expect(machine.jobState, 'wash');
      expect(machine.switchStatus, 'on');
      expect(machine.expectedCompletionTime, '2026-06-22T13:50:18.364Z');
      // 예약/가용성 정보는 서버 값을 유지한다.
      expect(machine.availability, 'RESERVED');
      expect(machine.reservationId, 99);
      expect(statusDataSource.requestedDeviceIds, ['device-1']);
    });

    test('returns base untouched and skips network when no deviceId', () async {
      final tokenDataSource = _FakeTokenDataSource();
      final statusDataSource = _FakeStatusDataSource(const {});
      final container = buildContainer(
        tokenDataSource: tokenDataSource,
        statusDataSource: statusDataSource,
      );

      const base = MachineStatusResponse(
        machines: [
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

      final result = await container
          .read(smartThingsMachineStatusOverlayProvider)
          .apply(base);

      expect(result, base);
      expect(tokenDataSource.callCount, 0);
      expect(statusDataSource.requestedDeviceIds, isEmpty);
    });

    test('keeps server values when SmartThings returns empty status', () async {
      final tokenDataSource = _FakeTokenDataSource();
      final statusDataSource = _FakeStatusDataSource({
        'device-1': const SmartThingsDeviceStatus(),
      });
      final container = buildContainer(
        tokenDataSource: tokenDataSource,
        statusDataSource: statusDataSource,
      );

      const base = MachineStatusResponse(
        machines: [
          MachineModel(
            machineId: 1,
            name: 'Dryer-3F-R1',
            type: 'DRYER',
            status: 'NORMAL',
            availability: 'UNAVAILABLE',
            operatingState: 'RUN',
            smartThingsDeviceId: 'device-1',
          ),
        ],
        totalCount: 1,
      );

      final result = await container
          .read(smartThingsMachineStatusOverlayProvider)
          .apply(base);

      expect(result.machines.single.operatingState, 'RUN');
    });
  });
}
