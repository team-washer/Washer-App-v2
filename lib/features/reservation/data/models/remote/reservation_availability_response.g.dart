// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation_availability_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReservationAvailabilityResponse _$ReservationAvailabilityResponseFromJson(
  Map<String, dynamic> json,
) => _ReservationAvailabilityResponse(
  canReserve: json['canReserve'] as bool? ?? true,
  penaltyExpiresAt: json['penaltyExpiresAt'] as String?,
  isBanned: json['isBanned'] as bool? ?? false,
);

Map<String, dynamic> _$ReservationAvailabilityResponseToJson(
  _ReservationAvailabilityResponse instance,
) => <String, dynamic>{
  'canReserve': instance.canReserve,
  'penaltyExpiresAt': instance.penaltyExpiresAt,
  'isBanned': instance.isBanned,
};
