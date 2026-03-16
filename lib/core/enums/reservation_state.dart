import 'dart:ui';

import '../theme/color.dart';

enum ReservationState {
  inUse, // 사용중
  available, // 예약가능
  reservedByMe, // 예약완료 (본인)
  reservedByOther, // 예약완료 (타인)
  confirmed, // 예약확인중 (본인)
  unavailable, // 사용불가
}

extension ReservationStateText on ReservationState {
  String get label {
    switch (this) {
      case ReservationState.inUse:
        return '사용중';
      case ReservationState.available:
        return '예약가능';
      case ReservationState.reservedByMe:
        return '예약완료';
      case ReservationState.reservedByOther:
        return '예약완료';
      case ReservationState.confirmed:
        return '예약확인중';
      case ReservationState.unavailable:
        return '사용불가';
    }
  }

  Color get color {
    switch (this) {
      case ReservationState.available:
        return WasherColor.baseGray200;
      case ReservationState.inUse:
      case ReservationState.reservedByMe:
      case ReservationState.reservedByOther:
      case ReservationState.confirmed:
        return WasherColor.mainColor500;
      case ReservationState.unavailable:
        return WasherColor.errorColor;
    }
  }
}
