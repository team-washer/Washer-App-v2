import 'package:flutter_test/flutter_test.dart';
import 'package:washer/features/auth/presentation/providers/oauth_transaction.dart';

const _redirectUri = 'com.washer.v2://auth/callback';

void main() {
  group('PKCE (#316)', () {
    test('RFC 7636 부록 B의 verifier로 S256 challenge를 만든다', () {
      final transaction = OAuthTransaction(
        state: 'state',
        codeVerifier: 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk',
      );

      expect(
        transaction.codeChallenge,
        'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
      );
    });

    test('요청마다 서로 다른 43자 base64url state와 verifier를 만든다', () {
      final first = OAuthTransaction.create();
      final second = OAuthTransaction.create();
      final urlSafe = RegExp(r'^[A-Za-z0-9_-]{43}$');

      expect(first.codeVerifier, matches(urlSafe));
      expect(first.state, matches(urlSafe));
      expect(first.state, isNot(second.state));
      expect(first.codeVerifier, isNot(second.codeVerifier));
    });

    test('인가 URL에 state와 S256 challenge를 담는다', () {
      final transaction = OAuthTransaction.create();

      final uri = transaction.authorizationUri(
        baseUrl: 'https://oauth.example.test/v1/oauth/authorize',
        clientId: 'client',
        redirectUri: _redirectUri,
      );

      expect(uri.queryParameters, {
        'redirect_uri': _redirectUri,
        'client_id': 'client',
        'state': transaction.state,
        'code_challenge': transaction.codeChallenge,
        'code_challenge_method': 'S256',
      });
    });
  });

  group('callback 검증 (#316)', () {
    final transaction = OAuthTransaction(state: 'expected', codeVerifier: 'v');

    String? codeFrom(String url) =>
        transaction.authorizationCodeFrom(url, redirectUri: _redirectUri);

    test('경로와 state가 맞으면 인가 코드를 돌려준다', () {
      expect(
        codeFrom('com.washer.v2://auth/callback?code=abc&state=expected'),
        'abc',
      );
    });

    test('state가 없거나 다르면 거부한다', () {
      expect(codeFrom('com.washer.v2://auth/callback?code=abc'), isNull);
      expect(
        codeFrom('com.washer.v2://auth/callback?code=abc&state=other'),
        isNull,
      );
    });

    test('scheme·host·path가 다른 callback은 거부한다', () {
      for (final url in [
        'evil.app://auth/callback?code=abc&state=expected',
        'com.washer.v2://evil/callback?code=abc&state=expected',
        'com.washer.v2://auth/other?code=abc&state=expected',
        'com.washer.v2://auth/callback/extra?code=abc&state=expected',
      ]) {
        expect(codeFrom(url), isNull, reason: url);
      }
    });

    test('인가 코드가 없으면 거부한다', () {
      expect(codeFrom('com.washer.v2://auth/callback?state=expected'), isNull);
      expect(
        codeFrom('com.washer.v2://auth/callback?code=&state=expected'),
        isNull,
      );
    });
  });
}
