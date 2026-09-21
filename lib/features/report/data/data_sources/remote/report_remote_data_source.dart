import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:washer/core/network/dio_client.dart';

part 'report_remote_data_source.g.dart';

/// 고장 신고 API를 추상화한 데이터 소스
abstract class ReportRemoteDataSource {
  Future<void> createMalfunctionReport({
    required int machineId,
    required String description,
  });
}

/// Retrofit이 구현을 생성하는 고장 신고 REST API 정의
@RestApi()
abstract class ReportApiService {
  factory ReportApiService(Dio dio, {String baseUrl}) = _ReportApiService;

  @POST('malfunction-reports')
  Future<void> createMalfunctionReport(
    @Body() Map<String, dynamic> payload,
  );
}

/// [ReportApiService]를 사용하는 [ReportRemoteDataSource] 구현체
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
