import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/network/dio_client.dart';

abstract class ReportRemoteDataSource {
  Future<void> createMalfunctionReport({
    required int machineId,
    required String description,
  });
}

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  final DioClient _client;

  const ReportRemoteDataSourceImpl(this._client);

  @override
  Future<void> createMalfunctionReport({
    required int machineId,
    required String description,
  }) async {
    await _client.post(
      '/api/v2/malfunction-reports',
      data: {
        'machineId': machineId,
        'description': description,
      },
    );
  }
}

final reportRemoteDataSourceProvider = Provider<ReportRemoteDataSource>((ref) {
  return ReportRemoteDataSourceImpl(ref.watch(dioClientProvider));
});
