import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:washer/core/network/api_response_parser.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/core/utils/background_task.dart';
import 'package:washer/features/auth/data/models/request/login_request.dart';
import 'package:washer/features/auth/data/models/request/refresh_request.dart';
import 'package:washer/features/auth/data/models/response/login_response.dart';

part 'auth_remote_data_source.g.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponse> login(LoginRequest request);
  Future<LoginResponse> refresh(RefreshRequest request);
}

@RestApi()
abstract class AuthApiService {
  factory AuthApiService(Dio dio, {String baseUrl}) = _AuthApiService;

  @POST('/api/v2/auth/login')
  Future<HttpResponse<dynamic>> login(@Body() Map<String, dynamic> payload);

  @POST('/api/v2/auth/refresh')
  Future<HttpResponse<dynamic>> refresh(@Body() Map<String, dynamic> payload);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._api);

  final AuthApiService _api;

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    final payload = {
      'authCode': request.code,
    };
    final response = await _api.login(payload);
    final data = extractDataMap(castJsonMap(response.data));

    return runInBackground(() => LoginResponse.fromJson(data));
  }

  @override
  Future<LoginResponse> refresh(RefreshRequest request) async {
    final payload = await runInBackground(request.toJson);
    final response = await _api.refresh(payload);
    final data = extractDataMap(castJsonMap(response.data));

    return runInBackground(() => LoginResponse.fromJson(data));
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(AuthApiService(ref.watch(dioProvider)));
});
