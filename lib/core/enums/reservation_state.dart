import 'dart:ui';

import 'package:washer/shared/theme/washer_color.dart';

/// 기기 카드에 표시되는 예약 관점의 기기 상태.
enum ReservationState {
  inUse, // 사용중
  available, // 예약가능
  reservedByMe, // 예약완료 (본인)
  reservedByOther, // 예약완료 (타인)
  unavailable, // 사용불가
}

extension ReservationStateText on ReservationState {
  /// 화면에 표시할 상태 문구.
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
      case ReservationState.unavailable:
        return '사용불가';
    }
  }

  /// 상태별 강조 색상.
  Color get color {
    switch (this) {
      case ReservationState.available:
        return WasherColor.baseGray300;
      case ReservationState.inUse:
      case ReservationState.reservedByMe:
      case ReservationState.reservedByOther:
        return WasherColor.mainColor400;
      case ReservationState.unavailable:
        return WasherColor.errorColor;
    }
  }
}
