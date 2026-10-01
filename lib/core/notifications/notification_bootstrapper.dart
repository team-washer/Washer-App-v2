import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/network/auth_notifier.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/core/notifications/fcm_diagnostic.dart';
import 'package:washer/core/notifications/fcm_session.dart';
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
    extends ConsumerState<NotificationBootstrapper>
    with WidgetsBindingObserver {
  StreamSubscription<String>? _tokenRefreshSubscription;

  @override
  void initState() {
    super.initState();

    final notificationService = ref.read(notificationServiceProvider);
    WidgetsBinding.instance.addObserver(this);
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
      await _syncCurrentFcmToken(trigger: FcmSyncTrigger.appStart);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to initialize notifications.',
        name: 'NotificationBootstrapper',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _syncCurrentFcmToken({required FcmSyncTrigger trigger}) async {
    AppLogger.info(
      'FCM sync started. trigger=${trigger.name}',
      name: 'NotificationBootstrapper',
    );
    final alarmRepository = ref.read(alarmRepositoryProvider);
    if (!await _hasActiveSession()) {
      AppLogger.info(
        'FCM sync skipped because there is no active session. trigger=${trigger.name}',
        name: 'NotificationBootstrapper',
      );
      ref
          .read(fcmDiagnosticProvider.notifier)
          .recordSessionUnavailable(trigger);
      return;
    }

    alarmRepository.enableFcmRegistrationForExistingSession();
    await alarmRepository.registerCurrentFcmToken(trigger: trigger);
  }

  Future<void> _syncCurrentFcmTokenAfterResume() async {
    AppLogger.info(
      'Resume FCM sync requested.',
      name: 'NotificationBootstrapper',
    );
    try {
      await _syncCurrentFcmToken(trigger: FcmSyncTrigger.resume);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to sync FCM token after app resumed.',
        name: 'NotificationBootstrapper',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncCurrentFcmTokenAfterResume());
    }
  }

  Future<void> _registerRefreshedToken(String token) async {
    if (token.isEmpty) return;

    try {
      AppLogger.info(
        'FCM sync started. trigger=token_refresh, token=[REDACTED], length=${token.length}',
        name: 'NotificationBootstrapper',
      );
      final alarmRepository = ref.read(alarmRepositoryProvider);
      if (!await _hasActiveSession()) {
        return;
      }

      await alarmRepository.registerFcmToken(
        token,
        trigger: FcmSyncTrigger.tokenRefresh,
      );
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
    final hasActiveSession = await hasActiveNotificationSession(storage);
    if (!mounted) return false;
    return hasActiveSession;
  }

  void _handleLogout() {
    ref
        .read(alarmRepositoryProvider)
        .disableFcmRegistration(blockUntilLogin: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    authNotifier.removeListener(_handleLogout);
    _tokenRefreshSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
