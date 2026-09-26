import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:washer/core/network/error.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/local/machine_model.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_status_remote_data_source.dart';
import 'package:washer/features/reservation/presentation/providers/my_reservation_update.dart';

/// 1초마다 현재 시각을 내보내는 시계. 카운트다운 UI가 구독한다.
final clockProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

/// polling/조회 실패 시 사용자에게 보여줄 오류. 없으면 null.
final pollingErrorProvider = StateProvider<AppException?>((ref) => null);

/// 기기 상태와 활성 예약을 함께 새로고침한다(Provider 내부에서 사용).
Future<void> refreshReservationStatusProviders(Ref ref) {
  return Future.wait([
    ref.read(machineStatusProvider.notifier).refresh(),
    ref.read(activeReservationProvider.notifier).refresh(),
  ]);
}

/// 기기 상태와 활성 예약을 함께 새로고침한다(위젯에서 사용).
Future<void> refreshReservationStatusWidgets(WidgetRef ref) {
  return Future.wait([
    ref.read(machineStatusProvider.notifier).refresh(),
    ref.read(activeReservationProvider.notifier).refresh(),
  ]);
}

/// Dio 오류를 사용자용 문구로 변환한다. 안내할 필요가 없는 오류면 null.
///
/// 상태 코드별 문구는 서버 오류 응답 계약을 따른다(자세한 계약은 [AppException] 참고).
AppException? _pollingErrorFor(DioException error) {
  // 인증 갱신에 실패해 요청 자체가 취소된 경우다. 로그아웃 흐름이 처리하므로
  // 여기서 "네트워크 오류" 같은 잘못된 안내를 띄우지 않는다.
  if (error.type == DioExceptionType.cancel) {
    return null;
  }

  final statusCode = error.response?.statusCode;
  if (statusCode != null && statusCode >= 500) {
    // 502(기기 서비스 실패)/503(일시 장애)은 원인별 문구를, 그 외 5xx는 코드를 보여준다.
    if (statusCode == 502 || statusCode == 503) {
      return AppException.from(error);
    }
    return AppException(
      message: '서버 오류가 발생했습니다. ($statusCode)',
      statusCode: statusCode,
    );
  }

  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout) {
    return AppException(message: '서버 응답 시간이 초과되었습니다.');
  }

  if (error.type == DioExceptionType.connectionError) {
    final rawError = error.error;
    if (rawError is SocketException) {
      if (rawError.message.contains('Connection refused')) {
        return AppException(message: '서버 연결이 거부되었습니다. 서버 상태를 확인해주세요.');
      }
      return AppException(message: '네트워크 연결에 실패했습니다. 인터넷 또는 서버 상태를 확인해주세요.');
    }

    return AppException(message: '네트워크 연결에 실패했습니다.');
  }

  if (error.response == null) {
    return AppException(message: '네트워크 오류가 발생했습니다.');
  }

  // 4xx(400 검증, 401 인증, 403 권한, 404 없음, 409 충돌 등)는 상태 코드별 고정 문구를 쓴다.
  return AppException.from(error);
}

/// 전체 기기 상태 provider.
final machineStatusProvider =
    AsyncNotifierProvider<MachineStatusNotifier, MachineStatusResponse>(
      MachineStatusNotifier.new,
    );

/// 서버의 기기 상태를 불러오고 새로고침한다. keepAlive로 화면 이동 시에도 유지된다.
class MachineStatusNotifier extends AsyncNotifier<MachineStatusResponse> {
  Future<MachineStatusResponse> _load() async {
    return ref
        .read(reservationStatusRemoteDataSourceProvider)
        .getMachineStatus();
  }

  @override
  Future<MachineStatusResponse> build() async {
    ref.keepAlive();
    try {
      return await _load();
    } on DioException catch (e, st) {
      AppLogger.error(
        '기기 상태를 불러오는 중 오류가 발생했습니다.',
        name: 'MachineStatusNotifier',
        error: e,
        stackTrace: st,
      );
      final pollingError = _pollingErrorFor(e);
      if (pollingError != null) {
        ref.read(pollingErrorProvider.notifier).state = pollingError;
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final machineStatus = await _load();
      state = AsyncData(machineStatus);
    } on DioException catch (e, st) {
      AppLogger.error(
        '기기 상태를 새로고침하는 중 오류가 발생했습니다.',
        name: 'MachineStatusNotifier',
        error: e,
        stackTrace: st,
      );
      final pollingError = _pollingErrorFor(e);
      if (pollingError != null) {
        ref.read(pollingErrorProvider.notifier).state = pollingError;
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

/// 내 방의 활성 예약 목록 provider.
final activeReservationProvider =
    AsyncNotifierProvider<
      ActiveReservationNotifier,
      List<ActiveReservationModel>
    >(
      ActiveReservationNotifier.new,
    );

/// 활성 예약 목록을 불러오고 새로고침한다.
///
/// 이 목록은 호실 목록 요청(`reservations/active/room`)과 polling(내 활성 예약)이
/// 함께 갱신한다. 두 요청의 응답이 도착하는 순서는 보장되지 않으므로, 요청을 시작할 때마다
/// 순번(요청 id)을 부여하고 **늦게 시작한 요청의 결과가 오래된 결과를 이기게** 한다.
///
/// - 호실 스냅샷: 이미 반영된 것보다 먼저 시작한 요청의 응답은 버린다.
/// - 내 예약(polling): 이미 반영된 것보다 먼저 시작한 응답은 버린다. 호실 목록 응답을
///   기다리는 중이면 결과만 기록해 두고, 스냅샷이 도착할 때 그 위에 겹쳐 쓴다.
class ActiveReservationNotifier
    extends AsyncNotifier<List<ActiveReservationModel>> {
  bool _hasFetched = false;

  /// 요청을 시작한 순서. [beginRequest]가 부를 때마다 1씩 증가한다.
  int _requestSeq = 0;

  /// 지금까지 반영한 호실 스냅샷 중 가장 늦게 시작한 요청의 id.
  int _appliedRoomRequestId = 0;

  /// 지금까지 반영한 내 예약(polling) 결과 중 가장 늦게 시작한 요청의 id.
  int _appliedMineRequestId = 0;

  /// 아직 응답이 오지 않은 호실 목록 요청 수.
  int _roomRequestsInFlight = 0;

  /// 가장 최근에 반영한 내 예약(polling) 결과. 호실 스냅샷 위에 겹쳐 쓰는 데 쓴다.
  MyReservationUpdate? _latestMyUpdate;

  /// 마지막으로 반영한 호실 목록.
  List<ActiveReservationModel> _latestList = const [];

  /// 요청을 시작할 때 부른다. 시작 순서를 나타내는 요청 id를 돌려준다.
  int beginRequest() => ++_requestSeq;

  @override
  Future<List<ActiveReservationModel>> build() async {
    ref.keepAlive();
    final requestId = beginRequest();
    _roomRequestsInFlight += 1;
    try {
      _hasFetched = true;
      final snapshot = await ref
          .read(reservationStatusRemoteDataSourceProvider)
          .getActiveReservations();
      // 더 늦게 시작한 새로고침이 먼저 반영됐다면 그 목록을 유지한다.
      return _resolveRoomSnapshot(requestId, snapshot) ?? _latestList;
    } on DioException catch (e, st) {
      AppLogger.error(
        '활성 예약을 불러오는 중 오류가 발생했습니다.',
        name: 'ActiveReservationNotifier',
        error: e,
        stackTrace: st,
      );
      final pollingError = _pollingErrorFor(e);
      if (pollingError != null) {
        ref.read(pollingErrorProvider.notifier).state = pollingError;
      }
      rethrow;
    } finally {
      _roomRequestsInFlight -= 1;
    }
  }

  /// 아직 불러온 적이 없을 때만 호실 활성 예약 목록(`reservations/active/room`)을 조회한다.
  /// 홈 최초 진입 시 호출되며, 이후 변경은 polling이 내 예약만 조회해 이 목록에 반영한다.
  Future<void> ensureLoaded() async {
    if (_hasFetched || state.isLoading) {
      return;
    }

    await refresh();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final requestId = beginRequest();
    _roomRequestsInFlight += 1;
    try {
      _hasFetched = true;
      final snapshot = await ref
          .read(reservationStatusRemoteDataSourceProvider)
          .getActiveReservations();
      final resolved = _resolveRoomSnapshot(requestId, snapshot);
      if (resolved != null) {
        state = AsyncData(resolved);
      }
    } on DioException catch (e, st) {
      AppLogger.error(
        '활성 예약을 새로고침하는 중 오류가 발생했습니다.',
        name: 'ActiveReservationNotifier',
        error: e,
        stackTrace: st,
      );
      final pollingError = _pollingErrorFor(e);
      if (pollingError != null) {
        ref.read(pollingErrorProvider.notifier).state = pollingError;
      }
      _setErrorIfLatest(requestId, e, st);
    } catch (e, st) {
      AppLogger.error(
        '활성 예약을 새로고침하는 중 오류가 발생했습니다.',
        name: 'ActiveReservationNotifier',
        error: e,
        stackTrace: st,
      );
      _setErrorIfLatest(requestId, e, st);
    } finally {
      _roomRequestsInFlight -= 1;
    }
  }

  /// 화면을 로딩 상태로 바꾸지 않고 호실 목록을 다시 불러와 맞춘다.
  ///
  /// polling은 내 예약만 조회하므로 룸메이트 예약의 변화는 이 재조회로 반영한다.
  /// [refresh]와 달리 `AsyncLoading`을 거치지 않아 카드에 스피너가 깜빡이지 않고,
  /// 실패해도 화면 상태나 안내 문구를 바꾸지 않고 로그만 남긴다.
  Future<void> reloadInBackground() async {
    final requestId = beginRequest();
    _roomRequestsInFlight += 1;
    try {
      final before = _latestList;
      final snapshot = await ref
          .read(reservationStatusRemoteDataSourceProvider)
          .getActiveReservations();
      final resolved = _resolveRoomSnapshot(requestId, snapshot);
      if (resolved != null &&
          (!state.hasValue || !listEquals(before, resolved))) {
        _hasFetched = true;
        state = AsyncData(resolved);
      }
    } catch (e, st) {
      AppLogger.error(
        '호실 활성 예약 백그라운드 동기화 중 오류가 발생했습니다.',
        name: 'ActiveReservationNotifier',
        error: e,
        stackTrace: st,
      );
    } finally {
      _roomRequestsInFlight -= 1;
    }
  }

  /// polling으로 확인한 내 활성 예약 결과를 호실 목록에 반영한다.
  ///
  /// 이미 반영된 더 최근 결과(내 예약 polling 또는 호실 스냅샷)보다 먼저 시작한 요청의
  /// 응답이면 버리고 `isStale`을 true로 돌려준다.
  MyReservationApplyResult applyMyReservation(MyReservationUpdate update) {
    if (update.requestId < _appliedMineRequestId ||
        update.requestId < _appliedRoomRequestId) {
      return const MyReservationApplyResult(isStale: true, hasChanged: false);
    }
    _appliedMineRequestId = update.requestId;
    _latestMyUpdate = update;

    // 호실 목록 응답을 기다리는 중이면 지금 목록은 곧 교체된다. 결과만 기록해 두고
    // 스냅샷이 도착할 때 그 위에 겹쳐 쓴다. 변경 여부는 알 수 없으므로 changed로 본다.
    if (_roomRequestsInFlight > 0) {
      return const MyReservationApplyResult(isStale: false, hasChanged: true);
    }

    final merged = update.applyTo(_latestList);
    final hasChanged = !listEquals(_latestList, merged);
    if (hasChanged) {
      _hasFetched = true;
      _latestList = merged;
      state = AsyncData(merged);
    }
    return MyReservationApplyResult(isStale: false, hasChanged: hasChanged);
  }

  /// 호실 스냅샷을 반영할 목록으로 정리한다. 더 늦게 시작한 스냅샷이 이미 반영됐다면 null.
  ///
  /// 이 스냅샷보다 늦게 시작한 내 예약(polling) 결과가 있으면, 스냅샷이 그 이전 시점의
  /// 서버 상태이므로 내 예약만 그 결과로 다시 겹쳐 쓴다.
  List<ActiveReservationModel>? _resolveRoomSnapshot(
    int requestId,
    List<ActiveReservationModel> snapshot,
  ) {
    if (requestId < _appliedRoomRequestId) {
      return null;
    }
    _appliedRoomRequestId = requestId;

    final update = _latestMyUpdate;
    final resolved = update != null && update.requestId > requestId
        ? update.applyTo(snapshot)
        : snapshot;
    _latestList = resolved;
    return resolved;
  }

  /// 더 늦게 시작한 호실 요청이 이미 반영됐다면, 이 오래된 요청의 오류는 무시한다.
  void _setErrorIfLatest(int requestId, Object error, StackTrace stackTrace) {
    if (requestId >= _appliedRoomRequestId) {
      state = AsyncError(error, stackTrace);
    }
  }
}
