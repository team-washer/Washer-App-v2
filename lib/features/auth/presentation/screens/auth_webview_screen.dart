import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:washer/core/router/route_paths.dart';
import 'package:washer/features/auth/presentation/viewmodels/auth_callback_view_model.dart';
import 'package:washer/features/auth/presentation/widgets/auth_base_scaffold.dart';

const _redirectUri = 'com.washer://auth/callback';
const _callbackScheme = 'com.washer';

/// RFC 7636 PKCE: 32 바이트 난수를 base64url(패딩 없음)로 인코딩
String _generateCodeVerifier() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

/// RFC 7636 PKCE: SHA-256(code_verifier) → base64url(패딩 없음)
String _generateCodeChallenge(String verifier) {
  final digest = sha256.convert(utf8.encode(verifier));
  return base64UrlEncode(digest.bytes).replaceAll('=', '');
}

/// OAuth 인증 화면.
///
/// WebView 대신 시스템 브라우저(Android: Chrome Custom Tabs,
/// iOS: SFSafariViewController)를 사용하여 XSS 위험을 차단합니다.
/// OAuth 콜백은 [app_links]를 통해 수신합니다.
class AuthWebViewScreen extends ConsumerStatefulWidget {
  const AuthWebViewScreen({super.key});

  @override
  ConsumerState<AuthWebViewScreen> createState() => _AuthWebViewScreenState();
}

class _AuthWebViewScreenState extends ConsumerState<AuthWebViewScreen> {
  late final String _codeVerifier;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _codeVerifier = _generateCodeVerifier();

    // 콜백 URI 수신 구독 → 브라우저 실행보다 먼저 등록
    _linkSub = AppLinks().uriLinkStream.listen(
      _handleIncomingLink,
      onError: (_) => _onError(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _launchBrowser());
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  Future<void> _launchBrowser() async {
    final oauthBaseUrl = dotenv.env['OAUTH_BASE_URL'];
    final clientId = dotenv.env['OAUTH_CLIENT_ID'];

    if (oauthBaseUrl == null ||
        oauthBaseUrl.isEmpty ||
        clientId == null ||
        clientId.isEmpty) {
      _onError();
      return;
    }

    final codeChallenge = _generateCodeChallenge(_codeVerifier);
    final uri = Uri.parse(oauthBaseUrl).replace(
      queryParameters: {
        'redirect_uri': _redirectUri,
        'client_id': clientId,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
      },
    );

    try {
      await launchUrl(
        uri,
        customTabsOptions: const CustomTabsOptions(showTitle: false),
        safariVCOptions: const SafariViewControllerOptions(
          entersReaderIfAvailable: false,
        ),
      );
    } catch (_) {
      _onError();
    }
  }

  void _handleIncomingLink(Uri uri) {
    if (uri.scheme != _callbackScheme) return;

    final authCode = uri.queryParameters['code'];
    if (authCode != null && authCode.isNotEmpty) {
      _onAuthCode(authCode);
    } else {
      _onError();
    }
  }

  Future<void> _onAuthCode(String authCode) async {
    await ref
        .read(authCallbackViewModelProvider.notifier)
        .handleAuthCode(authCode, _codeVerifier);

    if (!mounted) return;

    final state = ref.read(authCallbackViewModelProvider);
    if (state.hasError) {
      _onError();
    } else {
      context.go(RoutePaths.home);
    }
  }

  void _onError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('로그인에 실패했습니다. 다시 시도해주세요.')),
    );
    context.go(RoutePaths.login);
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = ref.watch(authCallbackViewModelProvider).isLoading;

    return AuthBaseScaffold(
      body: Center(
        child: isProcessing
            ? const CircularProgressIndicator()
            : const SizedBox.shrink(),
      ),
    );
  }
}
