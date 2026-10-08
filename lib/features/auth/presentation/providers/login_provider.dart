import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:washer/core/env/app_environment.dart';
import 'package:washer/core/network/error.dart';
import 'package:washer/core/network/session_generation_provider.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/auth/data/repositories/auth_repository.dart';
import 'package:washer/features/auth/presentation/providers/oauth_transaction.dart';

const _callbackScheme = 'com.washer.v2';
const _redirectUri = '$_callbackScheme://auth/callback';

/// OAuth 설정이 비어있거나 콜백에 인증 코드가 없는 등, 서버 응답 없이 로그인을
/// 진행할 수 없는 로컬 상태. 메시지는 [AppException.from]이 공통으로 처리한다.
class _LoginUnavailableException implements UserFacingException {
  const _LoginUnavailableException();

  @override
  String get userMessage => '로그인에 실패했습니다. 다시 시도해주세요.';
}

/// 시스템 브라우저로 인가 URL을 열고 callback URL을 돌려받는 함수.
typedef WebAuthenticator =
    Future<String> Function({
      required String url,
      required String callbackUrlScheme,
    });

/// 인가 브라우저 실행. 테스트에서 override한다.
final webAuthenticatorProvider = Provider<WebAuthenticator>(
  (_) => FlutterWebAuth2.authenticate,
);

/// OAuth(DataGSM) 로그인 진행 상태를 관리하는 Notifier
class LoginNotifier extends AsyncNotifier<void> {
  late final AuthRepository _authRepository;

  /// 로그인이 진행 중인지. 브라우저 인증부터 서버 로그인 완료까지 전체를 덮어,
  /// 겹친 로그인이 서로의 결과(세션·상태)를 뒤늦게 덮어쓰지 않게 한다.
  bool _isLoggingIn = false;

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
    final environment = ref.read(appEnvironmentProvider);
    if (environment.oauthBaseUrl.isEmpty || environment.oauthClientId.isEmpty) {
      state = AsyncError(
        const _LoginUnavailableException(),
        StackTrace.current,
      );
      return false;
    }

    // 이미 진행 중인 로그인이 있으면 새로 시작하지 않는다.
    if (_isLoggingIn) {
      return false;
    }
    _isLoggingIn = true;
    try {
      return await _loginWith(environment);
    } finally {
      _isLoggingIn = false;
    }
  }

  /// 새 트랜잭션으로 인가 요청 → callback 검증 → 서버 로그인을 진행한다.
  ///
  /// 트랜잭션은 이 호출 안에서만 쓰이므로, 끝난 트랜잭션의 callback은 다음 로그인의
  /// state와 맞지 않아 재사용할 수 없다.
  Future<bool> _loginWith(AppEnvironment environment) async {
    final transaction = OAuthTransaction.create();

    state = const AsyncLoading();

    final String callbackUrl;
    try {
      callbackUrl = await ref.read(webAuthenticatorProvider)(
        url: transaction
            .authorizationUri(
              baseUrl: environment.oauthBaseUrl,
              clientId: environment.oauthClientId,
              redirectUri: _redirectUri,
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

    final authCode = transaction.authorizationCodeFrom(
      callbackUrl,
      redirectUri: _redirectUri,
    );
    if (authCode == null) {
      AppLogger.error(
        'OAuth callback 검증에 실패했습니다(경로·state·인가 코드).',
        name: 'LoginNotifier',
      );
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
        codeVerifier: transaction.codeVerifier,
      ),
      logName: 'LoginNotifier',
    );

    switch (result) {
      case ResultSuccess():
        // 로그아웃을 거치지 않고 세션이 끝난 경우(토큰 만료로 로그인 화면 이동 등)에도
        // 이전 사용자의 상태가 새 세션에 남지 않도록 세션을 새로 시작한다.
        ref.read(sessionGenerationProvider.notifier).advance();
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
