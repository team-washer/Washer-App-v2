import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:washer/features/alarm/data/models/alarm_type.dart';

part 'alarm_model.freezed.dart';

/// 화면에서 사용하는 알람 한 건 (응답의 Notifications를 변환한 모델)
@freezed
abstract class AlarmModel with _$AlarmModel {
  const factory AlarmModel({
    required String id,
    required AlarmType status,
    required String time,
    required String description,
  }) = _AlarmModel;
}
