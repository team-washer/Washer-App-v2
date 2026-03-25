import 'dart:convert';

class TokenUtils {
  const TokenUtils._();

  static bool isExpired(String token, {DateTime? now}) {
    final expiration = getExpiration(token);
    if (expiration == null) {
      return false;
    }

    return !expiration.isAfter(now ?? DateTime.now());
  }

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
