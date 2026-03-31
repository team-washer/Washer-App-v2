import 'package:washer/features/alarm/domain/entities/alarm_model.dart';

abstract class AlarmRepository {
  Future<List<AlarmModel>> getAlarmList();
}
