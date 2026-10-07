import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/env/app_environment.dart';
import 'package:washer/features/auth/data/repositories/auth_repository.dart';
import 'package:washer/features/auth/presentation/providers/login_provider.dart';
import 'package:washer/features/auth/presentation/providers/oauth_transaction.dart';

/// 서버 로그인 호출을 기록하는 fake.
class _RecordingAuthRepository implements AuthRepository {
  final logins = <({String authCode, String redirectUri, String? verifier})>[];

  @override
  Future<void> login({
    required String authCode,
    required String redirectUri,
    String? codeVerifier,
  }) async {
    logins.add((
      authCode: authCode,
      redirectUri: redirectUri,
      verifier: codeVerifier,
    ));
  }

  @override
  Future<void> logout() async {}
}

/// 인가 브라우저. 열린 URL을 기록하고 테스트가 정한 callback을 돌려준다.
class _FakeBrowser {
  final openedUrls = <Uri>[];
  final pending = <Completer<String>>[];

  Future<String> authenticate({
    required String url,
    required String callbackUrlScheme,
  }) {
    openedUrls.add(Uri.parse(url));
    final completer = Completer<String>();
    pending.add(completer);
    return completer.future;
  }

  String get lastState => openedUrls.last.queryParameters['state']!;
}

void main() {
  late _RecordingAuthRepository repository;
  late _FakeBrowser browser;
  late ProviderContainer container;

  setUp(() {
    repository = _RecordingAuthRepository();
    browser = _FakeBrowser();
    container = ProviderContainer(
      overrides: [
        appEnvironmentProvider.overrideWithValue(
          AppEnvironment.test(
            oauthBaseUrl: 'https://oauth.example.test/v1/oauth/authorize',
            oauthClientId: 'client',
          ),
        ),
        authRepositoryProvider.overrideWithValue(repository),
        webAuthenticatorProvider.overrideWithValue(browser.authenticate),
      ],
    );
    addTearDown(container.dispose);
  });

  LoginNotifier notifier() => container.read(loginProvider.notifier);

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('정상 callback이면 인가 요청에 보낸 challenge의 verifier로 로그인한다', () async {
    final login = notifier().login();
    await settle();
    final state = browser.lastState;
    browser.pending.single.complete(
      'com.washer.v2://auth/callback?code=abc&state=$state',
    );

    expect(await login, isTrue);
    expect(repository.logins.single.authCode, 'abc');
    final query = browser.openedUrls.single.queryParameters;
    expect(query['code_challenge_method'], 'S256');
    expect(
      OAuthTransaction(
        state: state,
        codeVerifier: repository.logins.single.verifier!,
      ).codeChallenge,
      query['code_challenge'],
    );
  });

  test('state가 다른 callback은 서버에 보내지 않고 실패로 알린다', () async {
    final login = notifier().login();
    await settle();
    browser.pending.single.complete(
      'com.washer.v2://auth/callback?code=abc&state=forged',
    );

    expect(await login, isFalse);
    expect(repository.logins, isEmpty);
    expect(container.read(loginProvider).hasError, isTrue);
  });

  test('이전 트랜잭션의 callback은 다음 로그인에서 쓸 수 없다', () async {
    final first = notifier().login();
    await settle();
    final oldState = browser.lastState;
    browser.pending.single.complete(
      'com.washer.v2://auth/callback?code=old&state=$oldState',
    );
    await first;

    final second = notifier().login();
    await settle();
    browser.pending.last.complete(
      'com.washer.v2://auth/callback?code=old&state=$oldState',
    );

    expect(await second, isFalse);
    expect(repository.logins.map((l) => l.authCode), ['old']);
    expect(browser.lastState, isNot(oldState));
  });

  test('로그인마다 다른 verifier를 쓴다', () async {
    for (var i = 0; i < 2; i++) {
      final login = notifier().login();
      await settle();
      browser.pending.last.complete(
        'com.washer.v2://auth/callback?code=c$i&state=${browser.lastState}',
      );
      await login;
    }

    expect(repository.logins, hasLength(2));
    expect(repository.logins[0].verifier, isNot(repository.logins[1].verifier));
  });

  test('진행 중인 로그인이 있으면 새 트랜잭션으로 덮어쓰지 않는다', () async {
    final first = notifier().login();
    await settle();

    expect(await notifier().login(), isFalse);
    expect(browser.openedUrls, hasLength(1));

    browser.pending.single.complete(
      'com.washer.v2://auth/callback?code=abc&state=${browser.lastState}',
    );
    expect(await first, isTrue);
  });

  test('사용자가 브라우저를 닫으면 오류 없이 끝나고 다시 로그인할 수 있다', () async {
    final login = notifier().login();
    await settle();
    browser.pending.single.completeError(Exception('CANCELED'));

    expect(await login, isFalse);
    expect(container.read(loginProvider).hasError, isFalse);

    unawaited(notifier().login());
    await settle();
    expect(browser.openedUrls, hasLength(2));
  });
}
