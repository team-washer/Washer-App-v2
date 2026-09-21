import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:washer/core/network/api_response_parser.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/remote/cancel_reservation_response.dart';

part 'reservation_remote_data_source.g.dart';

/// 예약 생성/취소(변경 요청)를 담당하는 원격 데이터소스.
abstract class ReservationRemoteDataSource {
  Future<ActiveReservationModel> createReservation({
    required int machineId,
    required String startTime,
  });

  Future<CancelReservationResponse> cancelReservation({
    required int id,
  });
}

@RestApi()
abstract class ReservationApiService {
  factory ReservationApiService(Dio dio, {String baseUrl}) =
      _ReservationApiService;

  @POST('reservations')
  Future<HttpResponse<dynamic>> createReservation(
    @Body() Map<String, dynamic> payload,
  );

  @DELETE('reservations/{id}')
  Future<HttpResponse<dynamic>> cancelReservation(@Path('id') int id);
}

class ReservationRemoteDataSourceImpl implements ReservationRemoteDataSource {
  const ReservationRemoteDataSourceImpl(this._api);

  final ReservationApiService _api;

  @override
  Future<ActiveReservationModel> createReservation({
    required int machineId,
    required String startTime,
  }) async {
    final payload = {
      'machineId': machineId,
      'startTime': startTime,
    };
    final response = await _api.createReservation(payload);
    final data = extractDataMap(castJsonMap(response.data));

    return ActiveReservationModel.fromJson(data);
  }

  @override
  Future<CancelReservationResponse> cancelReservation({
    required int id,
  }) async {
    final response = await _api.cancelReservation(id);
    final data = castJsonMap(response.data);

    return CancelReservationResponse.fromJson(data);
  }
}

final reservationRemoteDataSourceProvider =
    Provider<ReservationRemoteDataSource>((ref) {
      return ReservationRemoteDataSourceImpl(
        ReservationApiService(ref.watch(dioProvider)),
      );
    });
