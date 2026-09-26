import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:washer/core/env/app_environment.dart';
import 'package:washer/core/network/error.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/auth/data/repositories/auth_repository.dart';

const _callbackScheme = 'com.washer.v2';
const _redirectUri = '$_callbackScheme://auth/callback';

/// OAuth 설정이 비어있거나 콜백에 인증 코드가 없는 등, 서버 응답 없이 로그인을
/// 진행할 수 없는 로컬 상태. 메시지는 [AppException.from]이 공통으로 처리한다.
class _LoginUnavailableException implements UserFacingException {
  const _LoginUnavailableException();

  @override
  String get userMessage => '로그인에 실패했습니다. 다시 시도해주세요.';
}

/// OAuth(DataGSM) 로그인 진행 상태를 관리하는 Notifier
class LoginNotifier extends AsyncNotifier<void> {
  late final AuthRepository _authRepository;

  @override
  FutureOr<void> build() {
    _authRepository = ref.watch(authRepositoryProvider);
  }

  /// 시스템 브라우저(외부 user-agent)로 OAuth 로그인을 진행한다. 성공 여부를 반환한다.
  ///
  /// 실패 메시지는 이 provider의 [state](AsyncError)를 통해서만 전달한다. 호출부는
  /// `ref.listen`으로 상태를 지켜보다 [AsyncError]가 되면 [AppException.from]으로
  /// 변환해 보여주면 된다. 사용자가 브라우저를 닫은 취소는 오류로 취급하지 않는다.
  Future<bool> login() async {
    final environment = AppEnvironment.instance;
    if (environment.oauthBaseUrl.isEmpty || environment.oauthClientId.isEmpty) {
      state = AsyncError(
        const _LoginUnavailableException(),
        StackTrace.current,
      );
      return false;
    }

    state = const AsyncLoading();

    final String callbackUrl;
    try {
      callbackUrl = await FlutterWebAuth2.authenticate(
        url: Uri.parse(environment.oauthBaseUrl)
            .replace(
              queryParameters: {
                'redirect_uri': _redirectUri,
                'client_id': environment.oauthClientId,
              },
            )
            .toString(),
        callbackUrlScheme: _callbackScheme,
      );
    } catch (error, stackTrace) {
      // 사용자가 브라우저를 닫은 경우도 예외로 전달된다. 오류로 알리지 않는다.
      AppLogger.error(
        '인증 브라우저가 종료되었습니다.',
        name: 'LoginNotifier',
        error: error,
        stackTrace: stackTrace,
      );
      state = const AsyncData(null);
      return false;
    }

    final authCode = Uri.tryParse(callbackUrl)?.queryParameters['code'];
    if (authCode == null || authCode.isEmpty) {
      state = AsyncError(
        const _LoginUnavailableException(),
        StackTrace.current,
      );
      return false;
    }

    final result = await guardApiCall(
      () => _authRepository.login(
        authCode: authCode,
        redirectUri: _redirectUri,
      ),
      logName: 'LoginNotifier',
    );

    switch (result) {
      case ResultSuccess():
        state = const AsyncData(null);
        return true;
      case ResultFailure(:final error):
        state = AsyncError(error, StackTrace.current);
        return false;
    }
  }
}

final loginProvider = AsyncNotifierProvider<LoginNotifier, void>(
  LoginNotifier.new,
);
