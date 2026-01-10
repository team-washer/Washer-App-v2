import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  // 토큰 갱신 전용 Dio 인스턴스 (인터셉터 없이)
  late final Dio _refreshDio;

  // 토큰 캐싱으로 성능 향상
  String? _cachedAccessToken;

  // 리프레시 중복 방지를 위한 Future 캐싱
  Future<String?>? _refreshFuture;

  // 재시도 플래그 (무한 루프 방지)
  static const String _retryKey = 'is_retry_request';

  AuthInterceptor(this._dio, this._storage) {
    // 토큰 갱신 전용 Dio 인스턴스 생성 (인터셉터 제거)
    _refreshDio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['BASE_URL'] ?? '',
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
    final isRetry = err.requestOptions.extra[_retryKey] == true;

    // 401 Unauthorized 에러 처리 (토큰 만료, 재시도가 아닐 때만)
    if (err.response?.statusCode == 401 && !isRetry) {
      try {
        // 토큰 리프레시 (동시성 제어: _refreshFuture 캐싱으로 중복 방지)
        final newAccessToken = await _refreshToken();

        if (newAccessToken != null) {
          // 실패했던 요청 재시도
          final response = await _retryRequest(
            err.requestOptions,
            newAccessToken,
          );
          return handler.resolve(response);
        } else {
          // 리프레시 토큰도 없거나 만료됨
          _handleRefreshFailure();
        }
      } on DioException catch (e) {
        // 리프레시 실패 시
        _handleRefreshFailure();
        return handler.next(e);
      } catch (e) {
        // 기타 에러
        _handleRefreshFailure();
        return handler.next(err);
      }
    }

    // 403 Forbidden 에러 처리 (권한 부족)
    if (err.response?.statusCode == 403) {
      // TODO :: 권한 부족 안내 또는 적절한 처리
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

  /// 리프레시 실패 처리
  void _handleRefreshFailure() {
    // 캐시 및 토큰 초기화
    _cachedAccessToken = null;
    _storage.delete(key: 'access_token');
    _storage.delete(key: 'refresh_token');

    // TODO :: 리프레시 실패 시 로그아웃 처리 또는 로그인 페이지로 이동
  }

  /// 토큰 캐시 무효화 (로그아웃 시 호출)
  Future<void> clearCache() async {
    _cachedAccessToken = null;
    _refreshFuture = null;
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}
