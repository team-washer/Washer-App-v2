import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:washer/core/network/token_utils.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio, this._storage, {this.onLogout}) {
    _refreshDio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['API_BASE_URL'] ?? '',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  final Dio _dio;
  final FlutterSecureStorage _storage;
  final VoidCallback? onLogout;

  late final Dio _refreshDio;
  String? _cachedAccessToken;
  Future<String?>? _refreshFuture;

  static const String _retryKey = 'is_retry_request';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_shouldSkipAuth(options.path)) {
      return handler.next(options);
    }

    _cachedAccessToken ??= await _storage.read(key: 'access_token');

    if (_cachedAccessToken == null) {
      _cachedAccessToken = await _tryRefreshBeforeRequest();
    } else if (TokenUtils.isExpired(_cachedAccessToken!)) {
      _cachedAccessToken =
          await _tryRefreshBeforeRequest() ?? _cachedAccessToken;
    }

    if (_cachedAccessToken != null) {
      options.headers['Authorization'] = 'Bearer $_cachedAccessToken';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final isRetry = err.requestOptions.extra[_retryKey] == true;

    if ((statusCode == 401 || statusCode == 403) && !isRetry) {
      try {
        final newAccessToken = await _refreshToken();

        if (newAccessToken != null) {
          final response = await _retryRequest(
            err.requestOptions,
            newAccessToken,
          );
          return handler.resolve(response);
        }

        await _handleRefreshFailure();
        return handler.next(err);
      } on DioException catch (e) {
        await _handleRefreshFailure();
        return handler.next(e);
      } catch (_) {
        await _handleRefreshFailure();
        return handler.next(err);
      }
    }

    return handler.next(err);
  }

  Future<String?> _tryRefreshBeforeRequest() async {
    try {
      return await _refreshToken();
    } catch (_) {
      return null;
    }
  }

  bool _shouldSkipAuth(String path) {
    return path.contains('/api/v2/auth/');
  }

  Future<String?> _refreshToken() async {
    if (_refreshFuture != null) {
      return _refreshFuture;
    }

    _refreshFuture = _performRefresh();

    try {
      return await _refreshFuture;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    final refreshEndpoint =
        dotenv.env['REFRESH_TOKEN_ENDPOINT'] ?? '/auth/refresh';
    final response = await _refreshDio.post(
      refreshEndpoint,
      options: Options(
        headers: {
          'Authorization': 'Bearer $refreshToken',
        },
      ),
    );

    final responseData = response.data;
    final payload = responseData is Map<String, dynamic>
        ? (responseData['data'] is Map<String, dynamic>
              ? responseData['data'] as Map<String, dynamic>
              : responseData)
        : <String, dynamic>{};

    final newAccessToken = _readString(
      payload,
      ['access_token', 'accessToken'],
    );
    final newRefreshToken = _readString(
      payload,
      ['refresh_token', 'refreshToken'],
    );

    if (newAccessToken != null) {
      _cachedAccessToken = newAccessToken;
      await _storage.write(key: 'access_token', value: newAccessToken);

      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _storage.write(key: 'refresh_token', value: newRefreshToken);
      }

      return newAccessToken;
    }

    return null;
  }

  String? _readString(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  Future<Response<dynamic>> _retryRequest(
    RequestOptions requestOptions,
    String newAccessToken,
  ) {
    final headers = Map<String, dynamic>.from(requestOptions.headers)
      ..['Authorization'] = 'Bearer $newAccessToken';

    final options = Options(
      method: requestOptions.method,
      headers: headers,
      extra: {...requestOptions.extra, _retryKey: true},
    );

    return _dio.request<dynamic>(
      requestOptions.path,
      options: options,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
    );
  }

  Future<void> _handleRefreshFailure() async {
    _cachedAccessToken = null;
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    onLogout?.call();
  }

  Future<void> clearCache() async {
    _cachedAccessToken = null;
    _refreshFuture = null;
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}
