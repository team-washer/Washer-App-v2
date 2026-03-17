import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/core/utils/background_task.dart';
import 'package:washer/features/history/data/models/machine_history_response.dart';

abstract class HistoryRemoteDataSource {
  Future<MachineHistoryResponse> getMachineHistory({
    required int machineId,
    required String startDate,
    required String endDate,
    int page = 0,
    int size = 20,
  });
}

class HistoryRemoteDataSourceImpl implements HistoryRemoteDataSource {
  const HistoryRemoteDataSourceImpl(this._client);

  final DioClient _client;

  @override
  Future<MachineHistoryResponse> getMachineHistory({
    required int machineId,
    required String startDate,
    required String endDate,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get(
      '/api/v2/machines/$machineId/history',
      queryParameters: {
        'startDate': startDate,
        'endDate': endDate,
        'page': page,
        'size': size,
      },
    );
    final data = Map<String, dynamic>.from(response.data['data'] as Map);

    return runInBackground(() => MachineHistoryResponse.fromJson(data));
  }
}

final historyRemoteDataSourceProvider = Provider<HistoryRemoteDataSource>((ref) {
  return HistoryRemoteDataSourceImpl(ref.watch(dioClientProvider));
});