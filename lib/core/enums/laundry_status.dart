import 'dart:ui';

import '../theme/color.dart';

enum LaundryStatus {
  reserved, // 예약완료
  needConfirm, // 확인필요
  inUse, // 사용중
  completed, // 완료
}

extension LaundryStatusExt on LaundryStatus {
  String get label {
    switch (this) {
      case LaundryStatus.reserved:
        return "대기중";
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
        return WasherColor.mainColor300;
      case LaundryStatus.inUse:
        return WasherColor.mainColor400;
      case LaundryStatus.completed:
        return WasherColor.mainColor400;
    }
  }

  bool get needsSpacing {
    return !(this == LaundryStatus.inUse ||
        this == LaundryStatus.needConfirm ||
        this == LaundryStatus.completed);
  }
}
