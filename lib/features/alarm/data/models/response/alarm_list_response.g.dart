// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_list_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AlarmListResponse _$AlarmListResponseFromJson(Map<String, dynamic> json) =>
    _AlarmListResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => Notifications.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AlarmListResponseToJson(_AlarmListResponse instance) =>
    <String, dynamic>{'data': instance.data};

_Notifications _$NotificationsFromJson(Map<String, dynamic> json) =>
    _Notifications(
      id: json['id'] as String,
      type: json['type'] as String,
      message: json['message'] as String,
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$NotificationsToJson(_Notifications instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'message': instance.message,
      'createdAt': instance.createdAt,
    };
