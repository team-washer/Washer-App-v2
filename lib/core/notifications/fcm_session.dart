import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:washer/core/network/token_utils.dart';

Future<bool> hasActiveNotificationSession(
  FlutterSecureStorage storage,
) async {
  final tokens = await Future.wait<String?>([
    storage.read(key: 'access_token'),
    storage.read(key: 'refresh_token'),
  ]);

  return tokens.any(
    (token) =>
        token != null && token.isNotEmpty && !TokenUtils.isExpired(token),
  );
}
