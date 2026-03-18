import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_interceptor.dart';
import 'auth_notifier.dart';

class DioClient {
  static const Duration _connectTimeout = Duration(seconds: 30);
  static const Duration _receiveTimeout = Duration(seconds: 30);

  final Dio _dio;
  final FlutterSecureStorage _storage;

  DioClient(this._storage) : _dio = Dio() {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';

    _dio
      ..options.baseUrl = baseUrl
      ..options.connectTimeout = _connectTimeout
      ..options.receiveTimeout = _receiveTimeout
      ..options.headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

    _dio.interceptors.add(
      AuthInterceptor(_dio, _storage, onLogout: authNotifier.logout),
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
  (ref) => DioClient(ref.watch(secureStorageProvider)),
);

final dioProvider = Provider<Dio>((ref) {
  return ref.watch(dioClientProvider).dio;
});
