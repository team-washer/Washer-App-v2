import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/network/auth_notifier.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/core/network/token_utils.dart';
import 'package:washer/core/notifications/notification_service.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/alarm/data/repositories/alarm_repository.dart';

/// 앱 시작 시 알림(FCM) 초기화를 한 번 트리거하고 [child]를 그대로 렌더링하는 래퍼.
class NotificationBootstrapper extends ConsumerStatefulWidget {
  const NotificationBootstrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<NotificationBootstrapper> createState() =>
      _NotificationBootstrapperState();
}

class _NotificationBootstrapperState
    extends ConsumerState<NotificationBootstrapper> {
  StreamSubscription<String>? _tokenRefreshSubscription;

  @override
  void initState() {
    super.initState();

    final notificationService = ref.read(notificationServiceProvider);
    authNotifier.addListener(_handleLogout);
    _tokenRefreshSubscription = notificationService.onTokenRefresh.listen(
      (token) => unawaited(_registerRefreshedToken(token)),
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.error(
          'FCM token refresh stream failed.',
          name: 'NotificationBootstrapper',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );

    Future.microtask(() {
      unawaited(_initializeNotifications());
    });
  }

  Future<void> _initializeNotifications() async {
    try {
      await ref.read(notificationInitializationProvider.future);
      final alarmRepository = ref.read(alarmRepositoryProvider);
      if (!await _hasActiveSession()) {
        alarmRepository.disableFcmRegistration();
        return;
      }

      alarmRepository.enableFcmRegistrationForExistingSession();
      await alarmRepository.registerCurrentFcmToken();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to initialize notifications.',
        name: 'NotificationBootstrapper',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _registerRefreshedToken(String token) async {
    if (token.isEmpty) return;

    try {
      final alarmRepository = ref.read(alarmRepositoryProvider);
      if (!await _hasActiveSession()) {
        alarmRepository.disableFcmRegistration();
        return;
      }

      await alarmRepository.registerFcmToken(token);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to handle refreshed FCM token.',
        name: 'NotificationBootstrapper',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> _hasActiveSession() async {
    final storage = ref.read(secureStorageProvider);
    final tokens = await Future.wait<String?>([
      storage.read(key: 'access_token'),
      storage.read(key: 'refresh_token'),
    ]);
    if (!mounted) return false;

    return tokens.any(
      (token) =>
          token != null && token.isNotEmpty && !TokenUtils.isExpired(token),
    );
  }

  void _handleLogout() {
    ref
        .read(alarmRepositoryProvider)
        .disableFcmRegistration(blockUntilLogin: true);
  }

  @override
  void dispose() {
    authNotifier.removeListener(_handleLogout);
    _tokenRefreshSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
