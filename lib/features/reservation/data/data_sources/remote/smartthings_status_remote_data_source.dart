import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:washer/core/network/api_response_parser.dart';
import 'package:washer/features/reservation/data/models/remote/smartthings_device_status.dart';

part 'smartthings_status_remote_data_source.g.dart';

/// SmartThings 공개 API 베이스 URL.
const String kSmartThingsApiBaseUrl = 'https://api.smartthings.com/v1';

abstract class SmartThingsStatusRemoteDataSource {
  Future<SmartThingsDeviceStatus> getDeviceStatus(
    String deviceId,
    String accessToken,
  );
}

@RestApi()
abstract class SmartThingsStatusApiService {
  factory SmartThingsStatusApiService(Dio dio, {String baseUrl}) =
      _SmartThingsStatusApiService;

  @GET('/devices/{deviceId}/status')
  Future<HttpResponse<dynamic>> getDeviceStatus(
    @Path('deviceId') String deviceId,
    @Header('Authorization') String authorization,
  );
}

class SmartThingsStatusRemoteDataSourceImpl
    implements SmartThingsStatusRemoteDataSource {
  const SmartThingsStatusRemoteDataSourceImpl(this._api);

  final SmartThingsStatusApiService _api;

  @override
  Future<SmartThingsDeviceStatus> getDeviceStatus(
    String deviceId,
    String accessToken,
  ) async {
    final response = await _api.getDeviceStatus(deviceId, 'Bearer $accessToken');
    return SmartThingsDeviceStatus.fromJson(castJsonMap(response.data));
  }
}

/// SmartThings 직접 호출 전용 Dio.
///
/// 우리 서버용 [AuthInterceptor]를 붙이지 않는다.
/// (서버 토큰/리프레시 체계와 SmartThings 인증은 완전히 별개이기 때문)
final smartThingsDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: kSmartThingsApiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {'Accept': 'application/json'},
    ),
  );
});

final smartThingsStatusRemoteDataSourceProvider =
    Provider<SmartThingsStatusRemoteDataSource>((ref) {
      return SmartThingsStatusRemoteDataSourceImpl(
        SmartThingsStatusApiService(ref.watch(smartThingsDioProvider)),
      );
    });
