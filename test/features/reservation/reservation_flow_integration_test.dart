import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/errors/app_exception.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_remote_data_source.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_status_remote_data_source.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/local/machine_model.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_action_provider.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_exceptions.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_sync_controller.dart';

import '../../support/mock_washer_server.dart';

/// 예약 · 조회 · polling 종합 테스트.
///
/// 상태를 가진 가짜 서버([MockWasherServer]) 위에서 여러 사용자가 동시에 예약하고 조회하며
/// polling한다. 응답 전달 시점(Hold)과 실패(failNext)를 테스트가 직접 제어해서
/// "어떤 응답이 어떤 결과를 덮어쓰는지"를 검증하고, 마지막에는 화면 상태가 서버의 진실과
/// 일치하는지 확인한다.

/// 대기 중인 비동기 작업이 진행될 기회를 준다.
Future<void> pump([int times = 8]) async {
  for (var i = 0; i < times; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// 한 사용자의 앱(provider 컨테이너). 서버를 진짜 서버처럼 쓴다.
class ClientApp {
  ClientApp(this.server, {required this.userId, this.room = '420'}) {
    container = ProviderContainer(
      // Riverpod 3의 자동 재시도를 끄고, 실패 직후의 상태를 그대로 검증한다.
      retry: (_, __) => null,
      overrides: [
        reservationStatusRemoteDataSourceProvider.overrideWith(
          (ref) => server.statusFor(userId, room),
        ),
        reservationRemoteDataSourceProvider.overrideWith(
          (ref) => server.actionsFor(userId, room),
        ),
      ],
    );
    addTearDown(() {
      sync.stopPolling();
      container.dispose();
    });
  }

  final MockWasherServer server;
  final int userId;
  final String room;
  late final ProviderContainer container;

  ReservationSyncController get sync =>
      container.read(reservationSyncControllerProvider);

  bool get isPolling => sync.isPolling;

  AsyncValue<List<ActiveReservationModel>> get reservationsAsync =>
      container.read(activeReservationProvider);

  /// 화면에 보이는 호실 활성 예약 목록.
  List<ActiveReservationModel> get reservations =>
      reservationsAsync.value ?? const [];

  MachineModel machine(int id) => container
      .read(machineStatusProvider)
      .value!
      .machines
      .firstWhere((machine) => machine.machineId == id);

  String? get pollingError => container.read(pollingErrorProvider);

  Object? get reserveError => container.read(reservationActionProvider).error;

  /// 홈 화면 진입: 호실 목록과 기기 현황을 처음 불러온다.
  Future<void> openHome() async {
    await container.read(activeReservationProvider.future);
    await container.read(machineStatusProvider.future);
  }

  Future<ActiveReservationModel?> reserve(int machineId) => container
      .read(reservationActionProvider.notifier)
      .reserve(machineId: machineId);

  Future<bool> cancel(int reservationId) => container
      .read(reservationActionProvider.notifier)
      .cancel(reservationId: reservationId);

  /// polling 타이머가 한 번 울린 것과 같다.
  Future<void> tick() => sync.syncActiveReservation();

  /// 사용자가 당겨서 새로고침한 것과 같다(호실 목록 + 기기 현황).
  Future<void> pullToRefresh() async {
    await container.read(activeReservationProvider.notifier).refresh();
    await container.read(machineStatusProvider.notifier).refresh();
  }
}

/// 내 예약이 사용 중(RUNNING)이고 polling이 돌고 있는 상태의 시나리오.
class Scenario {
  Scenario(this.server, this.me, this.reservationId);

  final MockWasherServer server;
  final ClientApp me;
  final int reservationId;
}

Future<Scenario> runningScenario() async {
  final server = MockWasherServer();
  final me = ClientApp(server, userId: 15);
  await me.openHome();
  final reserved = await me.reserve(1);
  expect(reserved, isNotNull, reason: '시나리오 준비: 예약 성공');
  server.start(reserved!.id);
  await me.tick();
  expect(me.reservations.single.status, 'RUNNING', reason: '시나리오 준비');
  expect(me.isPolling, isTrue, reason: '시나리오 준비');
  return Scenario(server, me, reserved.id);
}

/// [client]를 새로고침한 뒤 화면 상태가 서버의 진실과 일치하는지 확인한다.
Future<void> expectConsistentWithServer(ClientApp client) async {
  await client.pullToRefresh();
  ActiveReservationModel byId(ActiveReservationModel a) => a;
  final shown = client.reservations
      .sortedBy<num>((r) => r.id)
      .map(byId)
      .toList();
  expect(
    shown,
    client.server.activeInRoom(client.room),
    reason: 'user ${client.userId}의 호실 예약 목록',
  );
  final machines = {
    for (final m
        in client.container.read(machineStatusProvider).value!.machines)
      m.machineId: m.availability,
  };
  expect(
    machines,
    client.server.machineAvailability(),
    reason: 'user ${client.userId}의 기기 현황',
  );
}

void main() {
  late MockWasherServer server;

  setUp(() {
    server = MockWasherServer();
  });

  group('정상 흐름', () {
    test('예약 → 사용 시작 → 완료까지 화면이 서버를 따라간다', () async {
      final me = ClientApp(server, userId: 15);
      await me.openHome();

      final reserved = await me.reserve(1);

      expect(reserved, isNotNull);
      expect(me.reservations.map((r) => r.status), ['RESERVED']);
      expect(me.machine(1).availability, 'RESERVED');
      expect(me.isPolling, isTrue);

      server.start(reserved!.id);
      await me.tick();
      expect(me.reservations.single.status, 'RUNNING');
      expect(me.machine(1).availability, 'IN_USE');

      server.complete(reserved.id);
      await me.tick();
      await pump();
      expect(me.reservations, isEmpty);
      expect(me.machine(1).availability, 'AVAILABLE');
      expect(me.isPolling, isFalse);
      await expectConsistentWithServer(me);
    });
  });

  group('동시 예약', () {
    test('두 사용자가 같은 기기를 동시에 예약하면 한 명만 성공한다', () async {
      final a = ClientApp(server, userId: 15, room: '420');
      final b = ClientApp(server, userId: 16, room: '421');
      await Future.wait([a.openHome(), b.openHome()]);

      final results = await Future.wait([a.reserve(1), b.reserve(1)]);

      final winners = results.whereType<ActiveReservationModel>().toList();
      expect(winners, hasLength(1), reason: '서버가 하나만 허용해야 한다');
      expect(server.activeCount, 1);

      final loser = results[0] == null ? a : b;
      final winner = loser == a ? b : a;
      expect(loser.isPolling, isFalse, reason: '실패한 쪽은 polling을 시작하지 않는다');
      expect(loser.reservations, isEmpty);
      expect(loser.reserveError, isNotNull);
      expect(winner.isPolling, isTrue);
      expect(winner.reservations.single.id, winners.single.id);

      // 진 쪽은 조회 시점에는 비어 있던 기기를 봤으므로, 새로고침하면 서버와 일치해야 한다.
      await expectConsistentWithServer(loser);
      await expectConsistentWithServer(winner);
    });

    test('같은 기기를 연달아 누르면 서버 요청은 한 번만 나간다(single-flight)', () async {
      final me = ClientApp(server, userId: 15);
      await me.openHome();

      final results = await Future.wait([me.reserve(1), me.reserve(1)]);

      expect(results[0], isNotNull);
      expect(results[1], results[0], reason: '같은 요청에 합류해 같은 결과를 받는다');
      expect(server.calls(Endpoint.create), 1);
      expect(server.activeCount, 1);
    });

    test('한 사용자가 서로 다른 기기를 동시에 예약하면 1인 1예약으로 하나만 성공한다', () async {
      final me = ClientApp(server, userId: 15);
      await me.openHome();

      final results = await Future.wait([me.reserve(1), me.reserve(3)]);

      expect(results.whereType<ActiveReservationModel>(), hasLength(1));
      expect(server.calls(Endpoint.create), 2, reason: '키가 달라 둘 다 서버로 나간다');
      expect(server.activeCount, 1);
      final winner = results.whereType<ActiveReservationModel>().single;
      expect(me.reservations.map((r) => r.id), [winner.id]);
      expect(me.isPolling, isTrue);
      await expectConsistentWithServer(me);
    });

    test('같은 호실의 룸메이트가 같은 종류(세탁기)를 동시에 예약하면 한 명만 성공한다', () async {
      final a = ClientApp(server, userId: 15);
      final c = ClientApp(server, userId: 17);
      await Future.wait([a.openHome(), c.openHome()]);

      final results = await Future.wait([a.reserve(1), c.reserve(2)]);

      expect(results.whereType<ActiveReservationModel>(), hasLength(1));
      expect(server.activeInRoom('420'), hasLength(1));
    });

    test('같은 호실의 룸메이트가 세탁기와 건조기를 동시에 예약하면 둘 다 성공한다', () async {
      final a = ClientApp(server, userId: 15);
      final c = ClientApp(server, userId: 17);
      await Future.wait([a.openHome(), c.openHome()]);

      final results = await Future.wait([a.reserve(1), c.reserve(3)]);

      expect(results.whereType<ActiveReservationModel>(), hasLength(2));
      expect(server.activeInRoom('420'), hasLength(2));

      // 서로의 예약은 다음 호실 목록 조회로 보인다.
      await expectConsistentWithServer(a);
      await expectConsistentWithServer(c);
      expect(a.reservations.map((r) => r.userId).toSet(), {15, 17});
    });

    test('예약 요청과 홈 최초 조회가 겹쳐도 예약이 중복되거나 사라지지 않는다', () async {
      final me = ClientApp(server, userId: 15);

      final reserving = me.reserve(1);
      final opening = me.openHome();
      final reserved = await reserving;
      await opening;
      await pump();

      expect(reserved, isNotNull);
      expect(me.reservations, hasLength(1));
      expect(me.reservations.single.status, 'RESERVED');
      await expectConsistentWithServer(me);
    });
  });

  group('polling 실패가 결과를 덮어쓰는지', () {
    test('polling이 한 번 실패해도 화면의 예약 목록은 그대로이고 polling은 계속된다', () async {
      final s = await runningScenario();
      final before = s.me.reservations;

      s.server.failNext(Endpoint.myReservation, networkError());
      await s.me.tick();

      expect(s.me.reservations, same(before), reason: '실패한 응답은 상태를 건드리지 않는다');
      expect(s.me.reservationsAsync.hasError, isFalse);
      expect(s.me.pollingError, isNull, reason: '한 번의 실패는 사용자에게 알리지 않는다');
      expect(s.me.isPolling, isTrue);

      // 다음 성공이 정상적으로 반영된다.
      s.server.complete(s.reservationId);
      await s.me.tick();
      await pump();
      expect(s.me.reservations, isEmpty);
      expect(s.me.isPolling, isFalse);
    });

    test('실패한 polling은 그 사이 바뀐 서버 상태를 반영하지 않고, 다음 성공이 반영한다', () async {
      final s = await runningScenario();
      s.server.complete(s.reservationId); // 서버에서는 이미 완료됨

      s.server.failNext(Endpoint.myReservation, networkError());
      await s.me.tick();

      expect(s.me.reservations.single.status, 'RUNNING', reason: '아직 모른다');
      expect(s.me.isPolling, isTrue);

      await s.me.tick();
      await pump();
      expect(s.me.reservations, isEmpty);
      expect(s.me.isPolling, isFalse);
    });

    test('연속 5번 실패해야 중단되고, 중단돼도 화면의 예약은 유지된다', () async {
      final s = await runningScenario();

      s.server.failNext(Endpoint.myReservation, networkError(), times: 5);
      for (var i = 0; i < 4; i++) {
        await s.me.tick();
        expect(s.me.isPolling, isTrue, reason: '${i + 1}번째 실패');
        expect(s.me.pollingError, isNull);
      }
      await s.me.tick(); // 5번째

      expect(s.me.isPolling, isFalse);
      expect(s.me.pollingError, '서버 상태가 지연되고 있습니다.');
      expect(
        s.me.reservations.single.status,
        'RUNNING',
        reason: '조회를 못 했다고 예약 카드를 지우면 안 된다',
      );
    });

    test('중간에 한 번 성공하면 연속 실패 횟수가 초기화된다', () async {
      final s = await runningScenario();

      s.server.failNext(Endpoint.myReservation, networkError(), times: 4);
      for (var i = 0; i < 4; i++) {
        await s.me.tick();
      }
      await s.me.tick(); // 성공 -> 초기화
      expect(s.me.isPolling, isTrue);

      s.server.failNext(Endpoint.myReservation, networkError(), times: 4);
      for (var i = 0; i < 4; i++) {
        await s.me.tick();
      }
      expect(s.me.isPolling, isTrue, reason: '초기화 뒤 4번 실패는 아직 중단 조건이 아니다');

      s.server.failNext(Endpoint.myReservation, networkError());
      await s.me.tick();
      expect(s.me.isPolling, isFalse, reason: '초기화 뒤 연속 5번째');
    });

    test('상태 코드별 오류(403/409/502/503)도 화면의 예약 목록을 건드리지 않는다', () async {
      for (final code in [403, 409, 502, 503]) {
        final s = await runningScenario();
        final before = s.me.reservations;

        s.server.failNext(
          Endpoint.myReservation,
          httpError(code, '서버 오류 $code'),
        );
        await s.me.tick();

        expect(s.me.reservations, same(before), reason: 'status $code');
        expect(s.me.isPolling, isTrue, reason: 'status $code');
      }
    });

    test('종료 확정 뒤에 늦게 도착한 오래된 응답이 예약을 되살리지 않는다', () async {
      final s = await runningScenario();

      // 서버가 RUNNING 상태로 응답을 확정했지만 전달이 늦어진다.
      final hold = s.server.holdNext(Endpoint.myReservation);
      final stale = s.me.tick();
      await pump();

      // 그 사이 예약이 끝나고, 더 늦게 시작한 조회가 "없음"을 먼저 받는다.
      s.server.complete(s.reservationId);
      await s.me.tick();
      await pump();
      expect(s.me.reservations, isEmpty);
      expect(s.me.isPolling, isFalse);

      hold.release();
      await stale;
      await pump();

      expect(
        s.me.reservations,
        isEmpty,
        reason: '오래된 RUNNING 응답이 예약을 되살리면 안 된다',
      );
      expect(s.me.isPolling, isFalse, reason: '오래된 응답이 polling을 다시 켜면 안 된다');
    });

    test('오래된 응답은 성공, 더 최근 응답은 실패: 오래된 성공이 반영되고 실패 횟수는 초기화된다', () async {
      final s = await runningScenario();

      final hold = s.server.holdNext(Endpoint.myReservation);
      final older = s.me.tick(); // RUNNING 확정, 전달 지연
      await pump();

      s.server.failNext(Endpoint.myReservation, networkError());
      await s.me.tick(); // 더 최근 요청은 실패(횟수 1)

      hold.release();
      await older; // 마지막으로 도착한 성공이 횟수를 초기화한다
      await pump();

      expect(s.me.reservations.single.status, 'RUNNING');
      expect(s.me.isPolling, isTrue);

      s.server.failNext(Endpoint.myReservation, networkError(), times: 4);
      for (var i = 0; i < 4; i++) {
        await s.me.tick();
      }
      expect(s.me.isPolling, isTrue, reason: '초기화됐으므로 4번 실패는 아직 중단 조건이 아니다');
    });

    test('polling이 예약 변화를 감지했는데 기기 현황 조회가 실패해도 예약 목록은 갱신된다', () async {
      final me = ClientApp(server, userId: 15);
      await me.openHome();
      final reserved = (await me.reserve(1))!;

      server
        ..start(reserved.id)
        ..failNext(Endpoint.machineStatus, networkError());
      await me.tick();

      expect(me.reservations.single.status, 'RUNNING', reason: '예약 변화는 반영된다');
      expect(me.reservationsAsync.hasError, isFalse);
      expect(me.isPolling, isTrue, reason: '기기 현황 실패가 polling을 끊으면 안 된다');

      // 다음 성공에서 기기 현황도 복구된다.
      server.complete(reserved.id);
      await me.tick();
      await pump();
      expect(me.machine(1).availability, 'AVAILABLE');
      expect(me.reservations, isEmpty);
    });

    test('6번째 polling 뒤 백그라운드 호실 동기화가 실패해도 화면 상태와 안내는 그대로다', () async {
      final s = await runningScenario();
      final before = s.me.reservations;
      final roomCallsBefore = s.server.calls(Endpoint.roomReservations);

      // runningScenario의 첫 성공 polling(1회) + 여기서 5회 = 6회에서 동기화가 실행된다.
      s.server.failNext(Endpoint.roomReservations, networkError());
      for (var i = 0; i < 5; i++) {
        await s.me.tick();
      }
      await pump();

      expect(
        s.server.calls(Endpoint.roomReservations),
        roomCallsBefore + 1,
        reason: '동기화가 한 번 시도됨',
      );
      expect(s.me.reservations, same(before));
      expect(s.me.reservationsAsync.hasError, isFalse);
      expect(s.me.pollingError, isNull);
      expect(s.me.isPolling, isTrue);
    });

    test('주기 동기화로 룸메이트의 새 예약이 내 화면에 반영된다', () async {
      final s = await runningScenario();
      final roommate = ClientApp(s.server, userId: 17);
      await roommate.openHome();
      expect((await roommate.reserve(3)), isNotNull);

      expect(s.me.reservations, hasLength(1), reason: '동기화 전에는 모른다');
      for (var i = 0; i < 5; i++) {
        await s.me.tick();
      }
      await pump();

      expect(s.me.reservations.map((r) => r.userId).toSet(), {15, 17});
    });
  });

  group('취소와 polling', () {
    test('취소하면 패널티가 서버 기준으로 적용되어 재예약이 막히고, 해제되면 예약된다', () async {
      final me = ClientApp(server, userId: 15);
      await me.openHome();
      final reserved = (await me.reserve(1))!;

      expect(await me.cancel(reserved.id), isTrue);
      expect(me.reservations, isEmpty);
      expect(me.isPolling, isFalse);
      expect(me.machine(1).availability, 'AVAILABLE');

      expect(await me.reserve(1), isNull);
      expect(me.reserveError, isA<ReservationPenaltyException>());
      expect(
        server.calls(Endpoint.create),
        1,
        reason: '패널티 중에는 서버로 예약 요청을 보내지 않는다',
      );

      server.clearPenalty(15);
      expect(await me.reserve(1), isNotNull);
    });

    test('사용이 시작된 예약의 취소가 409로 실패해도 polling은 계속된다', () async {
      final s = await runningScenario();

      final cancelled = await s.me.cancel(s.reservationId);

      expect(cancelled, isFalse);
      expect(
        AppException.from(s.me.reserveError).message,
        '이미 사용이 시작된 예약은 취소할 수 없습니다.',
      );
      expect(s.me.reservations.single.status, 'RUNNING');
      expect(
        s.me.isPolling,
        isTrue,
        reason: '취소가 실패했으면 예약은 계속되므로 완료까지 화면이 갱신돼야 한다',
      );

      s.server.complete(s.reservationId);
      await s.me.tick();
      await pump();
      expect(s.me.reservations, isEmpty, reason: '취소 실패 뒤에도 완료가 화면에 반영된다');
    });

    test('취소하는 동안 늦게 도착한 오래된 polling 응답이 취소된 예약을 되살리지 않는다', () async {
      final me = ClientApp(server, userId: 15);
      await me.openHome();
      final reserved = (await me.reserve(1))!;

      // 취소 전 상태(RESERVED)로 응답이 확정됐지만 전달이 늦어진다.
      final hold = server.holdNext(Endpoint.myReservation);
      final stale = me.tick();
      await pump();

      expect(await me.cancel(reserved.id), isTrue);
      expect(me.reservations, isEmpty);

      hold.release();
      await stale;
      await pump();

      expect(me.reservations, isEmpty);
      expect(me.isPolling, isFalse);
    });
  });

  group('예약 요청 실패', () {
    test('예약 생성이 503이면 실패로 끝나고 polling·목록은 그대로다', () async {
      final me = ClientApp(server, userId: 15);
      await me.openHome();
      server.failNext(
        Endpoint.create,
        httpError(503, 'Redis connection failed'),
      );

      final result = await me.reserve(1);

      expect(result, isNull);
      expect(
        AppException.from(me.reserveError).message,
        '서버가 일시적으로 불안정합니다. 잠시 후 다시 시도해주세요.',
      );
      expect(me.isPolling, isFalse);
      expect(me.reservations, isEmpty);
      expect(server.activeCount, 0);
    });

    test('서버는 예약을 만들었지만 응답이 유실되면, 화면은 모르다가 새로고침으로 따라잡는다', () async {
      final me = ClientApp(server, userId: 15);
      await me.openHome();
      server.failNext(Endpoint.create, networkError(), afterProcessing: true);

      final result = await me.reserve(1);

      expect(result, isNull, reason: '클라이언트는 실패로 안다');
      expect(server.activeCount, 1, reason: '서버에는 예약이 생겼다');
      expect(me.reservations, isEmpty);
      expect(me.isPolling, isFalse);

      await expectConsistentWithServer(me);
      expect(me.reservations.single.status, 'RESERVED');
      expect(me.machine(1).availability, 'RESERVED');

      // 같은 기기를 다시 눌러도 예약이 중복 생성되지 않는다.
      expect(await me.reserve(1), isNull);
      expect(me.reserveError, isA<AlreadyReservedException>());
      expect(server.calls(Endpoint.create), 1);
    });

    test('예약 가능 상태 조회가 실패해도 예약은 진행된다(서버가 최종 검증)', () async {
      final me = ClientApp(server, userId: 15);
      await me.openHome();
      server.failNext(Endpoint.availability, networkError());

      expect(await me.reserve(1), isNotNull);
      expect(server.activeCount, 1);
    });

    test('예약 직전 기기 현황 조회가 실패하면 예약 요청을 보내지 않는다', () async {
      final me = ClientApp(server, userId: 15);
      await me.openHome();
      server.failNext(Endpoint.machineStatus, networkError());

      expect(await me.reserve(1), isNull);
      expect(server.calls(Endpoint.create), 0);
      expect(me.isPolling, isFalse);
    });
  });

  group('종합 시나리오', () {
    test(
      '동시 예약 · polling 실패 · 순서 역전 · 취소 실패 · 완료를 거쳐도 모든 화면이 서버와 일치한다',
      () async {
        final me = ClientApp(server, userId: 15, room: '420');
        final roommate = ClientApp(server, userId: 17, room: '420');
        final other = ClientApp(server, userId: 16, room: '421');
        await Future.wait([
          me.openHome(),
          roommate.openHome(),
          other.openHome(),
        ]);

        // 1) 내가 세탁기를 잡은 뒤, 다른 호실 사용자는 같은 기기에 도전(실패)하고
        //    룸메이트는 동시에 건조기를 예약한다.
        final mine = (await me.reserve(1))!;
        final concurrent = await Future.wait([
          other.reserve(1),
          roommate.reserve(3),
        ]);
        expect(concurrent[0], isNull, reason: '이미 예약된 세탁기');
        final roommateReservation = concurrent[1]!;
        expect(server.activeCount, 2);
        await expectConsistentWithServer(other);

        // 2) 둘 다 사용을 시작한다.
        server
          ..start(mine.id)
          ..start(roommateReservation.id);

        // 3) 내 polling: 한 번 실패한 뒤 성공 -> RUNNING 반영.
        server.failNext(Endpoint.myReservation, networkError());
        await me.tick();
        expect(
          me.reservations.firstWhere((r) => r.id == mine.id).status,
          'RESERVED',
        );
        await me.tick();
        expect(
          me.reservations.firstWhere((r) => r.id == mine.id).status,
          'RUNNING',
        );

        // 4) 룸메이트: 오래된 응답 전달이 지연되는 사이 예약이 끝난다.
        final hold = server.holdNext(Endpoint.myReservation);
        final stale = roommate.tick();
        await pump();
        server.complete(roommateReservation.id);
        await roommate.tick();
        await pump();
        expect(roommate.isPolling, isFalse);
        hold.release();
        await stale;
        await pump();
        expect(
          roommate.reservations.where((r) => r.id == roommateReservation.id),
          isEmpty,
          reason: '늦게 도착한 오래된 응답이 완료된 예약을 되살리면 안 된다',
        );

        // 5) 내 화면은 주기 동기화(6회)로 룸메이트의 완료를 따라잡는다.
        for (var i = 0; i < 5; i++) {
          await me.tick();
        }
        await pump();
        expect(me.reservations.map((r) => r.id), [mine.id]);

        // 6) 사용 중인 예약 취소는 실패하지만 polling은 유지된다.
        expect(await me.cancel(mine.id), isFalse);
        expect(me.isPolling, isTrue);
        await expectConsistentWithServer(me);

        // 7) 내 예약이 완료되고, 모두의 화면이 서버와 일치한다.
        server.complete(mine.id);
        await me.tick();
        await pump();
        expect(me.isPolling, isFalse);
        expect(server.activeCount, 0);
        for (final client in [me, roommate, other]) {
          await expectConsistentWithServer(client);
          expect(client.reservations, isEmpty);
        }
      },
    );
  });
}
