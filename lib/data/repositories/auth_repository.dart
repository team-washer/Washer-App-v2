import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/data/data_sources/remote/auth_remote_data_source.dart';
import 'package:washer/data/models/auth/request/login_request.dart';
import 'package:washer/data/models/auth/request/refresh_request.dart';

abstract class AuthRepository {
  Future<void> login(String code);
  Future<void> logout();
  Future<void> refresh();
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;
  final FlutterSecureStorage _storage;

  const AuthRepositoryImpl(this._dataSource, this._storage);

  @override
  Future<void> login(String code) async {
    final response = await _dataSource.login(LoginRequest(code: code));
    await Future.wait([
      _storage.write(key: 'access_token', value: response.accessToken),
      _storage.write(key: 'refresh_token', value: response.refreshToken),
    ]);
  }

  @override
  Future<void> logout() async {
    await Future.wait([
      _storage.delete(key: 'access_token'),
      _storage.delete(key: 'refresh_token'),
    ]);
  }

  @override
  Future<void> refresh() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null) return;
    final response = await _dataSource.refresh(
      RefreshRequest(refreshToken: refreshToken),
    );
    await Future.wait([
      _storage.write(key: 'access_token', value: response.accessToken),
      _storage.write(key: 'refresh_token', value: response.refreshToken),
    ]);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(secureStorageProvider),
  );
});
