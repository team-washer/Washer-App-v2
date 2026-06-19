import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:washer/core/network/api_response_parser.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/features/app_version/data/models/app_version_status_model.dart';

part 'app_version_remote_data_source.g.dart';

abstract class AppVersionRemoteDataSource {
  /// 현재 앱의 플랫폼/버전을 서버에 보내 업데이트 필요 여부를 조회한다.
  Future<AppVersionStatusModel?> getStatus({
    required String platform,
    required int versionCode,
    String? versionName,
  });
}

@RestApi()
abstract class AppVersionApiService {
  factory AppVersionApiService(Dio dio, {String baseUrl}) = _AppVersionApiService;

  @GET('/app-versions/status')
  Future<HttpResponse<dynamic>> getStatus(
    @Query('platform') String platform,
    @Query('versionCode') int versionCode,
    @Query('versionName') String? versionName,
  );
}

class AppVersionRemoteDataSourceImpl implements AppVersionRemoteDataSource {
  const AppVersionRemoteDataSourceImpl(this._api);

  final AppVersionApiService _api;

  @override
  Future<AppVersionStatusModel?> getStatus({
    required String platform,
    required int versionCode,
    String? versionName,
  }) async {
    final response = await _api.getStatus(platform, versionCode, versionName);
    final body = castJsonMap(response.data);

    // 다른 엔드포인트와 동일하게 `{ data: {...} }` 봉투를 우선 처리하되,
    // 봉투 없이 DTO를 그대로 내려주는 경우도 안전하게 파싱한다.
    final data = body.containsKey('data')
        ? extractNullableDataMap(body)
        : body;
    if (data == null) {
      return null;
    }

    return AppVersionStatusModel.fromJson(data);
  }
}

final appVersionRemoteDataSourceProvider = Provider<AppVersionRemoteDataSource>((
  ref,
) {
  return AppVersionRemoteDataSourceImpl(
    AppVersionApiService(ref.watch(dioProvider)),
  );
});
