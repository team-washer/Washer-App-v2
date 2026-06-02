import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:washer/core/network/api_response_parser.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/features/history/data/models/machine_history_response.dart';

part 'history_remote_data_source.g.dart';

abstract class HistoryRemoteDataSource {
  Future<MachineHistoryResponse> getMachineHistory({
    required int machineId,
    required String startDate,
    required String endDate,
    int page = 0,
    int size = 20,
  });
}

@RestApi()
abstract class HistoryApiService {
  factory HistoryApiService(Dio dio, {String baseUrl}) = _HistoryApiService;

  @GET('/api/v2/machines/{machineId}/history')
  Future<HttpResponse<dynamic>> getMachineHistory({
    @Path('machineId') required int machineId,
    @Query('startDate') required String startDate,
    @Query('endDate') required String endDate,
    @Query('page') int page = 0,
    @Query('size') int size = 20,
  });
}

class HistoryRemoteDataSourceImpl implements HistoryRemoteDataSource {
  const HistoryRemoteDataSourceImpl(this._api);

  final HistoryApiService _api;

  @override
  Future<MachineHistoryResponse> getMachineHistory({
    required int machineId,
    required String startDate,
    required String endDate,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _api.getMachineHistory(
      machineId: machineId,
      startDate: startDate,
      endDate: endDate,
      page: page,
      size: size,
    );
    final data = extractDataMap(castJsonMap(response.data));

    return MachineHistoryResponse.fromJson(data);
  }
}

final historyRemoteDataSourceProvider = Provider<HistoryRemoteDataSource>((
  ref,
) {
  return HistoryRemoteDataSourceImpl(HistoryApiService(ref.watch(dioProvider)));
});
