// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_reservation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ActiveReservationModel _$ActiveReservationModelFromJson(
  Map<String, dynamic> json,
) => _ActiveReservationModel(
  id: (json['id'] as num).toInt(),
  userId: (json['userId'] as num).toInt(),
  userName: json['userName'] as String,
  userRoomNumber: json['userRoomNumber'] as String,
  machineId: (json['machineId'] as num).toInt(),
  machineName: json['machineName'] as String,
  reservedAt: json['reservedAt'] as String?,
  startTime: json['startTime'] as String?,
  expectedCompletionTime: json['expectedCompletionTime'] as String?,
  actualCompletionTime: json['actualCompletionTime'] as String?,
  status: json['status'] as String,
);

Map<String, dynamic> _$ActiveReservationModelToJson(
  _ActiveReservationModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'userName': instance.userName,
  'userRoomNumber': instance.userRoomNumber,
  'machineId': instance.machineId,
  'machineName': instance.machineName,
  'reservedAt': instance.reservedAt,
  'startTime': instance.startTime,
  'expectedCompletionTime': instance.expectedCompletionTime,
  'actualCompletionTime': instance.actualCompletionTime,
  'status': instance.status,
};
