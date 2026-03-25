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
  Future<List<ActiveReservationModel>> getActiveReservations();
}

@RestApi()
abstract class HomeApiService {
  factory HomeApiService(Dio dio, {String baseUrl}) = _HomeApiService;

  @GET('/api/v2/machines/status')
  Future<HttpResponse<dynamic>> getMachineStatus();

  @GET('/api/v2/reservations/active/room')
  Future<HttpResponse<dynamic>> getActiveReservations();
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

      return runInBackground(
        () => reservations
            .map((item) => ActiveReservationModel.fromJson(castJsonMap(item)))
            .toList(growable: false),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 204) {
        return const [];
      }
      rethrow;
    }
  }
}

final homeRemoteDataSourceProvider = Provider<HomeRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return HomeRemoteDataSourceImpl(HomeApiService(dio));
});
