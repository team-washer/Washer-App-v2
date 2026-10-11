import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/features/auth/data/models/request/login_request.dart';

const _authCode = 'auth-code-secret-value';
const _codeVerifier = 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';
const _redirectUri = 'com.washer.v2://auth/callback';

void main() {
  group('로그인 요청 로그 마스킹 (#316)', () {
    final body = const LoginRequest(
      authCode: _authCode,
      redirectUri: _redirectUri,
      codeVerifier: _codeVerifier,
    ).toJson();

    test('LogInterceptor가 찍는 Map 형태 본문에서 인가 코드와 verifier를 가린다', () {
      final sanitized = sanitizeDioLog(body);

      expect(sanitized, isNot(contains(_authCode)));
      expect(sanitized, isNot(contains(_codeVerifier)));
      expect(sanitized, contains('authCode: [REDACTED]'));
      expect(sanitized, contains('codeVerifier: [REDACTED]'));
      expect(sanitized, contains(_redirectUri), reason: '민감하지 않은 필드는 남긴다');
    });

    test('JSON 문자열 본문에서도 인가 코드와 verifier를 가린다', () {
      final sanitized = sanitizeDioLog(jsonEncode(body));

      expect(sanitized, isNot(contains(_authCode)));
      expect(sanitized, isNot(contains(_codeVerifier)));
    });

    test('snake_case 키(code_verifier)도 가린다', () {
      final sanitized = sanitizeDioLog(
        '{code: abc, code_verifier: $_codeVerifier}',
      );

      expect(sanitized, isNot(contains(_codeVerifier)));
    });
  });
}
