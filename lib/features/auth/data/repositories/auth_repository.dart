import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/features/alarm/data/repositories/alarm_repository_provider.dart';
import 'package:washer/features/alarm/data/repositories/alarm_repository.dart';
import 'package:washer/features/auth/data/data_sources/remote/auth_remote_data_source.dart';
import 'package:washer/features/auth/data/models/request/login_request.dart';
import 'package:washer/features/auth/data/models/request/refresh_request.dart';

class AuthRepository {
  final AuthRemoteDataSource _dataSource;
  final FlutterSecureStorage _storage;
  final DioClient _dioClient;
  final AlarmRepository _alarmRepository;

  const AuthRepository(
    this._dataSource,
    this._storage,
    this._dioClient,
    this._alarmRepository,
  );

  Future<void> login({
    required String authCode,
    required String redirectUri,
  }) async {
    final response = await _dataSource.login(
      LoginRequest(authCode: authCode, redirectUri: redirectUri),
    );
    await Future.wait([
      _storage.write(key: 'access_token', value: response.accessToken),
      _storage.write(key: 'refresh_token', value: response.refreshToken),
    ]);

    await _alarmRepository.registerCurrentFcmToken();
  }

  Future<void> logout() async {
    await _alarmRepository.deleteFcmToken();

    await Future.wait([
      _storage.delete(key: 'access_token'),
      _storage.delete(key: 'refresh_token'),
      _dioClient.clearAuthCache(),
    ]);
  }

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
  return AuthRepository(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(secureStorageProvider),
    ref.watch(dioClientProvider),
    ref.watch(alarmRepositoryProvider),
  );
});
