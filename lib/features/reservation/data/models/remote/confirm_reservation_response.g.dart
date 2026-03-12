// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'confirm_reservation_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ConfirmReservationResponse _$ConfirmReservationResponseFromJson(
  Map<String, dynamic> json,
) => _ConfirmReservationResponse(
  status: json['status'] as String,
  code: (json['code'] as num).toInt(),
  message: json['message'] as String,
);

Map<String, dynamic> _$ConfirmReservationResponseToJson(
  _ConfirmReservationResponse instance,
) => <String, dynamic>{
  'status': instance.status,
  'code': instance.code,
  'message': instance.message,
};
