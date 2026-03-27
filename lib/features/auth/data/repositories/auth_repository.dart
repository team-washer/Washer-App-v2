import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/core/notifications/notification_service.dart';
import 'package:washer/features/auth/data/data_sources/remote/auth_remote_data_source.dart';
import 'package:washer/features/auth/data/models/request/login_request.dart';
import 'package:washer/features/auth/data/models/request/refresh_request.dart';

abstract class AuthRepository {
  Future<void> login(String code);
  Future<void> logout();
  Future<void> refresh();
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;
  final FlutterSecureStorage _storage;
  final NotificationService _notificationService;
  final DioClient _dioClient;

  const AuthRepositoryImpl(
    this._dataSource,
    this._storage,
    this._notificationService,
    this._dioClient,
  );

  @override
  Future<void> login(String code) async {
    final response = await _dataSource.login(
      LoginRequest(code: code),
    );
    await Future.wait([
      _storage.write(key: 'access_token', value: response.accessToken),
      _storage.write(key: 'refresh_token', value: response.refreshToken),
    ]);

    String? fcmToken;
    try {
      fcmToken = await _notificationService.ensureFcmToken();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to prepare FCM token during login: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      return;
    }

    if (fcmToken == null || fcmToken.isEmpty) {
      return;
    }

    try {
      await _dataSource.registerFcmToken(fcmToken);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to register FCM token: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dataSource.deleteFcmToken();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to delete FCM token: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    await Future.wait([
      _dioClient.clearAuthCache(),
      _notificationService.deleteStoredFcmToken(),
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
    ref.watch(notificationServiceProvider),
    ref.watch(dioClientProvider),
  );
});
