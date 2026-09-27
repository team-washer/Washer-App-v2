import 'package:freezed_annotation/freezed_annotation.dart';

part 'reservation_availability_response.freezed.dart';
part 'reservation_availability_response.g.dart';

/// `reservations/availability` 응답. 내 예약 가능 여부와 패널티 만료 시각.
///
/// 패널티 판단은 서버 상태를 그대로 따른다(앱이 따로 기록하지 않는다).
@freezed
abstract class ReservationAvailabilityResponse
    with _$ReservationAvailabilityResponse {
  const factory ReservationAvailabilityResponse({
    /// 예약 가능 여부. 값이 없으면 막지 않는 쪽(true)으로 본다.
    @Default(true) bool canReserve,

    /// 패널티 만료 시각. 패널티가 없으면 null.
    String? penaltyExpiresAt,

    /// 호실 세탁 강제 금지 여부.
    @Default(false) bool isBanned,
  }) = _ReservationAvailabilityResponse;

  factory ReservationAvailabilityResponse.fromJson(Map<String, dynamic> json) =>
      _$ReservationAvailabilityResponseFromJson(json);
}
