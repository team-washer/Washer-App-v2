import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/core/utils/background_task.dart';
import 'package:washer/features/auth/data/models/request/login_request.dart';
import 'package:washer/features/auth/data/models/request/refresh_request.dart';
import 'package:washer/features/auth/data/models/response/login_response.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponse> login(LoginRequest request, String codeVerifier);
  Future<LoginResponse> refresh(RefreshRequest request);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client);

  final DioClient _client;

  @override
  Future<LoginResponse> login(LoginRequest request, String codeVerifier) async {
    final payload = await runInBackground(
      () => <String, dynamic>{'authCode': request.code},
    );
    final response = await _client.post(
      '/api/v2/auth/login',
      data: payload,
    );
    final data = Map<String, dynamic>.from(response.data['data'] as Map);

    return runInBackground(() => LoginResponse.fromJson(data));
  }

  @override
  Future<LoginResponse> refresh(RefreshRequest request) async {
    final payload = await runInBackground(request.toJson);
    final response = await _client.post(
      '/api/v2/auth/refresh',
      data: payload,
    );
    final data = Map<String, dynamic>.from(response.data['data'] as Map);

    return runInBackground(() => LoginResponse.fromJson(data));
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.watch(dioClientProvider));
});