import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:washer/core/env/app_environment.dart';

import 'auth_interceptor.dart';
import 'auth_notifier.dart';
import 'http_client_adapter_config.dart';

/// 앱 공용 [Dio] 인스턴스와 인증 인터셉터를 구성하는 클라이언트.
class DioClient {
  static const Duration _connectTimeout = Duration(seconds: 30);
  static const Duration _receiveTimeout = Duration(seconds: 30);

  final Dio _dio;
  final FlutterSecureStorage _storage;
  final AppEnvironment _environment;
  late final AuthInterceptor _authInterceptor;

  DioClient(this._storage, this._environment) : _dio = Dio() {
    configureHttpClientAdapter(
      _dio,
      allowBadCertificates: _environment.allowBadCertificates,
    );

    _dio
      ..options.baseUrl = _environment.apiBaseUrl
      ..options.connectTimeout = _connectTimeout
      ..options.receiveTimeout = _receiveTimeout
      ..options.headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

    _authInterceptor = AuthInterceptor(
      _dio,
      _storage,
      _environment,
      onLogout: authNotifier.logout,
    );
    _dio.interceptors.add(_authInterceptor);

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
        ),
      );
    }
  }

  /// 인증/로깅 인터셉터가 적용된 [Dio].
  Dio get dio => _dio;

  void clearInMemoryCache() => _authInterceptor.clearInMemoryCache();

  Future<void> clearAuthCache() => _authInterceptor.clearCache();
}

/// 토큰 등 민감 정보를 저장하는 secure storage.
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

/// [DioClient] 싱글톤 provider.
final dioClientProvider = Provider<DioClient>(
  (ref) => DioClient(
    ref.watch(secureStorageProvider),
    ref.watch(appEnvironmentProvider),
  ),
);

/// 리포지토리/데이터소스에서 사용하는 [Dio] provider.
final dioProvider = Provider<Dio>((ref) {
  return ref.watch(dioClientProvider).dio;
});
