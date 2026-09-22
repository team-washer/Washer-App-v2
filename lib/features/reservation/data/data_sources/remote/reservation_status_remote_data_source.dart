import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:washer/core/network/api_response_parser.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/local/machine_model.dart';
import 'package:washer/features/reservation/data/models/remote/reservation_availability_response.dart';

part 'reservation_status_remote_data_source.g.dart';

/// 기기 상태와 활성 예약 조회(GET)를 담당하는 원격 데이터소스.
abstract class ReservationStatusRemoteDataSource {
  Future<MachineStatusResponse> getMachineStatus();

  /// 내 호실의 활성 예약 목록(`reservations/active/room`).
  /// 홈 최초 진입 시 한 번 불러온다. 없으면 빈 목록이다.
  Future<List<ActiveReservationModel>> getActiveReservations();

  /// 내 활성 예약 한 건(`reservations/active`). polling 전용이다.
  /// 서버는 활성 예약이 없으면 `data`를 null로 내려주므로 null을 반환한다.
  Future<ActiveReservationModel?> getMyActiveReservation();

  /// 내 예약 가능 여부와 패널티 만료 시각(`reservations/availability`).
  Future<ReservationAvailabilityResponse> getReservationAvailability();
}

@RestApi()
abstract class ReservationStatusApiService {
  factory ReservationStatusApiService(Dio dio, {String baseUrl}) =
      _ReservationStatusApiService;

  @GET('machines/status')
  Future<HttpResponse<dynamic>> getMachineStatus();

  @GET('reservations/active/room')
  Future<HttpResponse<dynamic>> getActiveReservations();

  @GET('reservations/active')
  Future<HttpResponse<dynamic>> getMyActiveReservation();

  @GET('reservations/availability')
  Future<HttpResponse<dynamic>> getReservationAvailability();
}

/// 기기 현황·활성 예약 조회 구현체.
///
/// 서버 계약: 활성 예약이 없으면 호실 조회는 200 + `data.reservations: []`,
/// 내 예약 조회는 200 + `data: null`이다. 404는 사용자·예약·기기가 없는 **오류**이고
/// "없음"이 아니다. 451(이용 대상이 아닌 사용자)만 빈 결과로 대체한다.
/// 204 처리는 서버가 보장하지 않는 응답에 대한 방어 코드다.
class ReservationStatusRemoteDataSourceImpl
    implements ReservationStatusRemoteDataSource {
  const ReservationStatusRemoteDataSourceImpl(this._api);

  final ReservationStatusApiService _api;

  @override
  Future<MachineStatusResponse> getMachineStatus() async {
    try {
      final response = await _api.getMachineStatus();
      final data = extractDataMap(castJsonMap(response.data));

      return MachineStatusResponse.fromJson(data);
    } on DioException catch (e) {
      // 451: 서비스 이용 불가 상태이므로 빈 목록으로 대체한다.
      if (e.response?.statusCode == 451) {
        return const MachineStatusResponse(machines: [], totalCount: 0);
      }
      rethrow;
    }
  }

  @override
  Future<List<ActiveReservationModel>> getActiveReservations() async {
    try {
      final response = await _api.getActiveReservations();
      if (response.response.statusCode == 204 || response.data == null) {
        return const [];
      }

      // 서버가 `data`를 `{reservations: [...]}` 또는 배열 그대로 내려줘도 모두 받는다.
      final data = castJsonMap(response.data)['data'];
      final Object? reservations = switch (data) {
        List() => data,
        Map() => data['reservations'],
        _ => null,
      };
      if (reservations is! List || reservations.isEmpty) {
        return const [];
      }

      return reservations
          .map((item) => ActiveReservationModel.fromJson(castJsonMap(item)))
          .toList(growable: false);
    } on DioException catch (e) {
      // 451: 이용 대상이 아닌 사용자라 활성 예약이 있을 수 없으므로 빈 목록으로 본다.
      if (e.response?.statusCode == 451) {
        return const [];
      }
      rethrow;
    }
  }

  @override
  Future<ActiveReservationModel?> getMyActiveReservation() async {
    try {
      final response = await _api.getMyActiveReservation();
      // 활성 예약이 없으면 서버가 200 + data null로 내려준다(204/빈 본문은 방어 코드).
      // 404 등 오류 응답은 "없음"이 아니라 조회 실패이므로 그대로 던진다.
      if (response.response.statusCode == 204 || response.data == null) {
        return null;
      }

      final data = extractNullableDataMap(castJsonMap(response.data));
      return data == null ? null : ActiveReservationModel.fromJson(data);
    } on DioException catch (e) {
      // 451: 이용 대상이 아닌 사용자는 활성 예약이 없다.
      if (e.response?.statusCode == 451) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<ReservationAvailabilityResponse> getReservationAvailability() async {
    final response = await _api.getReservationAvailability();
    final body = castJsonMap(response.data);
    // 응답이 `{data: {...}}`로 감싸져 있든 본문 자체든 받을 수 있게 한다.
    final data = body['data'] is Map ? castJsonMap(body['data']) : body;

    return ReservationAvailabilityResponse.fromJson(data);
  }
}

final reservationStatusRemoteDataSourceProvider =
    Provider<ReservationStatusRemoteDataSource>((ref) {
      final dio = ref.watch(dioProvider);
      return ReservationStatusRemoteDataSourceImpl(
        ReservationStatusApiService(dio),
      );
    });
