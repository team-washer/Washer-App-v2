import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:washer/core/network/api_response_parser.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/core/utils/background_task.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/remote/cancel_reservation_response.dart';
import 'package:washer/features/reservation/data/models/remote/confirm_reservation_response.dart';

part 'reservation_remote_data_source.g.dart';

abstract class ReservationRemoteDataSource {
  Future<ActiveReservationModel> createReservation({
    required int machineId,
    required String startTime,
  });

  Future<CancelReservationResponse> cancelReservation({
    required int id,
  });

  Future<ConfirmReservationResponse> confirmReservation({
    required int id,
  });
}

@RestApi()
abstract class ReservationApiService {
  factory ReservationApiService(Dio dio, {String baseUrl}) =
      _ReservationApiService;

  @POST('/api/v2/reservations')
  Future<HttpResponse<dynamic>> createReservation(
    @Body() Map<String, dynamic> payload,
  );

  @DELETE('/api/v2/reservations/{id}')
  Future<HttpResponse<dynamic>> cancelReservation(@Path('id') int id);

  @PUT('/api/v2/reservations/{id}/confirm')
  Future<HttpResponse<dynamic>> confirmReservation(@Path('id') int id);
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

    return runInBackground(() => ActiveReservationModel.fromJson(data));
  }

  @override
  Future<CancelReservationResponse> cancelReservation({
    required int id,
  }) async {
    final response = await _api.cancelReservation(id);
    final data = extractDataMap(castJsonMap(response.data));

    return runInBackground(() => CancelReservationResponse.fromJson(data));
  }

  @override
  Future<ConfirmReservationResponse> confirmReservation({
    required int id,
  }) async {
    final response = await _api.confirmReservation(id);
    final data = castJsonMap(response.data);

    return runInBackground(() => ConfirmReservationResponse.fromJson(data));
  }
}

final reservationRemoteDataSourceProvider =
    Provider<ReservationRemoteDataSource>((ref) {
      return ReservationRemoteDataSourceImpl(
        ReservationApiService(ref.watch(dioProvider)),
      );
    });
