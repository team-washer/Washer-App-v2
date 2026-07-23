// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'cancel_reservation_response.freezed.dart';
part 'cancel_reservation_response.g.dart';

@freezed
abstract class CancelReservationResponse with _$CancelReservationResponse {
  const factory CancelReservationResponse({
    @JsonKey(defaultValue: false) required bool success,
    @JsonKey(defaultValue: '') required String message,
    @JsonKey(defaultValue: false) required bool penaltyApplied,
    @JsonKey(defaultValue: '') required String penaltyExpiresAt,
  }) = _CancelReservationResponse;

  factory CancelReservationResponse.fromJson(Map<String, dynamic> json) =>
      _$CancelReservationResponseFromJson(json);
}
