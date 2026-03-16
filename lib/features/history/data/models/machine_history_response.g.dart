// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'machine_history_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MachineHistoryResponse _$MachineHistoryResponseFromJson(
  Map<String, dynamic> json,
) => _MachineHistoryResponse(
  content: (json['content'] as List<dynamic>)
      .map((e) => HistoryContent.fromJson(e as Map<String, dynamic>))
      .toList(),
  pageNumber: (json['pageNumber'] as num).toInt(),
  pageSize: (json['pageSize'] as num).toInt(),
  totalElements: (json['totalElements'] as num).toInt(),
  totalPages: (json['totalPages'] as num).toInt(),
  last: json['last'] as bool,
);

Map<String, dynamic> _$MachineHistoryResponseToJson(
  _MachineHistoryResponse instance,
) => <String, dynamic>{
  'content': instance.content,
  'pageNumber': instance.pageNumber,
  'pageSize': instance.pageSize,
  'totalElements': instance.totalElements,
  'totalPages': instance.totalPages,
  'last': instance.last,
};

_HistoryContent _$HistoryContentFromJson(Map<String, dynamic> json) =>
    _HistoryContent(
      id: (json['id'] as num).toInt(),
      userRoomNumber: json['userRoomNumber'] as String,
      startTime: json['startTime'] as String,
      completionTime: json['completionTime'] as String,
      status: json['status'] as String,
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$HistoryContentToJson(_HistoryContent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userRoomNumber': instance.userRoomNumber,
      'startTime': instance.startTime,
      'completionTime': instance.completionTime,
      'status': instance.status,
      'createdAt': instance.createdAt,
    };
