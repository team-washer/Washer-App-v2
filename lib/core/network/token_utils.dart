import 'dart:convert';

/// JWT 토큰의 payload(`exp`)를 읽어 만료 여부를 판단하는 유틸.
class TokenUtils {
  const TokenUtils._();

  /// 토큰이 [now] 기준으로 만료되었는지 반환한다. 만료 시각을 알 수 없으면 false.
  static bool isExpired(String token, {DateTime? now}) {
    final expiration = getExpiration(token);
    if (expiration == null) {
      return false;
    }

    return !expiration.isAfter(now ?? DateTime.now());
  }

  /// JWT payload의 `exp`(초 단위)를 로컬 [DateTime]으로 변환한다. 파싱 실패 시 null.
  static DateTime? getExpiration(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      return null;
    }

    try {
      final normalizedPayload = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalizedPayload));
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final exp = decoded['exp'];
      if (exp is num) {
        return DateTime.fromMillisecondsSinceEpoch(
          exp.toInt() * 1000,
          isUtc: true,
        ).toLocal();
      }

      if (exp is String) {
        final parsed = int.tryParse(exp);
        if (parsed == null) {
          return null;
        }

        return DateTime.fromMillisecondsSinceEpoch(
          parsed * 1000,
          isUtc: true,
        ).toLocal();
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}
