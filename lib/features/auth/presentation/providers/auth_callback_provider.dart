import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:washer/core/env/app_environment.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/auth/data/repositories/auth_repository.dart';

const _callbackScheme = 'com.washer.v2';
const _redirectUri = '$_callbackScheme://auth/callback';

class AuthCallbackNotifier extends AsyncNotifier<void> {
  late final AuthRepository _authRepository;

  @override
  FutureOr<void> build() {
    _authRepository = ref.watch(authRepositoryProvider);
  }

  /// 시스템 브라우저(외부 user-agent)로 OAuth 로그인을 진행한다.
  ///
  /// 반환값 `message`가 null이면 표시할 오류가 없다(성공 또는 사용자 취소).
  Future<({bool isSuccess, String? message})> login() async {
    final environment = AppEnvironment.instance;
    if (environment.oauthBaseUrl.isEmpty || environment.oauthClientId.isEmpty) {
      return (isSuccess: false, message: _defaultErrorMessage);
    }

    state = const AsyncLoading();

    final String callbackUrl;
    try {
      callbackUrl = await FlutterWebAuth2.authenticate(
        url: Uri.parse(environment.oauthBaseUrl).replace(
          queryParameters: {
            'redirect_uri': _redirectUri,
            'client_id': environment.oauthClientId,
          },
        ).toString(),
        callbackUrlScheme: _callbackScheme,
      );
    } catch (error, stackTrace) {
      // 사용자가 브라우저를 닫은 경우도 예외로 전달된다. 오류로 알리지 않는다.
      AppLogger.error(
        '인증 브라우저가 종료되었습니다.',
        name: 'AuthCallbackNotifier',
        error: error,
        stackTrace: stackTrace,
      );
      state = const AsyncData(null);
      return (isSuccess: false, message: null);
    }

    final authCode = Uri.tryParse(callbackUrl)?.queryParameters['code'];
    if (authCode == null || authCode.isEmpty) {
      state = const AsyncData(null);
      return (isSuccess: false, message: _defaultErrorMessage);
    }

    try {
      await _authRepository.login(
        authCode: authCode,
        redirectUri: _redirectUri,
      );
      state = const AsyncData(null);
      return (isSuccess: true, message: null);
    } catch (error, stackTrace) {
      AppLogger.error(
        '인증 콜백 처리 중 오류가 발생했습니다.',
        name: 'AuthCallbackNotifier',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
      return (isSuccess: false, message: _resolveErrorMessage(error));
    }
  }

  static const _defaultErrorMessage = '로그인에 실패했습니다. 다시 시도해주세요.';

  String _resolveErrorMessage(Object error) {
    if (error is! DioException || error.response?.statusCode != 403) {
      return _defaultErrorMessage;
    }

    final response = error.response?.data;
    if (response is Map<String, dynamic>) {
      final message = response['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    return _defaultErrorMessage;
  }
}

final authCallbackProvider = AsyncNotifierProvider<AuthCallbackNotifier, void>(
  AuthCallbackNotifier.new,
);
