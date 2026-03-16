import 'dart:ui';

import '../theme/color.dart';

enum LaundryStatus {
  reserved, // 예약완료
  confirmed, // 예약확인 및 기기 동작 감지
  needConfirm, // 확인필요
  inUse, // 사용중
  completed, // 완료
}

extension LaundryStatusExt on LaundryStatus {
  String get label {
    switch (this) {
      case LaundryStatus.reserved:
        return "대기중";
      case LaundryStatus.confirmed:
        return "예약완료";
      case LaundryStatus.needConfirm:
        return "확인필요";
      case LaundryStatus.inUse:
        return "사용중";
      case LaundryStatus.completed:
        return "완료";
    }
  }

  Color get color {
    switch (this) {
      case LaundryStatus.needConfirm:
        return WasherColor.errorColor;
      case LaundryStatus.reserved:
        return WasherColor.mainColor200;
      case LaundryStatus.inUse:
        return WasherColor.mainColor500;
      case LaundryStatus.confirmed:
        return WasherColor.mainColor500;
      case LaundryStatus.completed:
        return WasherColor.mainColor500;
    }
  }

  bool get needsSpacing {
    return !(this == LaundryStatus.inUse ||
        this == LaundryStatus.needConfirm ||
        this == LaundryStatus.completed);
  }
}
