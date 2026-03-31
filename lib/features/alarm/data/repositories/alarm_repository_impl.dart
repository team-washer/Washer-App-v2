import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/features/alarm/data/data_sources/alarm_data_source.dart';
import 'package:washer/features/alarm/data/mapper/response/alarm_list_mapper.dart';
import 'package:washer/features/alarm/domain/entities/alarm_model.dart';
import 'package:washer/features/alarm/domain/repositories/alarm_repository.dart';

class AlarmRepositoryImpl implements AlarmRepository {
  const AlarmRepositoryImpl(this._dataSource);

  final AlarmDataSource _dataSource;

  @override
  Future<List<AlarmModel>> getAlarmList() async {
    final response = await _dataSource.getAlarmList();
    return response.toEntity();
  }
}

final alarmRepositoryProvider = Provider<AlarmRepository>((ref) {
  return AlarmRepositoryImpl(ref.watch(alarmDataSourceProvider));
});
