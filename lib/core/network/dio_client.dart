import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:washer/core/env/app_environment.dart';

import 'auth_interceptor.dart';
import 'auth_notifier.dart';
import 'insecure_http_client_adapter.dart';

class DioClient {
  static const Duration _connectTimeout = Duration(seconds: 30);
  static const Duration _receiveTimeout = Duration(seconds: 30);

  final Dio _dio;
  final FlutterSecureStorage _storage;
  final AppEnvironment _environment;

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

    _dio.interceptors.add(
      AuthInterceptor(
        _dio,
        _storage,
        _environment,
        onLogout: authNotifier.logout,
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: true,
          error: true,
        ),
      );
    }
  }

  Dio get dio => _dio;
}

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final dioClientProvider = Provider<DioClient>(
  (ref) => DioClient(
    ref.watch(secureStorageProvider),
    ref.watch(appEnvironmentProvider),
  ),
);

final dioProvider = Provider<Dio>((ref) {
  return ref.watch(dioClientProvider).dio;
});
