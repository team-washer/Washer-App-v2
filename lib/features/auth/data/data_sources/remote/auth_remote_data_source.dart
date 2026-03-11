import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/features/auth/data/models/request/login_request.dart';
import 'package:washer/features/auth/data/models/request/refresh_request.dart';
import 'package:washer/features/auth/data/models/response/login_response.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponse> login(LoginRequest request);
  Future<LoginResponse> refresh(RefreshRequest request);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient _client;

  const AuthRemoteDataSourceImpl(this._client);

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _client.post(
      '/api/v2/auth/login',
      data: {'authCode': request.code},
    );
    return LoginResponse.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<LoginResponse> refresh(RefreshRequest request) async {
    final response = await _client.post(
      '/api/v2/auth/refresh',
      data: request.toJson(),
    );
    return LoginResponse.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.watch(dioClientProvider));
});
