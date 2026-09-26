import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/notifications/notification_service.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/alarm/data/data_sources/alarm_data_source.dart';
import 'package:washer/features/alarm/data/models/local/alarm_model.dart';

/// 알림 목록 조회/삭제와 FCM 토큰 등록/삭제를 담당하는 저장소.
///
/// 삭제·토큰 관련 실패는 로그만 남기고 예외를 밖으로 던지지 않는다.
class AlarmRepository {
  const AlarmRepository(this._dataSource, this._notificationService);

  final AlarmDataSource _dataSource;
  final NotificationService _notificationService;

  /// 서버 알림 응답을 화면용 [AlarmModel] 목록으로 변환해 반환한다.
  Future<List<AlarmModel>> fetchAlarms() async {
    final response = await _dataSource.getAlarmList();
    return response.data
        .map(
          (notification) => AlarmModel(
            id: notification.id,
            status: notification.type,
            time: notification.createdAt,
            description: notification.message,
          ),
        )
        .toList();
  }

  /// 서버의 모든 알림을 삭제한다.
  Future<void> deleteAllNotifications() async {
    try {
      await _dataSource.deleteAllNotifications();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to delete all notifications.',
        name: 'AlarmRepository',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// 현재 기기의 FCM 토큰을 확보해 서버에 등록한다.
  Future<void> registerCurrentFcmToken() async {
    String? fcmToken;
    try {
      fcmToken = await _notificationService.ensureFcmToken();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to prepare FCM token.',
        name: 'AlarmRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return;
    }

    if (fcmToken == null || fcmToken.isEmpty) {
      return;
    }

    try {
      await _dataSource.registerFcmToken(fcmToken);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to register FCM token.',
        name: 'AlarmRepository',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// 서버에서 FCM 토큰을 삭제하고, 로컬에 저장된 토큰도 함께 지운다.
  Future<void> deleteFcmToken() async {
    try {
      await _dataSource.deleteFcmToken();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to delete FCM token.',
        name: 'AlarmRepository',
        error: error,
        stackTrace: stackTrace,
      );
    }

    await _notificationService.deleteStoredFcmToken();
  }
}

final alarmRepositoryProvider = Provider<AlarmRepository>((ref) {
  return AlarmRepository(
    ref.watch(alarmDataSourceProvider),
    ref.watch(notificationServiceProvider),
  );
});
