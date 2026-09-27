import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 실행 환경(개발/운영).
enum AppFlavor { development, production }

/// `.env.*` 파일과 빌드 옵션(APP_ENV)에서 읽은 앱 환경 설정.
class AppEnvironment {
  AppEnvironment._({
    required this.flavor,
    required this.apiBaseUrl,
    required this.refreshTokenEndpoint,
    required this.oauthBaseUrl,
    required this.oauthClientId,
    required this.allowBadCertificates,
  });

  static late final AppEnvironment instance;

  final AppFlavor flavor;
  final String apiBaseUrl;
  final String refreshTokenEndpoint;
  final String oauthBaseUrl;
  final String oauthClientId;
  final bool allowBadCertificates;

  bool get isDevelopment => flavor == AppFlavor.development;

  /// 환경 파일을 로드해 [instance]를 초기화한다. 앱 시작 시 한 번 호출해야 한다.
  static Future<void> initialize() async {
    final flavor = _resolveFlavor();

    await dotenv.load(fileName: flavor.envFileName);

    instance = AppEnvironment._(
      flavor: flavor,
      apiBaseUrl: _resolveUrl('API_BASE_URL', flavor),
      refreshTokenEndpoint:
          dotenv.env['REFRESH_TOKEN_ENDPOINT'] ?? 'auth/refresh',
      oauthBaseUrl: _resolveOptionalUrl('OAUTH_BASE_URL', flavor),
      oauthClientId: dotenv.env['OAUTH_CLIENT_ID'] ?? '',
      allowBadCertificates: _resolveAllowBadCertificates(flavor),
    );
  }

  static AppFlavor _resolveFlavor() {
    final appEnv = const String.fromEnvironment('APP_ENV').trim().toLowerCase();

    if (appEnv == 'production' || appEnv == 'prod') {
      return AppFlavor.production;
    }

    if (appEnv == 'development' || appEnv == 'dev') {
      return AppFlavor.development;
    }

    return kReleaseMode ? AppFlavor.production : AppFlavor.development;
  }

  static bool _resolveAllowBadCertificates(AppFlavor flavor) {
    if (flavor == AppFlavor.production) {
      return false;
    }

    final rawValue =
        dotenv.env['ALLOW_BAD_CERTIFICATES']?.trim().toLowerCase() ?? '';

    return rawValue == 'true' || rawValue == '1' || rawValue == 'yes';
  }

  static String _resolveUrl(String key, AppFlavor flavor) {
    final value = dotenv.get(key);
    _ensureProductionHttps(key, value, flavor);
    return value;
  }

  static String _resolveOptionalUrl(String key, AppFlavor flavor) {
    final value = dotenv.env[key] ?? '';
    if (value.isEmpty) {
      return value;
    }

    _ensureProductionHttps(key, value, flavor);
    return value;
  }

  static void _ensureProductionHttps(
    String key,
    String value,
    AppFlavor flavor,
  ) {
    if (flavor != AppFlavor.production) {
      return;
    }

    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme.toLowerCase() != 'https') {
      throw StateError('$key must use HTTPS in production.');
    }
  }
}

extension on AppFlavor {
  String get envFileName {
    switch (this) {
      case AppFlavor.development:
        return '.env.development';
      case AppFlavor.production:
        return '.env.production';
    }
  }
}

/// [AppEnvironment.instance]를 노출하는 provider.
final appEnvironmentProvider = Provider<AppEnvironment>((_) {
  return AppEnvironment.instance;
});
