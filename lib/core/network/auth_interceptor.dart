import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// HTTP 토큰 자동 갱신 및 에러 처리 인터셉터
///
/// 역할:
/// - 모든 API 요청에 Bearer 토큰 자동 추가
/// - 401/403 (토큰 만료) 시 refresh token으로 자동 갱신
/// - 갱신 실패 시 강제 로그아웃 처리
/// - 동시 refresh 요청 중복 방지 (Future 캐싱)
class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  /// 리프레시 실패 시 호출되는 콜백 (강제 로그아웃 처리용)
  final VoidCallback? onLogout;

  // 토큰 갱신 전용 Dio 인스턴스 (인터셉터 없이)
  late final Dio _refreshDio;

  // 토큰 캐싱으로 성능 향상
  String? _cachedAccessToken;

  // 리프레시 중복 방지를 위한 Future 캐싱
  Future<String?>? _refreshFuture;

  // 재시도 플래그 (무한 루프 방지)
  static const String _retryKey = 'is_retry_request';

  AuthInterceptor(this._dio, this._storage, {this.onLogout}) {
    // 토큰 갱신 전용 Dio 인스턴스 생성 (인터셉터 제거)
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

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 캐시된 토큰이 있으면 사용, 없으면 storage에서 읽기
    _cachedAccessToken ??= await _storage.read(key: 'access_token');

    if (_cachedAccessToken != null) {
      options.headers['Authorization'] = 'Bearer $_cachedAccessToken';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final isRetry = err.requestOptions.extra[_retryKey] == true;

    // 401 Unauthorized / 403 Forbidden — 토큰 만료 처리 (재시도가 아닐 때만)
    if ((statusCode == 401 || statusCode == 403) && !isRetry) {
      try {
        final newAccessToken = await _refreshToken();

        if (newAccessToken != null) {
          // 갱신 성공 → 원 요청 재시도
          final response = await _retryRequest(
            err.requestOptions,
            newAccessToken,
          );
          return handler.resolve(response);
        }

        // 리프레시 토큰도 없거나 만료됨 → 강제 로그아웃
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

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    return handler.next(response);
  }

  /// 토큰 리프레시 (동시성 제어)
  Future<String?> _refreshToken() async {
    // 이미 리프레시 중이면 기존 Future 반환 (중복 방지)
    if (_refreshFuture != null) {
      return _refreshFuture;
    }

    _refreshFuture = _performRefresh();

    try {
      final result = await _refreshFuture;
      return result;
    } finally {
      _refreshFuture = null;
    }
  }

  /// 실제 리프레시 로직 수행
  Future<String?> _performRefresh() async {
    // 1. 리프레시 토큰 가져오기
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null) {
      return null;
    }

    // DataSource로 변경 예정 로직만 작성
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

    // 3. 새로운 토큰 저장
    final newAccessToken = response.data['access_token'] as String?;
    final newRefreshToken = response.data['refresh_token'] as String?;

    if (newAccessToken != null) {
      // 캐시 및 storage 동시 업데이트
      _cachedAccessToken = newAccessToken;
      await _storage.write(key: 'access_token', value: newAccessToken);

      if (newRefreshToken != null) {
        await _storage.write(key: 'refresh_token', value: newRefreshToken);
      }

      return newAccessToken;
    }

    return null;
  }

  /// 실패한 요청 재시도
  Future<Response> _retryRequest(
    RequestOptions requestOptions,
    String newAccessToken,
  ) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );

    // 새 토큰 설정 및 재시도 플래그 추가
    options.headers!['Authorization'] = 'Bearer $newAccessToken';
    options.extra = {...requestOptions.extra, _retryKey: true};

    return _dio.request(
      requestOptions.path,
      options: options,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
    );
  }

  /// 리프레시 실패 처리 — 토큰 삭제 후 onLogout 콜백으로 강제 로그아웃
  Future<void> _handleRefreshFailure() async {
    _cachedAccessToken = null;
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    onLogout?.call();
  }

  /// 토큰 캐시 무효화 (로그아웃 시 호출)
  Future<void> clearCache() async {
    _cachedAccessToken = null;
    _refreshFuture = null;
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}
