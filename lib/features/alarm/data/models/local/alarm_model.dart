import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:washer/features/alarm/data/models/alarm_type.dart';

part 'alarm_model.freezed.dart';

@freezed
abstract class AlarmModel with _$AlarmModel {
  const factory AlarmModel({
    required String id,
    required AlarmType status,
    required String time,
    required String description,
  }) = _AlarmModel;
}
