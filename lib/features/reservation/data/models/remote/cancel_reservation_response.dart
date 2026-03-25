import 'package:freezed_annotation/freezed_annotation.dart';

part 'cancel_reservation_response.freezed.dart';
part 'cancel_reservation_response.g.dart';

@freezed
abstract class CancelReservationResponse with _$CancelReservationResponse {
  const factory CancelReservationResponse({
    required bool success,
    required String message,
    required bool penaltyApplied,
    required String penaltyExpiresAt,
  }) = _CancelReservationResponse;

  factory CancelReservationResponse.fromJson(Map<String, dynamic> json) =>
      _$CancelReservationResponseFromJson(json);
}
