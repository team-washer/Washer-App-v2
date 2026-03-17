import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/core/utils/background_task.dart';

abstract class ReportRemoteDataSource {
  Future<void> createMalfunctionReport({
    required int machineId,
    required String description,
  });
}

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  const ReportRemoteDataSourceImpl(this._client);

  final DioClient _client;

  @override
  Future<void> createMalfunctionReport({
    required int machineId,
    required String description,
  }) async {
    final payload = await runInBackground(
      () => <String, dynamic>{
        'machineId': machineId,
        'description': description,
      },
    );

    await _client.post(
      '/api/v2/malfunction-reports',
      data: payload,
    );
  }
}

final reportRemoteDataSourceProvider = Provider<ReportRemoteDataSource>((ref) {
  return ReportRemoteDataSourceImpl(ref.watch(dioClientProvider));
});