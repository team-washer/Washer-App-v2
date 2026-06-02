import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:washer/core/env/app_environment.dart';
import 'package:washer/core/router/route_paths.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/auth/presentation/providers/auth_callback_provider.dart';
import 'package:washer/features/auth/presentation/widgets/auth_base_scaffold.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _redirectUri = 'com.washer.v2://auth/callback';
const _callbackScheme = 'com.washer.v2';
const _webViewKey = ValueKey('auth-webview');

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

  static _AuthWebViewSession? _createSession() {
    final environment = AppEnvironment.instance;
    final oauthBaseUrl = environment.oauthBaseUrl;
    final clientId = environment.oauthClientId;

    if (oauthBaseUrl.isEmpty || clientId.isEmpty) {
      return null;
    }

    final isLoading = ValueNotifier<bool>(true);

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(WasherColor.backgroundColor);

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

    final session = AuthWebViewScreen._createSession();
    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onError());
      return;
    }

    _session = session;

    try {
      _attachNavigationDelegate(session);
      session.controller.loadRequest(_buildAuthUri());
    } catch (error, stackTrace) {
      AppLogger.error(
        '인증 WebView 초기화 중 오류가 발생했습니다.',
        name: 'AuthWebViewScreen',
        error: error,
        stackTrace: stackTrace,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _onError());
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _session?.dispose();
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
          if (_isCallbackUrl(error.url) || _isHandlingAuthCode) {
            return;
          }

          if (error.isForMainFrame ?? true) {
            session.isLoading.value = false;
            _showErrorMessage();
          }
        },
        onNavigationRequest: _handleNavigationRequest,
      ),
    );
  }

  Uri _buildAuthUri() {
    final environment = AppEnvironment.instance;
    return Uri.parse(environment.oauthBaseUrl).replace(
      queryParameters: {
        'redirect_uri': _redirectUri,
        'client_id': environment.oauthClientId,
      },
    );
  }

  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.navigate;

    if (_isCallbackUri(uri)) {
      final authCode = uri.queryParameters['code'];
      if (authCode != null && authCode.isNotEmpty) {
        unawaited(_onAuthCode(authCode));
      } else {
        _showErrorMessage();
      }
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  bool _isCallbackUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }

    return _isCallbackUri(Uri.tryParse(url));
  }

  bool _isCallbackUri(Uri? uri) {
    return uri?.scheme == _callbackScheme;
  }

  Future<void> _onAuthCode(String authCode) async {
    final session = _session;
    if (_isDisposed || !mounted || _isHandlingAuthCode || session == null) {
      return;
    }

    _isHandlingAuthCode = true;
    session.isLoading.value = true;

    final isSuccess = await ref
        .read(authCallbackProvider.notifier)
        .handleAuthCode(authCode: authCode, redirectUri: _redirectUri);

    if (!mounted) return;

    if (!isSuccess) {
      _isHandlingAuthCode = false;
      session.isLoading.value = false;
      _showErrorMessage(_resolveLoginErrorMessage());
    } else {
      context.go(RoutePaths.splash);
    }
  }

  void _onError() {
    if (!mounted) return;
    _showErrorMessage();
    context.go(RoutePaths.login);
  }

  String? _resolveLoginErrorMessage() {
    final error = ref.read(authCallbackProvider).error;
    if (error is! DioException || error.response?.statusCode != 403) {
      return null;
    }

    final response = error.response?.data;
    if (response is Map<String, dynamic>) {
      final message = response['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    return null;
  }

  void _showErrorMessage([String? message]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? '로그인에 실패했습니다. 다시 시도해주세요.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (session == null) {
      return const AuthBaseScaffold(body: SizedBox.shrink());
    }

    final isProcessing = ref.watch(authCallbackProvider).isLoading;

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
                color: WasherColor.backgroundColor,
                child: Center(child: CircularProgressIndicator()),
              );
            },
          ),
        ],
      ),
    );
  }
}
