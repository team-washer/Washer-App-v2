import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/notifications/notification_service.dart';
import 'package:washer/features/alarm/data/data_sources/alarm_data_source.dart';
import 'package:washer/features/alarm/data/repositories/alarm_repository.dart';

final alarmRepositoryProvider = Provider<AlarmRepository>((ref) {
  return AlarmRepository(
    ref.watch(alarmDataSourceProvider),
    ref.watch(notificationServiceProvider),
  );
});
