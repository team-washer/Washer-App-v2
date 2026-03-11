import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:washer/core/router/route_paths.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/presentation/auth/login/viewModels/login_view_model.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _redirectUri = 'com.washer://auth/callback';
const _callbackScheme = 'com.washer';

class AuthWebViewScreen extends ConsumerStatefulWidget {
  const AuthWebViewScreen({super.key});

  @override
  ConsumerState<AuthWebViewScreen> createState() => _AuthWebViewScreenState();
}

class _AuthWebViewScreenState extends ConsumerState<AuthWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    final oauthBaseUrl = dotenv.env['OAUTH_BASE_URL']!;
    final uri = Uri.parse(oauthBaseUrl).replace(
      queryParameters: {
        'redirect_uri': _redirectUri,
        'client_id': dotenv.env['OAUTH_CLIENT_ID']!,
      },
    );

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(WasherColor.backgroundColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: _handleNavigationRequest,
        ),
      )
      ..loadRequest(uri);
  }

  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.navigate;

    // OAuth 콜백 인터셉트: com.washer://auth/callback?code=XXX
    if (uri.scheme == _callbackScheme) {
      final authCode = uri.queryParameters['code'];
      if (authCode != null && authCode.isNotEmpty) {
        _handleAuthCode(authCode);
      } else {
        _showError();
      }
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  Future<void> _handleAuthCode(String authCode) async {
    await ref.read(loginViewModelProvider.notifier).loginWithCode(authCode);

    if (!mounted) return;

    final loginState = ref.read(loginViewModelProvider);
    if (loginState.hasError) {
      _showError();
    } else {
      context.go(RoutePaths.home);
    }
  }

  void _showError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('로그인에 실패했습니다. 다시 시도해주세요.')),
    );
    context.go(RoutePaths.login);
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = ref.watch(loginViewModelProvider).isLoading;

    return Scaffold(
      backgroundColor: WasherColor.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading || isProcessing)
              const ColoredBox(
                color: Colors.white54,
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
