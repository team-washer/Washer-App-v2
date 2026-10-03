import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_status_remote_data_source.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/local/machine_model.dart';
import 'package:washer/features/reservation/data/models/remote/reservation_availability_response.dart';
import 'package:washer/features/reservation/presentation/providers/my_reservation_update.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_sync_controller.dart';
import 'package:washer/features/user/data/models/my_user_model.dart';
import 'package:washer/features/user/presentation/providers/my_user_provider.dart';

/// 서버 상태(호실 목록 / 내 예약)를 테스트가 자유롭게 바꿀 수 있는 fake.
class _FakeServer implements ReservationStatusRemoteDataSource {
  List<ActiveReservationModel> room = const [];
  ActiveReservationModel? mine;
  Object? roomError;
  int roomRequestCount = 0;

  @override
  Future<List<ActiveReservationModel>> getActiveReservations() async {
    roomRequestCount += 1;
    final error = roomError;
    if (error != null) {
      throw error;
    }
    return room;
  }

  @override
  Future<ActiveReservationModel?> getMyActiveReservation() async => mine;

  @override
  Future<MachineStatusResponse> getMachineStatus() async =>
      const MachineStatusResponse(machines: [], totalCount: 0);

  @override
  Future<ReservationAvailabilityResponse> getReservationAvailability() async =>
      const ReservationAvailabilityResponse();
}

class _FakeMyUserNotifier extends MyUserNotifier {
  _FakeMyUserNotifier(this.userId);

  final int userId;

  @override
  Future<MyUserModel?> build() async =>
      MyUserModel(id: userId, name: '나', roomNumber: '420');
}

ActiveReservationModel _reservation({
  required int id,
  required int userId,
  String status = 'RUNNING',
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

final _mine = _reservation(id: 114, userId: 15);
final _roommate = _reservation(id: 200, userId: 16);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('MyReservationUpdate.applyTo (내 사용자 ID로 식별)', () {
    test('예약 ID를 몰라도 내 사용자 ID로 종료된 내 예약을 제거한다', () {
      const update = MyReservationUpdate(
        requestId: 1,
        mine: null,
        trackedId: null,
        userId: 15,
      );

      expect(update.applyTo([_mine, _roommate]), [_roommate]);
    });

    test('예약 ID도 사용자 ID도 모르면 목록을 그대로 둔다', () {
      const update = MyReservationUpdate(
        requestId: 1,
        mine: null,
        trackedId: null,
      );

      expect(update.applyTo([_mine, _roommate]), [_mine, _roommate]);
    });

    test('같은 사용자의 오래된 예약(다른 ID)을 새 예약으로 교체하고 중복을 만들지 않는다', () {
      final oldMine = _reservation(id: 100, userId: 15, status: 'COMPLETED');
      final newMine = _reservation(id: 114, userId: 15, status: 'RESERVED');
      final update = MyReservationUpdate(
        requestId: 1,
        mine: newMine,
        trackedId: 114,
      );

      expect(update.applyTo([oldMine, _roommate]), [newMine, _roommate]);
    });

    test('룸메이트 예약은 건드리지 않는다', () {
      final update = MyReservationUpdate(
        requestId: 1,
        mine: _reservation(id: 114, userId: 15, status: 'COMPLETED'),
        trackedId: 114,
      );

      expect(update.applyTo([_mine, _roommate]).last, _roommate);
    });
  });

  group('ReservationSyncController 리뷰 반영', () {
    late _FakeServer server;

    ProviderContainer makeContainer({int? loggedInUserId}) {
      final container = ProviderContainer(
        overrides: [
          reservationStatusRemoteDataSourceProvider.overrideWith(
            (ref) => server,
          ),
          if (loggedInUserId != null)
            myUserProvider.overrideWith(
              () => _FakeMyUserNotifier(loggedInUserId),
            ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    setUp(() {
      server = _FakeServer();
    });

    test('예약 ID 없이 시작해 첫 응답이 null이어도 내 예약을 제거하고 종료한다', () async {
      server
        ..room = [_mine, _roommate]
        ..mine = null;
      final container = makeContainer(loggedInUserId: 15);
      // 홈에서 이미 불러와 있는 상태를 재현한다.
      await container.read(myUserProvider.future);
      await container.read(activeReservationProvider.future);
      // 서버는 내 예약이 끝난 뒤 호실 목록에서도 그 예약을 뺀다.
      server.room = [_roommate];

      final controller = container.read(reservationSyncControllerProvider);
      controller.startPolling(); // 예약 ID, 사용자 ID 모두 모름
      addTearDown(controller.stopPolling);

      await controller.syncActiveReservation();
      await _settle();

      expect(controller.isPolling, isFalse);
      expect(container.read(activeReservationProvider).value, [_roommate]);
    });

    test('내 예약이 끝난 뒤 룸메이트 예약의 변화도 함께 맞춘다', () async {
      server
        ..room = [_mine, _roommate]
        ..mine = _mine;
      final container = makeContainer();
      await container.read(activeReservationProvider.future);
      final controller = container.read(reservationSyncControllerProvider);
      controller.startPolling(reservationId: 114, userId: 15);
      addTearDown(controller.stopPolling);

      // 내 예약이 끝나고, 그 사이 룸메이트 예약도 완료로 바뀌었다.
      final roommateCompleted = _reservation(
        id: 200,
        userId: 16,
        status: 'COMPLETED',
      );
      server
        ..mine = null
        ..room = [roommateCompleted];

      await controller.syncActiveReservation();
      await _settle();

      expect(controller.isPolling, isFalse);
      expect(container.read(activeReservationProvider).value, [
        roommateCompleted,
      ]);
    });

    test('polling이 6번 성공할 때마다 호실 목록을 다시 맞춘다(그 전에는 조회하지 않는다)', () async {
      server
        ..room = [_mine, _roommate]
        ..mine = _mine;
      final container = makeContainer();
      await container.read(activeReservationProvider.future);
      final controller = container.read(reservationSyncControllerProvider);
      controller.startPolling(reservationId: 114, userId: 15);
      addTearDown(controller.stopPolling);
      expect(server.roomRequestCount, 1); // 홈 최초 진입 조회

      for (var i = 0; i < 5; i++) {
        await controller.syncActiveReservation();
      }
      await _settle();
      expect(server.roomRequestCount, 1); // 5번째까지는 호실 목록을 조회하지 않는다

      await controller.syncActiveReservation(); // 6번째
      await _settle();
      expect(server.roomRequestCount, 2);

      for (var i = 0; i < 6; i++) {
        await controller.syncActiveReservation();
      }
      await _settle();
      expect(server.roomRequestCount, 3);
    });

    test('주기 동기화로 룸메이트의 새 예약이 목록에 반영된다', () async {
      server
        ..room = [_mine]
        ..mine = _mine;
      final container = makeContainer();
      await container.read(activeReservationProvider.future);
      final controller = container.read(reservationSyncControllerProvider);
      controller.startPolling(reservationId: 114, userId: 15);
      addTearDown(controller.stopPolling);

      server.room = [_mine, _roommate]; // 룸메이트가 새로 예약했다.
      for (var i = 0; i < 6; i++) {
        await controller.syncActiveReservation();
      }
      await _settle();

      expect(container.read(activeReservationProvider).value, [
        _mine,
        _roommate,
      ]);
    });
  });

  group('ActiveReservationNotifier.reloadInBackground', () {
    late _FakeServer server;

    setUp(() {
      server = _FakeServer()..room = [_mine];
    });

    ProviderContainer makeContainer() {
      final container = ProviderContainer(
        overrides: [
          reservationStatusRemoteDataSourceProvider.overrideWith(
            (ref) => server,
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('로딩 상태를 거치지 않고 목록을 갱신한다', () async {
      final container = makeContainer();
      await container.read(activeReservationProvider.future);
      final states = <AsyncValue<List<ActiveReservationModel>>>[];
      container.listen(
        activeReservationProvider,
        (_, next) => states.add(next),
      );

      server.room = [_mine, _roommate];
      await container
          .read(activeReservationProvider.notifier)
          .reloadInBackground();

      expect(states.any((state) => state.isLoading), isFalse);
      expect(container.read(activeReservationProvider).value, [
        _mine,
        _roommate,
      ]);
    });

    test('실패해도 화면 상태와 안내 문구를 바꾸지 않는다', () async {
      final container = makeContainer();
      await container.read(activeReservationProvider.future);

      server.roomError = Exception('네트워크 오류');
      await container
          .read(activeReservationProvider.notifier)
          .reloadInBackground();

      expect(container.read(activeReservationProvider).value, [_mine]);
      expect(container.read(activeReservationProvider).hasError, isFalse);
      expect(container.read(pollingErrorProvider), isNull);
    });

    test('변화가 없으면 상태를 다시 내보내지 않는다', () async {
      final container = makeContainer();
      await container.read(activeReservationProvider.future);
      var emitCount = 0;
      container.listen(activeReservationProvider, (_, __) => emitCount += 1);

      await container
          .read(activeReservationProvider.notifier)
          .reloadInBackground();

      expect(emitCount, 0);
    });
  });
}
