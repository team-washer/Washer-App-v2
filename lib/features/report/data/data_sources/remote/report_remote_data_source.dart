import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:washer/core/network/dio_client.dart';

part 'report_remote_data_source.g.dart';

abstract class ReportRemoteDataSource {
  Future<void> createMalfunctionReport({
    required int machineId,
    required String description,
  });
}

@RestApi()
abstract class ReportApiService {
  factory ReportApiService(Dio dio, {String baseUrl}) = _ReportApiService;

  @POST('/api/v2/malfunction-reports')
  Future<void> createMalfunctionReport(
    @Body() Map<String, dynamic> payload,
  );
}

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  const ReportRemoteDataSourceImpl(this._api);

  final ReportApiService _api;

  @override
  Future<void> createMalfunctionReport({
    required int machineId,
    required String description,
  }) async {
    final payload = {
      'machineId': machineId,
      'description': description,
    };

    await _api.createMalfunctionReport(payload);
  }
}

final reportRemoteDataSourceProvider = Provider<ReportRemoteDataSource>((ref) {
  return ReportRemoteDataSourceImpl(ReportApiService(ref.watch(dioProvider)));
});
