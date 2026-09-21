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
  Future<List<ActiveReservationModel>> getActiveReservations();

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

  @GET('reservations/availability')
  Future<HttpResponse<dynamic>> getReservationAvailability();
}

/// 서버 응답 코드(204/404/451)를 빈 결과로 변환하는 구현체.
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

      final responseMap = castJsonMap(response.data);
      final data = extractDataMap(responseMap);
      final reservations = data['reservations'];
      if (reservations is! List || reservations.isEmpty) {
        return const [];
      }

      return reservations
          .map((item) => ActiveReservationModel.fromJson(castJsonMap(item)))
          .toList(growable: false);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 404 || statusCode == 204 || statusCode == 451) {
        return const [];
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
