import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:washer/features/alarm/data/models/alarm_type.dart';

part 'alarm_list_response.freezed.dart';
part 'alarm_list_response.g.dart';

@freezed
abstract class AlarmListResponse with _$AlarmListResponse {
  const factory AlarmListResponse({
    required List<Notifications> data,
  }) = _AlarmListResponse;

  factory AlarmListResponse.fromJson(Map<String, dynamic> json) =>
      _$AlarmListResponseFromJson(json);
}

@freezed
abstract class Notifications with _$Notifications {
  const factory Notifications({
    required String id,
    required AlarmType type,
    required String message,
    required String createdAt,
  }) = _Notifications;

  factory Notifications.fromJson(Map<String, dynamic> json) =>
      _$NotificationsFromJson(json);
}
