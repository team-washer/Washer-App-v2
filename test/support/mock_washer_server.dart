import 'dart:async';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_remote_data_source.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_status_remote_data_source.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/local/machine_model.dart';
import 'package:washer/features/reservation/data/models/remote/cancel_reservation_response.dart';
import 'package:washer/features/reservation/data/models/remote/reservation_availability_response.dart';

/// 서버 API 한 종류. 장애 주입과 응답 지연의 대상이다.
enum Endpoint {
  machineStatus,
  roomReservations,
  myReservation,
  availability,
  create,
  cancel,
}

/// 서버가 처리를 끝낸 응답의 **전달**을 붙잡아 두는 핸들.
///
/// 서버는 요청을 받은 시점의 상태로 응답 내용을 확정하고, [release]를 부를 때까지
/// 클라이언트에게 전달하지 않는다. 그 사이 서버 상태가 바뀌면 나중에 도착하는 응답은
/// "오래된 스냅샷"이 된다(응답 순서 역전 재현).
class Hold {
  final _completer = Completer<void>();

  void release() {
    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }
}

class _Fault {
  _Fault(this.error, {required this.afterProcessing});

  final DioException error;

  /// true면 서버는 요청을 처리했지만 응답이 유실된 경우(상태는 바뀌고 클라이언트는 실패로 안다).
  final bool afterProcessing;
}

class _MachineRow {
  _MachineRow(this.id, this.name, this.type);

  final int id;
  final String name;
  final String type;
}

class _ReservationRow {
  _ReservationRow({
    required this.id,
    required this.userId,
    required this.room,
    required this.machine,
    required this.status,
  });

  final int id;
  final int userId;
  final String room;
  final _MachineRow machine;
  String status;

  bool get isActive => status == 'RESERVED' || status == 'RUNNING';
}

/// 서버 오류 응답 계약(공통 wrapper)을 따르는 [DioException]을 만든다.
DioException httpError(int statusCode, String message) {
  final options = RequestOptions(path: '/mock');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: statusCode,
      data: {
        'status': '$statusCode',
        'code': statusCode,
        'message': message,
        'data': {'errorCode': 'E_$statusCode', 'traceId': 'mock-trace'},
      },
    ),
  );
}

/// 응답 없이 끊긴 네트워크 오류.
DioException networkError() {
  return DioException(
    requestOptions: RequestOptions(path: '/mock'),
    type: DioExceptionType.connectionError,
    error: 'network down',
  );
}

/// 상태를 가진 가짜 서버.
///
/// 기기·예약·패널티를 실제 서버처럼 관리하고 서버 규칙(1인 1예약, 호실당 같은 종류 1개,
/// 사용이 시작된 예약 취소는 409 등)을 적용한다. 여러 사용자가 [statusFor]/[actionsFor]로
/// 같은 서버를 공유해 동시 예약·조회를 재현할 수 있다.
class MockWasherServer {
  MockWasherServer() {
    for (final machine in [
      _MachineRow(1, 'Washer-4F-L1', 'WASHER'),
      _MachineRow(2, 'Washer-4F-L2', 'WASHER'),
      _MachineRow(3, 'Dryer-4F-R1', 'DRYER'),
      _MachineRow(4, 'Dryer-4F-R2', 'DRYER'),
    ]) {
      _machines[machine.id] = machine;
    }
  }

  final Map<int, _MachineRow> _machines = {};
  final List<_ReservationRow> _rows = [];
  final Map<int, DateTime> _penaltyUntil = {};
  final Map<Endpoint, List<_Fault>> _faults = {};
  final Map<Endpoint, List<Hold>> _holds = {};
  final Map<Endpoint, int> _calls = {for (final e in Endpoint.values) e: 0};
  int _nextReservationId = 100;

  static const Duration cancelPenalty = Duration(minutes: 5);

  // ── 서버 밖에서 일어나는 일(시간 경과, 관리자 조작 등) ──────────────────────

  /// 예약된 기기의 사용이 시작된다(RESERVED -> RUNNING).
  void start(int reservationId) => _row(reservationId).status = 'RUNNING';

  /// 사용이 끝나 예약이 완료된다(활성 예약에서 빠진다).
  void complete(int reservationId) => _row(reservationId).status = 'COMPLETED';

  /// 서버가 예약을 자동 취소한다(확정 만료 등).
  void expire(int reservationId) => _row(reservationId).status = 'CANCELLED';

  /// 사용자의 취소 패널티를 해제한다(만료 시각 경과).
  void clearPenalty(int userId) => _penaltyUntil.remove(userId);

  // ── 서버의 진실 값(테스트가 화면 상태와 대조한다) ────────────────────────────

  /// [room] 호실의 활성 예약 전체(id 순).
  List<ActiveReservationModel> activeInRoom(String room) {
    return _rows
        .where((row) => row.isActive && row.room == room)
        .map(_toModel)
        .sorted((a, b) => a.id.compareTo(b.id));
  }

  ActiveReservationModel? activeOf(int userId) {
    final row = _rows.firstWhereOrNull((r) => r.isActive && r.userId == userId);
    return row == null ? null : _toModel(row);
  }

  int get activeCount => _rows.where((row) => row.isActive).length;

  /// 기기별 현재 상태(id -> availability)의 진실 값.
  Map<int, String> machineAvailability() => {
    for (final machine in _machineStatus().machines)
      machine.machineId: machine.availability,
  };

  /// [endpoint]가 지금까지 호출된 횟수.
  int calls(Endpoint endpoint) => _calls[endpoint]!;

  // ── 장애 주입과 응답 지연 ─────────────────────────────────────────────────

  /// [endpoint]의 다음 [times]번 호출을 [error]로 실패시킨다.
  ///
  /// [afterProcessing]이 true면 서버는 요청을 처리한 뒤(상태 변경 포함) 응답만 유실된다.
  void failNext(
    Endpoint endpoint,
    DioException error, {
    int times = 1,
    bool afterProcessing = false,
  }) {
    final queue = _faults.putIfAbsent(endpoint, () => []);
    for (var i = 0; i < times; i++) {
      queue.add(_Fault(error, afterProcessing: afterProcessing));
    }
  }

  /// [endpoint]의 다음 호출 응답 전달을 붙잡아 둔다. 반환된 [Hold.release]로 전달한다.
  Hold holdNext(Endpoint endpoint) {
    final hold = Hold();
    _holds.putIfAbsent(endpoint, () => []).add(hold);
    return hold;
  }

  // ── 사용자별 클라이언트(앱이 쓰는 데이터소스 구현) ──────────────────────────

  ReservationStatusRemoteDataSource statusFor(int userId, String room) =>
      _StatusClient(this, userId, room);

  ReservationRemoteDataSource actionsFor(int userId, String room) =>
      _ActionsClient(this, userId, room);

  // ── 내부 ───────────────────────────────────────────────────────────────

  _ReservationRow _row(int id) => _rows.firstWhere((row) => row.id == id);

  ActiveReservationModel _toModel(_ReservationRow row) {
    return ActiveReservationModel(
      id: row.id,
      userId: row.userId,
      userName: '사용자${row.userId}',
      userRoomNumber: row.room,
      machineId: row.machine.id,
      machineName: row.machine.name,
      reservedAt: '2026-09-21T10:00:00',
      status: row.status,
    );
  }

  Future<T> _serve<T>(Endpoint endpoint, T Function() handle) async {
    _calls[endpoint] = _calls[endpoint]! + 1;
    final fault = _take(_faults, endpoint);
    final hold = _take(_holds, endpoint);

    T? result;
    DioException? error;
    if (fault != null && !fault.afterProcessing) {
      error = fault.error; // 처리 전에 실패: 서버 상태는 그대로다.
    } else {
      try {
        result = handle(); // 응답 내용(과 상태 변경)은 요청을 받은 시점에 확정된다.
      } on DioException catch (e) {
        error = e;
      }
      if (fault != null && error == null) {
        error = fault.error; // 처리는 됐지만 응답이 유실됐다.
        result = null;
      }
    }

    if (hold != null) {
      await hold._completer.future; // 전달만 늦어진다.
    }
    if (error != null) {
      throw error;
    }
    return result as T;
  }

  X? _take<X>(Map<Endpoint, List<X>> queues, Endpoint endpoint) {
    final queue = queues[endpoint];
    if (queue == null || queue.isEmpty) {
      return null;
    }
    return queue.removeAt(0);
  }

  MachineStatusResponse _machineStatus() {
    final machines = _machines.values.map((machine) {
      final active = _rows.firstWhereOrNull(
        (row) => row.isActive && row.machine.id == machine.id,
      );
      return MachineModel(
        machineId: machine.id,
        name: machine.name,
        type: machine.type,
        status: 'NORMAL',
        availability: active == null
            ? 'AVAILABLE'
            : (active.status == 'RESERVED' ? 'RESERVED' : 'IN_USE'),
        reservationId: active?.id,
        userId: active?.userId,
        roomNumber: active?.room,
      );
    }).toList();
    return MachineStatusResponse(
      machines: machines,
      totalCount: machines.length,
    );
  }

  ReservationAvailabilityResponse _availability(int userId) {
    final until = _penaltyUntil[userId];
    final penalized = until != null && until.isAfter(DateTime.now());
    return ReservationAvailabilityResponse(
      canReserve: !penalized,
      // 오프셋 없는 문자열은 앱이 KST로 해석하므로 절대 시각(Z)으로 내려준다.
      penaltyExpiresAt: penalized ? until.toUtc().toIso8601String() : null,
    );
  }

  ActiveReservationModel _create(int userId, String room, int machineId) {
    final machine = _machines[machineId];
    if (machine == null) {
      throw httpError(404, '기기를 찾을 수 없습니다.');
    }
    if (!_availability(userId).canReserve) {
      throw httpError(409, '취소 패널티로 예약이 제한된 상태입니다.');
    }
    if (_rows.any((row) => row.isActive && row.userId == userId)) {
      throw httpError(409, '이미 활성 예약이 있습니다.');
    }
    if (_rows.any((row) => row.isActive && row.machine.id == machineId)) {
      throw httpError(409, '이미 예약되었거나 사용 중인 기기입니다.');
    }
    if (_rows.any(
      (row) =>
          row.isActive && row.room == room && row.machine.type == machine.type,
    )) {
      throw httpError(409, '같은 호실에 같은 종류의 활성 예약이 있습니다.');
    }

    final row = _ReservationRow(
      id: _nextReservationId++,
      userId: userId,
      room: room,
      machine: machine,
      status: 'RESERVED',
    );
    _rows.add(row);
    return _toModel(row);
  }

  CancelReservationResponse _cancel(int userId, int reservationId) {
    final row = _rows.firstWhereOrNull((r) => r.id == reservationId);
    if (row == null || row.userId != userId) {
      throw httpError(404, '예약을 찾을 수 없습니다.');
    }
    if (row.status == 'RUNNING') {
      throw httpError(409, '이미 사용이 시작된 예약은 취소할 수 없습니다.');
    }
    if (row.status != 'RESERVED') {
      throw httpError(409, '취소할 수 없는 상태의 예약입니다.');
    }

    row.status = 'CANCELLED';
    final until = DateTime.now().add(cancelPenalty);
    _penaltyUntil[userId] = until;
    return CancelReservationResponse(
      success: true,
      message: '예약이 취소되었습니다.',
      penaltyApplied: true,
      penaltyExpiresAt: until.toUtc().toIso8601String(),
    );
  }
}

class _StatusClient implements ReservationStatusRemoteDataSource {
  _StatusClient(this._server, this._userId, this._room);

  final MockWasherServer _server;
  final int _userId;
  final String _room;

  @override
  Future<MachineStatusResponse> getMachineStatus() =>
      _server._serve(Endpoint.machineStatus, _server._machineStatus);

  @override
  Future<List<ActiveReservationModel>> getActiveReservations() =>
      _server._serve(
        Endpoint.roomReservations,
        () => _server.activeInRoom(_room),
      );

  @override
  Future<ActiveReservationModel?> getMyActiveReservation() => _server._serve(
    Endpoint.myReservation,
    () => _server.activeOf(_userId),
  );

  @override
  Future<ReservationAvailabilityResponse> getReservationAvailability() =>
      _server._serve(
        Endpoint.availability,
        () => _server._availability(_userId),
      );
}

class _ActionsClient implements ReservationRemoteDataSource {
  _ActionsClient(this._server, this._userId, this._room);

  final MockWasherServer _server;
  final int _userId;
  final String _room;

  @override
  Future<ActiveReservationModel> createReservation({
    required int machineId,
    required String startTime,
  }) => _server._serve(
    Endpoint.create,
    () => _server._create(_userId, _room, machineId),
  );

  @override
  Future<CancelReservationResponse> cancelReservation({required int id}) =>
      _server._serve(Endpoint.cancel, () => _server._cancel(_userId, id));
}
