import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppFlavor { development, production }

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

  static Future<void> initialize() async {
    final flavor = _resolveFlavor();

    await dotenv.load(fileName: flavor.envFileName);

    instance = AppEnvironment._(
      flavor: flavor,
      apiBaseUrl: dotenv.get('API_BASE_URL'),
      refreshTokenEndpoint:
          dotenv.env['REFRESH_TOKEN_ENDPOINT'] ?? '/auth/refresh',
      oauthBaseUrl: dotenv.env['OAUTH_BASE_URL'] ?? '',
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
    if (kReleaseMode || flavor == AppFlavor.production) {
      return false;
    }

    final rawValue =
        dotenv.env['ALLOW_BAD_CERTIFICATES']?.trim().toLowerCase() ?? '';

    return rawValue == 'true' || rawValue == '1' || rawValue == 'yes';
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

final appEnvironmentProvider = Provider<AppEnvironment>((_) {
  return AppEnvironment.instance;
});
