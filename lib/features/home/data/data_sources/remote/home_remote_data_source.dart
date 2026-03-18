import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:washer/core/network/api_response_parser.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/core/utils/background_task.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/local/laundry_machine_model.dart';

part 'home_remote_data_source.g.dart';

abstract class HomeRemoteDataSource {
  Future<MachineStatusResponse> getMachineStatus();
  Future<ActiveReservationModel?> getActiveReservation();
}

@RestApi()
abstract class HomeApiService {
  factory HomeApiService(Dio dio, {String baseUrl}) = _HomeApiService;

  @GET('/api/v2/machines/status')
  Future<HttpResponse<dynamic>> getMachineStatus();

  @GET('/api/v2/reservations/active')
  Future<HttpResponse<dynamic>> getActiveReservation();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  const HomeRemoteDataSourceImpl(this._api);

  final HomeApiService _api;

  @override
  Future<MachineStatusResponse> getMachineStatus() async {
    final response = await _api.getMachineStatus();
    final data = extractDataMap(castJsonMap(response.data));

    return runInBackground(() => MachineStatusResponse.fromJson(data));
  }

  @override
  Future<ActiveReservationModel?> getActiveReservation() async {
    try {
      final response = await _api.getActiveReservation();
      if (response.response.statusCode == 204 || response.data == null) {
        return null;
      }

      final data = extractNullableDataMap(castJsonMap(response.data));
      if (data == null) {
        return null;
      }

      return runInBackground(() => ActiveReservationModel.fromJson(data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 204) {
        return null;
      }
      rethrow;
    }
  }
}

final homeRemoteDataSourceProvider = Provider<HomeRemoteDataSource>((ref) {
  return HomeRemoteDataSourceImpl(HomeApiService(ref.watch(dioProvider)));
});