import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_status_remote_data_source.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/local/machine_model.dart';
import 'package:washer/features/reservation/data/models/remote/reservation_availability_response.dart';
import 'package:washer/features/reservation/presentation/providers/my_reservation_update.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_sync_controller.dart';

/// 호실 목록 요청과 내 예약 polling 요청의 응답 시점을 테스트가 직접 제어하는 fake.
class _ControlledDataSource implements ReservationStatusRemoteDataSource {
  final roomRequests = <Completer<List<ActiveReservationModel>>>[];
  final mineRequests = <Completer<ActiveReservationModel?>>[];

  @override
  Future<List<ActiveReservationModel>> getActiveReservations() {
    final completer = Completer<List<ActiveReservationModel>>();
    roomRequests.add(completer);
    return completer.future;
  }

  @override
  Future<ActiveReservationModel?> getMyActiveReservation() {
    final completer = Completer<ActiveReservationModel?>();
    mineRequests.add(completer);
    return completer.future;
  }

  @override
  Future<MachineStatusResponse> getMachineStatus() async =>
      const MachineStatusResponse(machines: [], totalCount: 0);

  @override
  Future<ReservationAvailabilityResponse> getReservationAvailability() async =>
      const ReservationAvailabilityResponse();
}

ActiveReservationModel _reservation({
  required int id,
  required int userId,
  required String status,
}) {
  return ActiveReservationModel(
    id: id,
    userId: userId,
    userName: '사용자$userId',
    userRoomNumber: '420',
    machineId: id,
    machineName: 'Washer-4F-L1',
    status: status,
  );
}

final _mineReserved = _reservation(id: 114, userId: 15, status: 'RESERVED');
final _mineRunning = _reservation(id: 114, userId: 15, status: 'RUNNING');
final _roommate = _reservation(id: 200, userId: 16, status: 'RUNNING');

/// 다음 microtask까지 진행시켜, 대기 중인 요청이 시작될 기회를 준다.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _ControlledDataSource dataSource;
  late ProviderContainer container;
  late ReservationSyncController controller;

  setUp(() {
    dataSource = _ControlledDataSource();
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        reservationStatusRemoteDataSourceProvider.overrideWith(
          (ref) => dataSource,
        ),
      ],
    );
    controller = container.read(reservationSyncControllerProvider);
    addTearDown(() {
      controller.stopPolling();
      container.dispose();
    });
  });

  List<ActiveReservationModel> currentList() =>
      container.read(activeReservationProvider).value ?? const [];

  group('호실 목록 초기 요청과 polling이 겹칠 때', () {
    test('초기 요청이 polling보다 늦게 끝나도 내 예약의 최신 상태가 유지된다', () async {
      // 호실 목록 초기 요청 시작 (id 1). 아직 응답 전.
      final initial = container.read(activeReservationProvider.future);
      await _settle();
      controller.startPolling(reservationId: 114);

      // polling이 더 늦게 시작하고(id 2) 먼저 끝난다: 내 예약이 RUNNING으로 바뀜.
      final sync = controller.syncActiveReservation();
      await _settle();
      dataSource.mineRequests.single.complete(_mineRunning);
      await sync;

      // 그 뒤에 더 일찍 시작한 초기 요청이 오래된 스냅샷(RESERVED)으로 도착한다.
      dataSource.roomRequests.single.complete([_mineReserved, _roommate]);
      await initial;

      // 내 예약은 최신 polling 결과(RUNNING), 룸메이트는 스냅샷 값이 유지된다.
      expect(currentList(), [_mineRunning, _roommate]);
    });

    test('polling이 시작되기도 전에 끝난 초기 요청은 그대로 반영된다', () async {
      final initial = container.read(activeReservationProvider.future);
      await _settle();
      dataSource.roomRequests.single.complete([_mineReserved, _roommate]);
      await initial;

      expect(currentList(), [_mineReserved, _roommate]);
    });

    test('polling이 더 일찍 시작했어도 더 늦게 시작한 새로고침이 이기면 polling 응답은 버린다', () async {
      final notifier = container.read(activeReservationProvider.notifier);
      final initial = container.read(activeReservationProvider.future); // 요청 1
      await _settle();
      dataSource.roomRequests[0].complete([_mineReserved]);
      await initial;
      controller.startPolling(reservationId: 114);

      final sync = controller.syncActiveReservation(); // 요청 2 (polling이 먼저 시작)
      await _settle();
      final refresh = notifier.refresh(); // 요청 3 (더 늦게 시작)
      await _settle();

      // 더 늦게 시작한 새로고침이 먼저 끝나 RUNNING 스냅샷을 반영한다.
      dataSource.roomRequests[1].complete([_mineRunning, _roommate]);
      await refresh;
      // 더 일찍 시작한 polling의 오래된 응답(RESERVED)이 뒤늦게 도착해도 되돌리지 못한다.
      dataSource.mineRequests.single.complete(_mineReserved);
      await sync;

      expect(currentList(), [_mineRunning, _roommate]);
      expect(controller.isPolling, isTrue);
    });
  });

  group('polling 응답이 뒤바뀌어 도착할 때', () {
    Future<void> loadInitial(List<ActiveReservationModel> reservations) async {
      final initial = container.read(activeReservationProvider.future);
      await _settle();
      dataSource.roomRequests.single.complete(reservations);
      await initial;
    }

    test('오래된 응답이 나중에 도착해도 최신 결과를 덮지 않는다', () async {
      await loadInitial([_mineReserved]);
      controller.startPolling(reservationId: 114);

      final older = controller.syncActiveReservation(); // id 2
      final newer = controller.syncActiveReservation(); // id 3
      await _settle();

      // 더 늦게 시작한 요청이 먼저 끝나 RUNNING을 반영한다.
      dataSource.mineRequests[1].complete(_mineRunning);
      await newer;
      // 더 일찍 시작한 요청의 오래된 응답(RESERVED)이 뒤늦게 도착한다.
      dataSource.mineRequests[0].complete(_mineReserved);
      await older;

      expect(currentList(), [_mineRunning]);
      expect(controller.isPolling, isTrue);
    });

    test('오래된 null 응답은 최신 상태를 지우거나 polling을 끊지 않는다', () async {
      await loadInitial([_mineReserved, _roommate]);
      controller.startPolling(reservationId: 114);

      final older = controller.syncActiveReservation();
      final newer = controller.syncActiveReservation();
      await _settle();

      dataSource.mineRequests[1].complete(_mineRunning);
      await newer;
      // 오래된 요청은 "내 예약 없음"이라고 응답했지만, 이미 더 최근 결과가 반영됐다.
      dataSource.mineRequests[0].complete(null);
      await older;

      expect(currentList(), [_mineRunning, _roommate]);
      expect(controller.isPolling, isTrue);
    });

    test('가장 최근 요청이 null이면 정상적으로 종료한다', () async {
      await loadInitial([_mineReserved, _roommate]);
      controller.startPolling(reservationId: 114);

      final older = controller.syncActiveReservation();
      final newer = controller.syncActiveReservation();
      await _settle();

      // 오래된 응답(RUNNING)이 먼저, 가장 최근 응답(null)이 나중에 도착한다.
      dataSource.mineRequests[0].complete(_mineRunning);
      await older;
      dataSource.mineRequests[1].complete(null);
      await newer;

      expect(currentList(), [_roommate]);
      expect(controller.isPolling, isFalse);
    });
  });

  group('#325 호실 조회 종료 후 보류된 내 예약 반영', () {
    late ActiveReservationNotifier notifier;

    setUp(() async {
      final initial = container.read(activeReservationProvider.future);
      await _settle();
      dataSource.roomRequests.single.complete([_mineReserved, _roommate]);
      await initial;
      notifier = container.read(activeReservationProvider.notifier);
    });

    MyReservationApplyResult deferMine(ActiveReservationModel? mine) =>
        notifier.applyMyReservation(
          MyReservationUpdate(
            requestId: notifier.beginRequest(),
            mine: mine,
            trackedId: 114,
            userId: 15,
          ),
        );

    test('polling 종료 후 마지막 호실 조회도 실패하면 내 예약만 제거된다', () async {
      controller.startPolling(reservationId: 114, userId: 15);
      final reload = notifier.reloadInBackground();
      final polling = controller.syncActiveReservation();
      dataSource.mineRequests.single.complete(null);
      await polling;

      expect(controller.isPolling, isFalse);
      expect(currentList(), [_mineReserved, _roommate]);
      expect(dataSource.roomRequests, hasLength(3));
      dataSource.roomRequests[1].completeError(Exception('첫 호실 조회 실패'));
      await reload;
      expect(currentList(), [_mineReserved, _roommate]);

      dataSource.roomRequests[2].completeError(Exception('마지막 호실 조회 실패'));
      await _settle();

      expect(currentList(), [_roommate]);
      expect(controller.isPolling, isFalse);
      expect(container.read(activeReservationProvider).hasError, isFalse);
      expect(container.read(pollingErrorProvider), isNull);
    });

    test('호실 조회 실패 후 보류된 RUNNING 변경을 반영한다', () async {
      final reload = notifier.reloadInBackground();
      expect(deferMine(_mineRunning).isStale, isFalse);
      expect(currentList(), [_mineReserved, _roommate]);

      dataSource.roomRequests[1].completeError(Exception('호실 조회 실패'));
      await reload;

      expect(currentList(), [_mineRunning, _roommate]);
      expect(container.read(activeReservationProvider).hasError, isFalse);
    });

    test('여러 호실 요청이 남아 있으면 기다리고 마지막 실패 뒤 적용한다', () async {
      final first = notifier.reloadInBackground();
      final second = notifier.reloadInBackground();
      deferMine(_mineRunning);

      dataSource.roomRequests[1].completeError(Exception('첫 조회 실패'));
      await first;
      expect(currentList(), [_mineReserved, _roommate]);

      dataSource.roomRequests[2].completeError(Exception('마지막 조회 실패'));
      await second;
      expect(currentList(), [_mineRunning, _roommate]);
    });

    test('오래된 pending null은 더 최신인 호실 성공 스냅샷을 덮지 않는다', () async {
      final older = notifier.reloadInBackground();
      deferMine(null);
      final newer = notifier.reloadInBackground();

      dataSource.roomRequests[2].complete([_mineRunning, _roommate]);
      await newer;
      expect(currentList(), [_mineRunning, _roommate]);
      dataSource.roomRequests[1].completeError(Exception('오래된 조회 실패'));
      await older;

      expect(currentList(), [_mineRunning, _roommate]);
    });

    test('호실 성공 스냅샷 위에 최신 pending을 한 번만 반영한다', () async {
      var emitCount = 0;
      container.listen(activeReservationProvider, (_, _) => emitCount += 1);
      final reload = notifier.reloadInBackground();
      deferMine(_mineRunning);

      dataSource.roomRequests[1].complete([_mineReserved, _roommate]);
      await reload;

      expect(currentList(), [_mineRunning, _roommate]);
      expect(emitCount, 1);
    });

    test('pending 내용이 기존 목록과 같으면 실패 후 state를 재발행하지 않는다', () async {
      var emitCount = 0;
      container.listen(activeReservationProvider, (_, _) => emitCount += 1);
      final reload = notifier.reloadInBackground();
      deferMine(_mineReserved);

      dataSource.roomRequests[1].completeError(Exception('호실 조회 실패'));
      await reload;

      expect(currentList(), [_mineReserved, _roommate]);
      expect(emitCount, 0);
    });

    test('여러 polling 결과 중 가장 최신 pending만 실패 뒤 적용한다', () async {
      final reload = notifier.reloadInBackground();
      deferMine(_mineRunning);
      deferMine(null);

      dataSource.roomRequests[1].completeError(Exception('호실 조회 실패'));
      await reload;

      expect(currentList(), [_roommate]);
    });

    test('foreground refresh 실패는 오류를 유지하면서 최신 목록을 내부에 반영한다', () async {
      final error = Exception('foreground 호실 조회 실패');
      final refresh = notifier.refresh();
      deferMine(_mineRunning);

      dataSource.roomRequests[1].completeError(error);
      await refresh;

      expect(container.read(activeReservationProvider).hasError, isTrue);
      expect(container.read(activeReservationProvider).error, same(error));
      // 동일한 결과가 이미 내부 목록에 반영되어 추가 변경이 없어야 한다.
      expect(deferMine(_mineRunning).hasChanged, isFalse);
      expect(container.read(activeReservationProvider).error, same(error));
    });
  });

  test('#325 초기 build 실패는 pending이 있어도 실패 Future와 오류 상태를 유지한다', () async {
    final error = Exception('초기 호실 조회 실패');
    final initialFailure = expectLater(
      container.read(activeReservationProvider.future),
      throwsA(same(error)),
    );
    final notifier = container.read(activeReservationProvider.notifier);
    MyReservationUpdate update() => MyReservationUpdate(
      requestId: notifier.beginRequest(),
      mine: _mineRunning,
      trackedId: 114,
    );
    notifier.applyMyReservation(update());

    dataSource.roomRequests.single.completeError(error);
    await initialFailure;

    expect(container.read(activeReservationProvider).hasError, isTrue);
    expect(notifier.applyMyReservation(update()).hasChanged, isFalse);
    expect(container.read(activeReservationProvider).error, same(error));
  });

  group('호실 목록 새로고침 응답이 뒤바뀌어 도착할 때', () {
    test('오래된 새로고침이 나중에 도착해도 최신 목록을 덮지 않는다', () async {
      final notifier = container.read(activeReservationProvider.notifier);
      final initial = container.read(activeReservationProvider.future);
      await _settle();
      dataSource.roomRequests[0].complete([_mineReserved]);
      await initial;

      final older = notifier.refresh(); // 요청 2
      final newer = notifier.refresh(); // 요청 3
      await _settle();

      dataSource.roomRequests[2].complete([_mineRunning, _roommate]);
      await newer;
      dataSource.roomRequests[1].complete([_mineReserved]);
      await older;

      expect(currentList(), [_mineRunning, _roommate]);
    });
  });
}
