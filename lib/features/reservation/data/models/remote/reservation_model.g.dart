// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReservationModel _$ReservationModelFromJson(Map<String, dynamic> json) =>
    _ReservationModel(
      id: json['id'] as String,
      machineId: json['machineId'] as String,
      machineType: json['machineType'] as String,
      floor: (json['floor'] as num).toInt(),
      room: json['room'] as String,
      reservedAt: json['reservedAt'] as String,
      remainDuration: json['remainDuration'] as String?,
    );

Map<String, dynamic> _$ReservationModelToJson(_ReservationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'machineId': instance.machineId,
      'machineType': instance.machineType,
      'floor': instance.floor,
      'room': instance.room,
      'reservedAt': instance.reservedAt,
      'remainDuration': instance.remainDuration,
    };
