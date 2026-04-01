import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/features/alarm/data/data_sources/alarm_data_source.dart';
import 'package:washer/features/alarm/data/repositories/alarm_repository_impl.dart';
import 'package:washer/features/alarm/domain/repositories/alarm_repository.dart';

final alarmRepositoryProvider = Provider<AlarmRepository>((ref) {
  return AlarmRepositoryImpl(ref.watch(alarmDataSourceProvider));
});
