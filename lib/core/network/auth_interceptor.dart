import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthInterceptor(this._dio, this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 액세스 토큰을 헤더에 추가
    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 403 Forbidden 에러 처리
    if (err.response?.statusCode == 403) {
      try {
        // TODO :: 리프레시 로직 추가
        // 1. 리프레시 토큰 가져오기
        // final refreshToken = await _storage.read(key: 'refresh_token');
        //
        // 2. 리프레시 토큰으로 새로운 액세스 토큰 요청
        // final response = await _dio.post(
        //   '/auth/refresh',
        //   options: Options(
        //     headers: {
        //       'Authorization': 'Bearer $refreshToken',
        //     },
        //   ),
        // );
        //
        // 3. 새로운 토큰 저장
        // final newAccessToken = response.data['access_token'];
        // final newRefreshToken = response.data['refresh_token'];
        // await _storage.write(key: 'access_token', value: newAccessToken);
        // await _storage.write(key: 'refresh_token', value: newRefreshToken);
        //
        // 4. 실패했던 요청 재시도
        // final opts = Options(
        //   method: err.requestOptions.method,
        //   headers: err.requestOptions.headers,
        // );
        // opts.headers!['Authorization'] = 'Bearer $newAccessToken';
        //
        // final cloneReq = await _dio.request(
        //   err.requestOptions.path,
        //   options: opts,
        //   data: err.requestOptions.data,
        //   queryParameters: err.requestOptions.queryParameters,
        // );
        //
        // return handler.resolve(cloneReq);

        // 임시: 리프레시 로직 구현 전까지는 에러 처리
        return handler.next(err);
      } catch (e) {
        // 리프레시 실패 시 로그아웃 처리 등
        // TODO :: 리프레시 실패 시 로그아웃 처리
        return handler.next(err);
      }
    }

    // 401 Unauthorized 에러 처리 (로그인 필요)
    if (err.response?.statusCode == 401) {
      // TODO :: 로그인 페이지로 이동
      return handler.next(err);
    }

    return handler.next(err);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    return handler.next(response);
  }
}
