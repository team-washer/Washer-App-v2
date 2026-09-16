// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'laundry_machine_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MachineModel _$MachineModelFromJson(Map<String, dynamic> json) =>
    _MachineModel(
      machineId: (json['machineId'] as num).toInt(),
      name: json['name'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      availability: json['availability'] as String,
      operatingState: json['operatingState'] as String?,
      jobState: json['jobState'] as String?,
      switchStatus: json['switchStatus'] as String?,
      expectedCompletionTime: json['expectedCompletionTime'] as String?,
      remainingMinutes: (json['remainingMinutes'] as num?)?.toInt(),
      reservationId: (json['reservationId'] as num?)?.toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      userStudentId: json['userStudentId'] as String?,
      userName: json['userName'] as String?,
      roomNumber: json['roomNumber'] as String?,
    );

Map<String, dynamic> _$MachineModelToJson(_MachineModel instance) =>
    <String, dynamic>{
      'machineId': instance.machineId,
      'name': instance.name,
      'type': instance.type,
      'status': instance.status,
      'availability': instance.availability,
      'operatingState': instance.operatingState,
      'jobState': instance.jobState,
      'switchStatus': instance.switchStatus,
      'expectedCompletionTime': instance.expectedCompletionTime,
      'remainingMinutes': instance.remainingMinutes,
      'reservationId': instance.reservationId,
      'userId': instance.userId,
      'userStudentId': instance.userStudentId,
      'userName': instance.userName,
      'roomNumber': instance.roomNumber,
    };

_MachineStatusResponse _$MachineStatusResponseFromJson(
  Map<String, dynamic> json,
) => _MachineStatusResponse(
  machines: (json['machines'] as List<dynamic>)
      .map((e) => MachineModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalCount: (json['totalCount'] as num).toInt(),
);

Map<String, dynamic> _$MachineStatusResponseToJson(
  _MachineStatusResponse instance,
) => <String, dynamic>{
  'machines': instance.machines,
  'totalCount': instance.totalCount,
};
