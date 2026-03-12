// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cancel_reservation_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CancelReservationResponse _$CancelReservationResponseFromJson(
  Map<String, dynamic> json,
) => _CancelReservationResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  penaltyApplied: json['penaltyApplied'] as bool,
  penaltyExpiresAt: json['penaltyExpiresAt'] as String,
);

Map<String, dynamic> _$CancelReservationResponseToJson(
  _CancelReservationResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'penaltyApplied': instance.penaltyApplied,
  'penaltyExpiresAt': instance.penaltyExpiresAt,
};
