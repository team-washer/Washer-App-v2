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
  });

  static late final AppEnvironment instance;

  final AppFlavor flavor;
  final String apiBaseUrl;
  final String refreshTokenEndpoint;
  final String oauthBaseUrl;
  final String oauthClientId;

  bool get isDevelopment => flavor == AppFlavor.development;
  bool get allowBadCertificates => isDevelopment;

  static Future<void> initialize() async {
    final flavor = _resolveFlavor();

    await dotenv.load(fileName: flavor.envFileName);

    instance = AppEnvironment._(
      flavor: flavor,
      apiBaseUrl: dotenv.get('API_BASE_URL'),
      refreshTokenEndpoint:
          dotenv.get('REFRESH_TOKEN_ENDPOINT'),
      oauthBaseUrl: dotenv.get('OAUTH_BASE_URL'),
      oauthClientId: dotenv.get('OAUTH_CLIENT_ID'),
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
