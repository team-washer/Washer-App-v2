import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:washer/core/env/app_environment.dart';
import 'package:washer/core/network/token_utils.dart';
import 'package:washer/core/utils/app_logger.dart';

import 'http_client_adapter_config.dart';

/// 요청에 액세스 토큰을 붙이고, 만료/401 시 토큰을 갱신해 재시도하는 인터셉터.
/// 갱신에 실패하면 토큰을 지우고 [onLogout]을 호출한다.
///
/// 세션 시작([startSession])과 종료([clearCache])는 세션 세대([_sessionGeneration])를
/// 올리고 저장소와 메모리 캐시를 함께 맞춘다. 이전 세대에 시작한 갱신은 응답이 늦게
/// 와도 토큰을 저장하지 않고, 그 갱신을 기다리던 요청도 재시도하지 않는다(#279).
/// 이전 세대에 시작한 저장소 읽기도 메모리 캐시를 되살리지 않는다(#319).
class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._dio,
    this._storage,
    this._environment, {
    this.onLogout,
    @visibleForTesting Dio? refreshDio,
  }) {
    if (refreshDio != null) {
      _refreshDio = refreshDio;
      return;
    }
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

  /// 세션 세대. 로그아웃마다 올라가며, 이전 세대에서 시작한
  /// 갱신 결과를 폐기하는 기준이 된다.
  int _sessionGeneration = 0;

  /// [_serializeStorage]의 마지막 작업. 토큰 저장소 작업을 직렬화한다.
  Future<void> _storageQueue = Future<void>.value();

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
      final generation = _sessionGeneration;
      final storedToken = await _storage.read(key: 'access_token');

      // 읽는 동안 세션이 바뀌었으면 읽은 값은 이전 세션의 토큰이므로 캐시에 올리지 않는다.
      // 새 세션이 시작됐다면 그 토큰이 이미 캐시에 있고, 세션이 끝났다면 요청을 보내지 않는다.
      if (generation != _sessionGeneration) {
        if (_cachedAccessToken == null) {
          return handler.reject(_sessionEndedException(options));
        }
      } else if (storedToken != null) {
        // 재로그인 등으로 스토리지에 새 토큰이 들어오면 로그아웃 가드를 해제한다.
        // 가드가 true로 남아 있으면 첫 요청부터 갱신 실패 시 onLogout이
        // 호출되지 않아 사용자가 갇힐 수 있다.
        _isLoggedOut = false;
        _cachedAccessToken = storedToken;
      }
    }

    final hasValidToken =
        _cachedAccessToken != null &&
        !TokenUtils.isExpired(_cachedAccessToken!);

    if (!hasValidToken) {
      final generation = _sessionGeneration;
      final refreshedToken = await _tryRefreshToken();

      // 갱신을 기다리는 동안 로그아웃되었으면 요청을 보내지 않는다.
      // 이미 로그아웃 처리가 끝났으므로 onLogout을 다시 호출하지도 않는다.
      if (generation != _sessionGeneration) {
        return handler.reject(_sessionEndedException(options));
      }
      _cachedAccessToken = refreshedToken;

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
    final isRetry = err.requestOptions.extra[_retryKey] == true;

    if (_needsTokenRefresh(err) && !isRetry) {
      final generation = _sessionGeneration;

      // 1) 갱신 성공 여부를 먼저 확정한다. 네트워크 오류 등으로 갱신 자체가
      //    실패하면 세션을 유지할 수 없으므로 로그아웃한다.
      final newAccessToken = await _tryRefreshToken();

      // 갱신을 기다리는 동안 로그아웃되었으면 원래 요청을 재시도하지 않는다.
      if (generation != _sessionGeneration) {
        return handler.next(err);
      }

      if (newAccessToken == null) {
        await _handleRefreshFailure();
        return handler.next(err);
      }

      // 2) 갱신이 확인된 뒤에만 재요청한다. 재요청 실패(409, 500, 네트워크 등)는
      //    인증 문제가 아니므로 로그아웃하지 않고 그 오류를 호출부에 그대로 전달한다.
      try {
        final response = await _retryRequest(
          err.requestOptions,
          newAccessToken,
        );
        return handler.resolve(response);
      } on DioException catch (e) {
        return handler.next(e);
      } catch (error, stackTrace) {
        AppLogger.error(
          '토큰 갱신 후 요청 재시도 중 오류가 발생했습니다.',
          name: 'AuthInterceptor',
          error: error,
          stackTrace: stackTrace,
        );
        return handler.next(err);
      }
    }

    return handler.next(err);
  }

  /// 토큰을 갱신하면 해결될 수 있는 인증 오류인지 판단한다.
  ///
  /// 401은 항상 인증 실패다. 403은 원인별 코드(권한 부족·호실 세탁 금지·재가입 제한
  /// 등, 백엔드 #196)가 있으면 토큰과 무관한 거부라 갱신하지 않는다. 갱신해도 같은
  /// 거부가 반복되고, 갱신이 일시적으로 실패하면 로그아웃까지 되기 때문이다.
  /// 코드가 없는 403은 구버전 서버의 인증 실패일 수 있어 기존처럼 갱신한다.
  static bool _needsTokenRefresh(DioException err) {
    final statusCode = err.response?.statusCode;
    if (statusCode == 401) return true;
    if (statusCode != 403) return false;

    final body = err.response?.data;
    final data = body is Map ? body['data'] : null;
    final errorCode = data is Map ? data['errorCode'] : null;
    return errorCode is! String || errorCode.trim().isEmpty;
  }

  Future<String?> _tryRefreshToken() async {
    try {
      return await _refreshToken();
    } catch (error, stackTrace) {
      AppLogger.error(
        '토큰 갱신 중 오류가 발생했습니다.',
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
    final inflight = _refreshFuture;
    if (inflight != null) {
      return inflight;
    }

    final refresh = _performRefresh(_sessionGeneration);
    _refreshFuture = refresh;

    try {
      return await refresh;
    } finally {
      // 로그아웃 뒤 새 세션에서 시작한 갱신을 이전 갱신의 종료가 지우지 않도록,
      // 자기 자신일 때만 비운다.
      if (identical(_refreshFuture, refresh)) {
        _refreshFuture = null;
      }
    }
  }

  /// [generation] 세대의 토큰을 갱신한다. 응답을 받은 뒤 세대가 바뀌었으면
  /// (로그아웃 등) 토큰을 저장하지 않고 null을 반환한다.
  Future<String?> _performRefresh(int generation) async {
    bool isStale() => generation != _sessionGeneration;

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

    if (newAccessToken == null) {
      return null;
    }

    // 세대 확인과 저장을 로그아웃 삭제와 같은 직렬화 구간에서 처리한다.
    // 확인 직후 로그아웃 삭제가 먼저 끝나고 저장이 늦게 끝나면 세션이 되살아나므로,
    // 확인·저장을 한 단위로 묶고 로그아웃 삭제는 그 뒤에 실행되게 한다.
    final committed = await _serializeStorage(() async {
      if (isStale()) return false;
      await _storage.write(key: 'access_token', value: newAccessToken);
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _storage.write(key: 'refresh_token', value: newRefreshToken);
      }
      return true;
    });

    // 저장 중 로그아웃되었으면 뒤이은 로그아웃 삭제가 토큰을 지운다.
    // 메모리 캐시에도 올리지 않는다.
    if (!committed || isStale()) {
      return null;
    }
    _cachedAccessToken = newAccessToken;
    return newAccessToken;
  }

  /// 토큰 저장소 쓰기·삭제를 순서대로 하나씩 실행한다.
  ///
  /// secure storage 호출은 플랫폼에서 호출 순서대로 끝난다는 보장이 없다.
  /// 갱신 결과 저장과 로그아웃 삭제가 서로 끼어들지 않도록 이 큐를 거친다.
  Future<T> _serializeStorage<T>(Future<T> Function() action) {
    final result = _storageQueue.then((_) => action());
    _storageQueue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
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

  DioException _sessionEndedException(RequestOptions options) {
    return DioException(
      requestOptions: options,
      type: DioExceptionType.cancel,
      error: '로그아웃되어 요청을 중단했습니다.',
    );
  }

  /// 로그인으로 새 세션을 시작한다. 메모리 캐시와 스토리지를 새 토큰으로 함께 맞춘다.
  ///
  /// 세대를 올리므로 이전 세션에서 시작한 갱신·저장소 읽기의 결과는 버려지고,
  /// 이후 요청은 스토리지 저장이 끝나기 전이라도 새 토큰만 사용한다.
  Future<void> startSession({
    required String accessToken,
    required String refreshToken,
  }) async {
    _sessionGeneration++;
    _cachedAccessToken = accessToken;
    _refreshFuture = null;
    _isLoggedOut = false;
    await _serializeStorage(() async {
      await _storage.write(key: 'access_token', value: accessToken);
      await _storage.write(key: 'refresh_token', value: refreshToken);
    });
  }

  /// 세션을 끝낸다. 메모리 캐시 + 스토리지 토큰 모두 삭제
  Future<void> clearCache() async {
    _sessionGeneration++;
    _cachedAccessToken = null;
    _refreshFuture = null;
    _isLoggedOut = false;
    // 세대를 먼저 올렸으므로, 큐에서 이보다 앞선 갱신 저장은 끝난 뒤 여기서 지워지고
    // 뒤늦게 실행되는 이전 세대의 저장은 세대 확인에서 버려진다.
    await _serializeStorage(() async {
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
    });
  }
}
