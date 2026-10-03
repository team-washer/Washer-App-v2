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

  /// 테스트에서 환경 파일 없이 값을 지정해 만든다.
  @visibleForTesting
  AppEnvironment.test({
    this.apiBaseUrl = 'https://example.test/api/v2/',
    this.refreshTokenEndpoint = 'auth/refresh',
  }) : flavor = AppFlavor.development,
       oauthBaseUrl = '',
       oauthClientId = '',
       allowBadCertificates = false;

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
    return resolveAllowBadCertificates(
      flavor: flavor,
      rawValue: dotenv.env['ALLOW_BAD_CERTIFICATES'],
    );
  }

  /// 인증서 검증 우회 허용 여부. release 빌드는 flavor와 관계없이 항상 거부한다(#321).
  ///
  /// debug·profile의 development flavor에서 `ALLOW_BAD_CERTIFICATES`가 명시적으로
  /// 켜진 경우에만 로컬·자체 서명 인증서를 허용한다.
  @visibleForTesting
  static bool resolveAllowBadCertificates({
    required AppFlavor flavor,
    required String? rawValue,
    bool isReleaseMode = kReleaseMode,
  }) {
    if (isReleaseMode || flavor == AppFlavor.production) {
      return false;
    }

    final value = rawValue?.trim().toLowerCase() ?? '';

    return value == 'true' || value == '1' || value == 'yes';
  }

  static String _resolveUrl(String key, AppFlavor flavor) {
    final value = dotenv.get(key);
    ensureHttpsPolicy(key, value, flavor);
    return value;
  }

  static String _resolveOptionalUrl(String key, AppFlavor flavor) {
    final value = dotenv.env[key] ?? '';
    if (value.isEmpty) {
      return value;
    }

    ensureHttpsPolicy(key, value, flavor);
    return value;
  }

  /// production flavor와 release 빌드에서는 host가 있는 HTTPS URL만 허용한다(#321).
  @visibleForTesting
  static void ensureHttpsPolicy(
    String key,
    String value,
    AppFlavor flavor, {
    bool isReleaseMode = kReleaseMode,
  }) {
    if (!isReleaseMode && flavor != AppFlavor.production) {
      return;
    }

    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme.toLowerCase() != 'https' ||
        !uri.hasAuthority ||
        uri.host.isEmpty) {
      throw StateError('$key must use HTTPS in production or release builds.');
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
