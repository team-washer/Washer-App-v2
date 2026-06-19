// freezed 생성자 파라미터에 붙은 @JsonKey 는 json_serializable 이 정상 적용하지만
// 분석기가 invalid_annotation_target 경고를 내므로 파일 단위로 무시한다.
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:washer/features/alarm/data/models/alarm_type.dart';

part 'alarm_list_response.freezed.dart';
part 'alarm_list_response.g.dart';

@freezed
abstract class AlarmListResponse with _$AlarmListResponse {
  const factory AlarmListResponse({
    @JsonKey(name: 'notifications')
    @Default(<Notifications>[])
    List<Notifications> data,
  }) = _AlarmListResponse;

  factory AlarmListResponse.fromJson(Map<String, dynamic> json) =>
      _$AlarmListResponseFromJson(json);
}

@freezed
abstract class Notifications with _$Notifications {
  const factory Notifications({
    // 서버가 id를 숫자로 내려주므로 문자열로 안전하게 변환한다.
    @JsonKey(fromJson: _idFromJson) required String id,
    // 알 수 없는 타입이 와도 목록 전체가 깨지지 않도록 unknown으로 폴백한다.
    @JsonKey(unknownEnumValue: AlarmType.unknown) required AlarmType type,
    required String message,
    required String createdAt,
  }) = _Notifications;

  factory Notifications.fromJson(Map<String, dynamic> json) =>
      _$NotificationsFromJson(json);
}

String _idFromJson(Object? value) => value?.toString() ?? '';
