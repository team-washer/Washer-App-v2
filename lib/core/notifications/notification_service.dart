import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/firebase_options.dart';

const _completionChannelId = 'laundry_completion';
const _completionChannelName = 'Laundry Completion';
const _completionNotificationId = 1001;
const _scheduledReservationKey = 'scheduled_completion_reservation_key';
const _fcmTokenKey = 'fcm_token';
const _apnsTokenRetryDelay = Duration(seconds: 1);
const _apnsTokenMaxRetries = 10;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // 로컬 알림 플러그인 초기화
  final localNotifications = FlutterLocalNotificationsPlugin();

  const initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    ),
  );
  await localNotifications.initialize(initializationSettings);

  // Android 알림 채널 생성
  await localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          _completionChannelId,
          _completionChannelName,
          description: '세탁 및 건조 완료 알림 채널',
          importance: Importance.max,
        ),
      );

  final notification = message.notification;
  final title = notification?.title ?? '세탁 알림';
  final body = notification?.body ?? '새 알림이 도착했습니다.';

  await localNotifications.show(
    message.messageId?.hashCode.abs() ??
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        _completionChannelId,
        _completionChannelName,
        channelDescription: '세탁 및 건조 완료 알림 채널',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: message.data.isEmpty ? null : message.data.toString(),
  );
}

class NotificationService {
  NotificationService(
    this._messaging,
    this._localNotifications,
    this._storage,
  );

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final FlutterSecureStorage _storage;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  bool _isInitialized = false;

  bool _timeZoneInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initializeLocalNotifications();
    await _requestPermissions();
    await _saveFcmTokenWhenReady();

    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((token) {
      unawaited(_storage.write(key: _fcmTokenKey, value: token));
      if (kDebugMode) {
        debugPrint('FCM token refreshed: $token');
      }
    });

    _foregroundMessageSubscription ??= FirebaseMessaging.onMessage.listen((
      message,
    ) {
      unawaited(showRemoteNotification(message));
    });

    _isInitialized = true;
  }

  Future<void> syncReservationCompletionNotification(
    ActiveReservationModel? reservation,
  ) async {
    await initialize();

    if (reservation == null) {
      await cancelScheduledCompletionNotification();
      return;
    }

    final completionTime = DateTime.tryParse(
      reservation.expectedCompletionTime ?? '',
    );
    final shouldSchedule =
        completionTime != null &&
        completionTime.isAfter(DateTime.now()) &&
        (reservation.status == 'CONFIRMED' || reservation.status == 'IN_USE');

    if (!shouldSchedule) {
      await cancelScheduledCompletionNotification();
      return;
    }

    final reservationKey =
        '${reservation.id}:${reservation.status}:${reservation.expectedCompletionTime}';
    final scheduledReservationKey = await _storage.read(
      key: _scheduledReservationKey,
    );

    if (scheduledReservationKey == reservationKey) {
      return;
    }

    await _localNotifications.cancel(_completionNotificationId);

    await _localNotifications.zonedSchedule(
      _completionNotificationId,
      '${reservation.machineType.text} 완료 알림',
      '${reservation.machineName} 사용이 완료되었습니다. 세탁물을 확인해주세요.',
      tz.TZDateTime.from(completionTime, tz.local),
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'completion:${reservation.id}',
    );

    await _storage.write(key: _scheduledReservationKey, value: reservationKey);
  }

  Future<void> cancelScheduledCompletionNotification() async {
    await _localNotifications.cancel(_completionNotificationId);
    await _storage.delete(key: _scheduledReservationKey);
  }

  Future<void> showRemoteNotification(RemoteMessage message) async {
    await _initializeLocalNotifications();

    final notification = message.notification;
    final title = notification?.title ?? '세탁 알림';
    final body = notification?.body ?? '새 알림이 도착했습니다.';

    await _localNotifications.show(
      _remoteNotificationId(message),
      title,
      body,
      _notificationDetails(),
      payload: message.data.isEmpty ? null : message.data.toString(),
    );
  }

  Future<String?> getStoredFcmToken() {
    return _storage.read(key: _fcmTokenKey);
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _foregroundMessageSubscription?.cancel();
  }

  Future<void> _initializeLocalNotifications() async {
    if (!_timeZoneInitialized) {
      tz.initializeTimeZones();
      _timeZoneInitialized = true;
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _localNotifications.initialize(initializationSettings);

    const channel = AndroidNotificationChannel(
      _completionChannelId,
      _completionChannelName,
      description: '세탁 및 건조 완료 알림 채널',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> _saveFcmToken() async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    await _storage.write(key: _fcmTokenKey, value: token);
    if (kDebugMode) {
      debugPrint('FCM token: $token');
    }
  }

  Future<void> _saveFcmTokenWhenReady() async {
    if (Platform.isIOS) {
      final apnsTokenReady = await _waitForApnsToken();
      if (!apnsTokenReady) {
        if (kDebugMode) {
          debugPrint(
            'APNS token is not ready yet. Skipping initial FCM token save.',
          );
        }
        return;
      }
    }

    try {
      await _saveFcmToken();
    } on FirebaseException catch (e) {
      if (_isApnsTokenNotSetError(e)) {
        if (kDebugMode) {
          debugPrint('FCM token skipped until APNS token is available.');
        }
        return;
      }
      rethrow;
    }
  }

  Future<bool> _waitForApnsToken() async {
    for (var attempt = 0; attempt < _apnsTokenMaxRetries; attempt++) {
      try {
        final token = await _messaging.getAPNSToken();
        if (token != null && token.isNotEmpty) {
          if (kDebugMode) {
            debugPrint('APNS token received.');
          }
          return true;
        }
      } on FirebaseException catch (e) {
        if (!_isApnsTokenNotSetError(e)) {
          rethrow;
        }
      }

      await Future<void>.delayed(_apnsTokenRetryDelay);
    }

    return false;
  }

  bool _isApnsTokenNotSetError(FirebaseException error) {
    return error.plugin == 'firebase_messaging' &&
        error.code == 'apns-token-not-set';
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _completionChannelId,
        _completionChannelName,
        channelDescription: '세탁 및 건조 완료 알림 채널',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  int _remoteNotificationId(RemoteMessage message) {
    return message.messageId?.hashCode.abs() ??
        DateTime.now().millisecondsSinceEpoch.remainder(100000);
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService(
    FirebaseMessaging.instance,
    FlutterLocalNotificationsPlugin(),
    ref.watch(secureStorageProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final notificationInitializationProvider = FutureProvider<void>((ref) async {
  await ref.watch(notificationServiceProvider).initialize();
});
