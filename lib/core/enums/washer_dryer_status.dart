import 'dart:ui';

import '../theme/color.dart';

enum WasherDryerStatus {
  waiting,        // 대기
  reserved,       // 예약완료
  needConfirm,    // 확인필요
  inUse,          // 사용중
  completed,      // 완료
}

extension WasherDryerStatusExt on WasherDryerStatus {
  String get label {
    switch (this) {
      case WasherDryerStatus.waiting:
        return "대기";
      case WasherDryerStatus.reserved:
        return "예약완료";
      case WasherDryerStatus.needConfirm:
        return "확인필요";
      case WasherDryerStatus.inUse:
        return "사용중";
      case WasherDryerStatus.completed:
        return "완료";
    }
  }

  Color get color {
    switch (this) {
      case WasherDryerStatus.needConfirm:
        return WasherColor.errorColor;
      case WasherDryerStatus.waiting:
        return WasherColor.mainColor200;
      case WasherDryerStatus.inUse:
        return WasherColor.mainColor500;
      case WasherDryerStatus.reserved:
        return WasherColor.mainColor500;
      case WasherDryerStatus.completed:
        return WasherColor.mainColor500;
    }
  }
}
