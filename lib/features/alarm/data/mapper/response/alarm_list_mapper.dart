import 'package:washer/features/alarm/data/models/response/alarm_list_response.dart';
import 'package:washer/features/alarm/domain/entities/alarm_model.dart';

extension AlarmListResponseMapper on AlarmListResponse {
  List<AlarmModel> toEntity() {
    return data.map((notification) => notification.toEntity()).toList();
  }
}

extension NotificationMapper on Notifications {
  AlarmModel toEntity() {
    return AlarmModel(
      id: id,
      status: type,
      time: createdAt,
      description: message,
      reason: null, // TODO: 추후 변경 예정
    );
  }
}
