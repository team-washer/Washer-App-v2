import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:washer/core/env/app_environment.dart';
import 'package:washer/core/router/route_paths.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/features/auth/presentation/viewmodels/auth_callback_view_model.dart';
import 'package:washer/features/auth/presentation/widgets/auth_base_scaffold.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _redirectUri = 'com.washer://auth/callback';
const _callbackScheme = 'com.washer';
const _webViewKey = ValueKey('auth-webview');

_AuthWebViewSession? _cachedAuthSession;

class _AuthWebViewSession {
  _AuthWebViewSession({
    required this.controller,
    required this.isLoading,
  });

  final WebViewController controller;
  final ValueNotifier<bool> isLoading;

  void dispose() {
    isLoading.dispose();
  }
}

class AuthWebViewScreen extends ConsumerStatefulWidget {
  const AuthWebViewScreen({super.key});

  static void preload() {
    _cachedAuthSession ??= _createSession();
  }

  static void clearPreloadedSession() {
    _cachedAuthSession?.dispose();
    _cachedAuthSession = null;
  }

  static _AuthWebViewSession? _createSession() {
    final environment = AppEnvironment.instance;
    final oauthBaseUrl = environment.oauthBaseUrl;
    final clientId = environment.oauthClientId;

    if (oauthBaseUrl.isEmpty || clientId.isEmpty) {
      return null;
    }

    final isLoading = ValueNotifier<bool>(true);
    final uri = Uri.parse(oauthBaseUrl).replace(
      queryParameters: {
        'redirect_uri': _redirectUri,
        'client_id': clientId,
      },
    );

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(WasherColor.backgroundColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => isLoading.value = true,
          onPageFinished: (_) => isLoading.value = false,
        ),
      )
      ..loadRequest(uri);

    return _AuthWebViewSession(
      controller: controller,
      isLoading: isLoading,
    );
  }

  @override
  ConsumerState<AuthWebViewScreen> createState() => _AuthWebViewScreenState();
}

class _AuthWebViewScreenState extends ConsumerState<AuthWebViewScreen> {
  _AuthWebViewSession? _session;
  bool _isDisposed = false;
  bool _isHandlingAuthCode = false;

  @override
  void initState() {
    super.initState();

    final session = _cachedAuthSession ?? AuthWebViewScreen._createSession();
    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onError());
      return;
    }

    _cachedAuthSession = session;
    _session = session;

    try {
      _attachNavigationDelegate(session);
    } catch (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onError());
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _attachNavigationDelegate(_AuthWebViewSession session) {
    session.controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (_) {
          if (!_isDisposed) {
            session.isLoading.value = true;
          }
        },
        onPageFinished: (_) {
          if (!_isDisposed) {
            session.isLoading.value = false;
          }
        },
        onWebResourceError: (error) {
          if (error.isForMainFrame ?? true) {
            session.isLoading.value = false;
            _onError();
          }
        },
        onNavigationRequest: _handleNavigationRequest,
      ),
    );
  }

  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.navigate;

    if (uri.scheme == _callbackScheme) {
      final authCode = uri.queryParameters['code'];
      if (authCode != null && authCode.isNotEmpty) {
        unawaited(_onAuthCode(authCode));
      } else {
        _onError();
      }
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  Future<void> _onAuthCode(String authCode) async {
    final session = _session;
    if (_isDisposed || !mounted || _isHandlingAuthCode || session == null) {
      return;
    }

    _isHandlingAuthCode = true;
    session.isLoading.value = true;

    await ref
        .read(authCallbackViewModelProvider.notifier)
        .handleAuthCode(authCode);

    if (!mounted) return;

    final state = ref.read(authCallbackViewModelProvider);
    if (state.hasError) {
      _onError();
    } else {
      AuthWebViewScreen.clearPreloadedSession();
      context.go(RoutePaths.splash);
    }
  }

  void _onError() {
    AuthWebViewScreen.clearPreloadedSession();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('로그인에 실패했습니다. 다시 시도해주세요.')),
    );
    context.go(RoutePaths.login);
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (session == null) {
      return const AuthBaseScaffold(body: SizedBox.shrink());
    }

    final isProcessing = ref.watch(authCallbackViewModelProvider).isLoading;

    return AuthBaseScaffold(
      body: Stack(
        children: [
          RepaintBoundary(
            child: WebViewWidget(
              key: _webViewKey,
              controller: session.controller,
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: session.isLoading,
            builder: (context, isLoading, _) {
              if (!isLoading && !isProcessing) {
                return const SizedBox.shrink();
              }

              return const ColoredBox(
                color: Colors.white54,
                child: Center(child: CircularProgressIndicator()),
              );
            },
          ),
        ],
      ),
    );
  }
}
