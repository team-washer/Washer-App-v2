import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// OAuth 로그인 요청 한 번에 묶이는 일회성 값(state, PKCE code verifier).
///
/// 인가 요청과 callback을 같은 트랜잭션으로 검증한다(#316).
/// - state: callback이 이 요청의 응답인지 확인한다(CSRF 방지).
/// - code verifier: 인가 요청에는 SHA-256 해시(code_challenge, S256)만 보내고
///   원본은 토큰 교환 때 서버로 보낸다. 인가 코드가 탈취돼도 verifier 없이는 교환할 수 없다.
class OAuthTransaction {
  OAuthTransaction({required this.state, required this.codeVerifier});

  /// 요청마다 새 state와 code verifier를 만든다. [random]은 테스트에서만 바꾼다.
  factory OAuthTransaction.create({Random? random}) {
    final source = random ?? Random.secure();
    return OAuthTransaction(
      state: _randomUrlSafe(source, 32),
      codeVerifier: _randomUrlSafe(source, 32),
    );
  }

  final String state;

  /// RFC 7636의 43~128자 code verifier (32바이트 → base64url 43자).
  final String codeVerifier;

  /// code verifier의 SHA-256 해시를 base64url(패딩 없음)로 인코딩한 값.
  String get codeChallenge => _base64UrlNoPadding(
    sha256.convert(ascii.encode(codeVerifier)).bytes,
  );

  /// 인가 요청 URL. 기존 파라미터에 state와 PKCE(S256) 파라미터를 더한다.
  Uri authorizationUri({
    required String baseUrl,
    required String clientId,
    required String redirectUri,
  }) {
    return Uri.parse(baseUrl).replace(
      queryParameters: {
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'state': state,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
      },
    );
  }

  /// callback URL을 검증하고 인가 코드를 돌려준다. 검증에 실패하면 null.
  ///
  /// scheme·host·path가 [redirectUri]와 정확히 같고, state가 이 트랜잭션의 값과
  /// 같으며, 인가 코드가 있어야 한다.
  String? authorizationCodeFrom(
    String callbackUrl, {
    required String redirectUri,
  }) {
    final callback = Uri.tryParse(callbackUrl);
    final expected = Uri.parse(redirectUri);
    if (callback == null ||
        callback.scheme.toLowerCase() != expected.scheme.toLowerCase() ||
        callback.host.toLowerCase() != expected.host.toLowerCase() ||
        callback.path != expected.path) {
      return null;
    }

    final params = callback.queryParameters;
    if (params['state'] != state) {
      return null;
    }

    final code = params['code'];
    return code == null || code.isEmpty ? null : code;
  }

  static String _randomUrlSafe(Random random, int byteLength) =>
      _base64UrlNoPadding(
        List<int>.generate(byteLength, (_) => random.nextInt(256)),
      );

  static String _base64UrlNoPadding(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');
}
