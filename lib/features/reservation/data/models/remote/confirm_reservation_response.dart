import 'package:freezed_annotation/freezed_annotation.dart';

part 'confirm_reservation_response.freezed.dart';
part 'confirm_reservation_response.g.dart';

@freezed
abstract class ConfirmReservationResponse with _$ConfirmReservationResponse {
  const factory ConfirmReservationResponse({
    required String status,
    required int code,
    required String message,
  }) = _ConfirmReservationResponse;

  factory ConfirmReservationResponse.fromJson(Map<String, dynamic> json) =>
      _$ConfirmReservationResponseFromJson(json);
}
