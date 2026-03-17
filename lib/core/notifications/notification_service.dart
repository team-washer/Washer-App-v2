import 'dart:async';

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

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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

  static bool _timeZoneInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initializeLocalNotifications();
    await _requestPermissions();
    await _saveFcmToken();

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
      '${reservation.machineType.text} ?꾨즺 ?뚮┝',
      '${reservation.machineName} ?ъ슜???꾨즺?섏뿀?듬땲?? ?명긽臾쇱쓣 ?뺤씤?댁＜?몄슂.',
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
    final title = notification?.title ?? '?명긽 ?뚮┝';
    final body = notification?.body ?? '???뚮┝???꾩갑?덉뒿?덈떎.';

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
      description: '?명긽 諛?嫄댁“ ?꾨즺 ?뚮┝ 梨꾨꼸',
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

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _completionChannelId,
        _completionChannelName,
        channelDescription: '?명긽 諛?嫄댁“ ?꾨즺 ?뚮┝ 梨꾨꼸',
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


