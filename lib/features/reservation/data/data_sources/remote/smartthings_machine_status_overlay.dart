import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/reservation/data/data_sources/remote/smartthings_status_remote_data_source.dart';
import 'package:washer/features/reservation/data/data_sources/remote/smartthings_token_remote_data_source.dart';
import 'package:washer/features/reservation/data/models/local/laundry_machine_model.dart';
import 'package:washer/features/reservation/data/models/remote/smartthings_device_status.dart';

/// 서버가 내려준 기기 목록의 "운전 상태"만 SmartThings에서 직접 조회해 덮어쓴다.
///
/// 예약/가용성/사용자 정보 등 나머지는 서버 값을 그대로 유지한다.
/// SmartThings 호출이 실패한 기기는 서버 값을 그대로 사용한다(graceful degradation).
class SmartThingsMachineStatusOverlay {
  SmartThingsMachineStatusOverlay(this._ref);

  final Ref _ref;

  // SmartThings 의존성은 실제로 호출할 때만 해석한다.
  // (deviceId가 하나도 없으면 토큰/Dio 그래프를 전혀 건드리지 않도록 지연 로딩)
  SmartThingsTokenStore get _tokenStore =>
      _ref.read(smartThingsTokenStoreProvider);

  SmartThingsStatusRemoteDataSource get _statusDataSource =>
      _ref.read(smartThingsStatusRemoteDataSourceProvider);

  Future<MachineStatusResponse> apply(MachineStatusResponse base) async {
    final machines = base.machines;
    final hasDeviceId = machines.any(
      (m) => (m.smartThingsDeviceId ?? '').trim().isNotEmpty,
    );
    if (!hasDeviceId) {
      return base;
    }

    final tokenStore = _tokenStore;
    final String token;
    try {
      token = await tokenStore.getAccessToken();
    } catch (e, st) {
      AppLogger.error(
        'SmartThings 토큰을 가져오지 못했습니다. 서버 상태를 사용합니다.',
        name: 'SmartThingsOverlay',
        error: e,
        stackTrace: st,
      );
      return base;
    }

    final overlaid = await _overlayAll(machines, token);
    return base.copyWith(machines: overlaid);
  }

  Future<List<MachineModel>> _overlayAll(
    List<MachineModel> machines,
    String token,
  ) async {
    final statusDataSource = _statusDataSource;
    final tokenStore = _tokenStore;
    // 병렬 조회 중 401이 나면 한 기기가 토큰을 갱신하고, 나머지는 갱신된
    // activeToken을 재사용한다. (토큰 스토어가 in-flight 요청을 공유)
    var activeToken = token;

    Future<MachineModel> overlayOne(MachineModel machine) async {
      final deviceId = machine.smartThingsDeviceId?.trim();
      if (deviceId == null || deviceId.isEmpty) {
        return machine;
      }

      final tokenUsed = activeToken;
      try {
        final status = await statusDataSource.getDeviceStatus(
          deviceId,
          tokenUsed,
        );
        return _merge(machine, status);
      } on DioException catch (e, st) {
        // 토큰 만료(401): 아직 아무도 갱신하지 않았다면 강제 갱신하고,
        // 갱신된(또는 다른 기기가 이미 갱신한) 새 토큰으로 1회 재시도한다.
        if (e.response?.statusCode == 401) {
          try {
            if (activeToken == tokenUsed) {
              activeToken = await tokenStore.getAccessToken(forceRefresh: true);
            }
            if (activeToken != tokenUsed) {
              final status = await statusDataSource.getDeviceStatus(
                deviceId,
                activeToken,
              );
              return _merge(machine, status);
            }
          } catch (e2, st2) {
            AppLogger.error(
              'SmartThings 토큰 갱신/재조회 실패 (deviceId=$deviceId). 서버 상태 유지.',
              name: 'SmartThingsOverlay',
              error: e2,
              stackTrace: st2,
            );
            return machine;
          }
        }
        AppLogger.error(
          'SmartThings 상태 조회 실패 (deviceId=$deviceId). 서버 상태 유지.',
          name: 'SmartThingsOverlay',
          error: e,
          stackTrace: st,
        );
        return machine;
      } catch (e, st) {
        AppLogger.error(
          'SmartThings 상태 파싱 실패 (deviceId=$deviceId). 서버 상태 유지.',
          name: 'SmartThingsOverlay',
          error: e,
          stackTrace: st,
        );
        return machine;
      }
    }

    return Future.wait(machines.map(overlayOne));
  }

  MachineModel _merge(MachineModel machine, SmartThingsDeviceStatus status) {
    if (status.isEmpty) {
      return machine;
    }

    return machine.copyWith(
      operatingState: status.jobState ?? machine.operatingState,
      jobState: status.jobState ?? machine.jobState,
      switchStatus: status.switchStatus ?? machine.switchStatus,
      expectedCompletionTime:
          status.completionTime ?? machine.expectedCompletionTime,
    );
  }
}

final smartThingsMachineStatusOverlayProvider =
    Provider<SmartThingsMachineStatusOverlay>((ref) {
      return SmartThingsMachineStatusOverlay(ref);
    });
