import 'package:washer/core/notifications/notification_service.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/alarm/data/data_sources/alarm_data_source.dart';
import 'package:washer/features/alarm/data/models/local/alarm_model.dart';

class AlarmRepository {
  const AlarmRepository(this._dataSource, this._notificationService);

  final AlarmDataSource _dataSource;
  final NotificationService _notificationService;

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
