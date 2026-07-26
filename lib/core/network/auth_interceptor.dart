import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:washer/core/env/app_environment.dart';
import 'package:washer/core/network/token_utils.dart';
import 'package:washer/core/utils/app_logger.dart';

import 'insecure_http_client_adapter.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._dio,
    this._storage,
    this._environment, {
    this.onLogout,
  }) {
    _refreshDio = Dio(
      BaseOptions(
        baseUrl: _environment.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    configureHttpClientAdapter(
      _refreshDio,
      allowBadCertificates: _environment.allowBadCertificates,
    );
  }

  final Dio _dio;
  final FlutterSecureStorage _storage;
  final AppEnvironment _environment;
  final VoidCallback? onLogout;

  late final Dio _refreshDio;
  String? _cachedAccessToken;
  Future<String?>? _refreshFuture;

  /// 갱신 실패로 인한 로그아웃을 단일화하기 위한 가드.
  /// 동시에 들어온 여러 요청이 각자 로그아웃을 호출하지 않도록 막고,
  /// 유효 토큰을 다시 확보(재로그인 등)하면 해제된다.
  bool _isLoggedOut = false;

  static const String _retryKey = 'is_retry_request';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_shouldSkipAuth(options.path)) {
      return handler.next(options);
    }

    if (_cachedAccessToken == null) {
      final storedToken = await _storage.read(key: 'access_token');
      if (storedToken != null) {
        // 재로그인 등으로 스토리지에 새 토큰이 들어오면 로그아웃 가드를 해제한다.
        // 가드가 true로 남아 있으면 첫 요청부터 갱신 실패 시 onLogout이
        // 호출되지 않아 사용자가 갇힐 수 있다.
        _isLoggedOut = false;
        _cachedAccessToken = storedToken;
      }
    }

    final hasValidToken = _cachedAccessToken != null &&
        !TokenUtils.isExpired(_cachedAccessToken!);

    if (!hasValidToken) {
      _cachedAccessToken = await _tryRefreshBeforeRequest();

      // 갱신 실패 시: 인증 없이 요청을 보내면 403 → onError → 재갱신으로
      // 무한 루프가 발생하므로, 로그아웃 처리 후 요청을 즉시 중단한다.
      if (_cachedAccessToken == null) {
        await _handleRefreshFailure();
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            error: '인증 토큰 갱신에 실패했습니다.',
          ),
        );
      }
    }

    // 유효 토큰 확보됨(캐시 유효 or 갱신 성공) → 로그아웃 가드 해제.
    _isLoggedOut = false;
    options.headers['Authorization'] = 'Bearer $_cachedAccessToken';

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
        AppLogger.error(
          '토큰 갱신 후 요청 재시도 중 Dio 오류가 발생했습니다.',
          name: 'AuthInterceptor',
          error: e,
          stackTrace: e.stackTrace,
        );
        await _handleRefreshFailure();
        return handler.next(e);
      } catch (error, stackTrace) {
        AppLogger.error(
          '토큰 갱신 후 요청 재시도 중 오류가 발생했습니다.',
          name: 'AuthInterceptor',
          error: error,
          stackTrace: stackTrace,
        );
        await _handleRefreshFailure();
        return handler.next(err);
      }
    }

    return handler.next(err);
  }

  Future<String?> _tryRefreshBeforeRequest() async {
    try {
      return await _refreshToken();
    } catch (error, stackTrace) {
      AppLogger.error(
        '요청 전 토큰 갱신 중 오류가 발생했습니다.',
        name: 'AuthInterceptor',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  bool _shouldSkipAuth(String path) {
    return path.startsWith('auth/') || path.startsWith('/auth/');
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
    if (TokenUtils.isExpired(refreshToken)) {
      return null;
    }

    final refreshEndpoint = _environment.refreshTokenEndpoint;
    final response = await _refreshDio.post(
      refreshEndpoint,
      data: {'refreshToken': refreshToken},
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
    // 동시에 들어온 요청들이 각자 로그아웃을 호출하지 않도록 단일화한다.
    // 한 번의 갱신 실패 버스트에 대해 스토리지 삭제·onLogout 은 한 번만 실행된다.
    if (_isLoggedOut) {
      _cachedAccessToken = null;
      return;
    }
    _isLoggedOut = true;
    _cachedAccessToken = null;
    // 일부 기기(안드로이드 키스토어 등)에서 secure storage 삭제가 간헐적으로
    // 실패할 수 있다. 삭제가 실패하더라도 onLogout 은 반드시 호출되어야
    // 사용자가 잘못된 상태에 갇히지 않는다.
    try {
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
    } catch (error, stackTrace) {
      AppLogger.error(
        '로그아웃 처리 중 스토리지 삭제에 실패했습니다.',
        name: 'AuthInterceptor',
        error: error,
        stackTrace: stackTrace,
      );
    }
    onLogout?.call();
  }

  /// 스토리지 토큰은 유지하고 메모리 캐시만 초기화
  void clearInMemoryCache() {
    _cachedAccessToken = null;
    _refreshFuture = null;
    _isLoggedOut = false;
  }

  /// 로그아웃 시 메모리 캐시 + 스토리지 토큰 모두 삭제
  Future<void> clearCache() async {
    _cachedAccessToken = null;
    _refreshFuture = null;
    _isLoggedOut = false;
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}
