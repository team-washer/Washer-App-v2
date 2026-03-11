import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:washer/data/data_sources/remote/auth_remote_data_source.dart';
import 'package:washer/data/models/auth/login_request.dart';

abstract class AuthRepository {
  Future<void> login(String code);
  Future<void> logout();
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
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    const FlutterSecureStorage(),
  );
});
