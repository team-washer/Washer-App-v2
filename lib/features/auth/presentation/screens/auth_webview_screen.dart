import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:washer/core/router/route_paths.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/features/auth/presentation/viewmodels/auth_callback_view_model.dart';
import 'package:washer/features/auth/presentation/widgets/auth_base_scaffold.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _redirectUri = 'com.washer://auth/callback';
const _callbackScheme = 'com.washer';

/// RFC 7636 PKCE: 32 바이트 난수를 base64url(패딩 없음)로 인코딩
String _generateCodeVerifier() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

class AuthWebViewScreen extends ConsumerStatefulWidget {
  const AuthWebViewScreen({super.key});

  @override
  ConsumerState<AuthWebViewScreen> createState() => _AuthWebViewScreenState();
}

class _AuthWebViewScreenState extends ConsumerState<AuthWebViewScreen> {
  WebViewController? _controller;
  String _codeVerifier = '';
  bool _isLoading = true;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    final oauthBaseUrl = dotenv.env['OAUTH_BASE_URL'];
    final clientId = dotenv.env['OAUTH_CLIENT_ID'];

    if (oauthBaseUrl == null ||
        oauthBaseUrl.isEmpty ||
        clientId == null ||
        clientId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onError());
      return;
    }

    _codeVerifier = _generateCodeVerifier();

    final uri = Uri.parse(oauthBaseUrl).replace(
      queryParameters: {
        'redirect_uri': _redirectUri,
        'client_id': clientId,
      },
    );

    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(WasherColor.backgroundColor)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (!_isDisposed) setState(() => _isLoading = true);
            },
            onPageFinished: (_) {
              if (!_isDisposed) setState(() => _isLoading = false);
            },
            onWebResourceError: (error) {
              // 메인 프레임 로드 실패일 때만 에러 처리
              if (error.isForMainFrame ?? true) {
                if (!_isDisposed) setState(() => _isLoading = false);
                _onError();
              }
            },
            onNavigationRequest: _handleNavigationRequest,
          ),
        )
        ..loadRequest(uri);
    } catch (_) {
      // 네이티브 WebView 채널 연결 실패 (Hot Restart 후 등)
      // → 앱을 완전히 재시작하면 해결됨
      WidgetsBinding.instance.addPostFrameCallback((_) => _onError());
    }
  }

  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.navigate;

    if (uri.scheme == _callbackScheme) {
      final authCode = uri.queryParameters['code'];
      if (authCode != null && authCode.isNotEmpty) {
        _onAuthCode(authCode);
      } else {
        _onError();
      }
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  Future<void> _onAuthCode(String authCode) async {
    if (_isDisposed || !mounted) return;
    await ref
        .read(authCallbackViewModelProvider.notifier)
        .handleAuthCode(authCode, _codeVerifier);

    if (!mounted) return;

    final state = ref.read(authCallbackViewModelProvider);
    if (state.hasError) {
      _onError();
    } else {
      context.go(RoutePaths.splash);
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
    final controller = _controller;
    if (controller == null) {
      return const AuthBaseScaffold(body: SizedBox.shrink());
    }

    final isProcessing = ref.watch(authCallbackViewModelProvider).isLoading;

    return AuthBaseScaffold(
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (_isLoading || isProcessing)
            const ColoredBox(
              color: Colors.white54,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}





