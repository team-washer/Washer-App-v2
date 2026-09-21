import 'dart:ui';

import 'package:washer/shared/theme/washer_color.dart';

/// 내 예약/이용 현황의 진행 단계.
enum LaundryStatus {
  reserved, // 예약완료
  needConfirm, // 확인필요
  inUse, // 사용중
  completed, // 완료
}

extension LaundryStatusExt on LaundryStatus {
  /// 화면에 표시할 상태 문구.
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

  /// 상태별 강조 색상.
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

  /// 상태 뱃지 뒤에 추가 여백이 필요한지 여부(대기중 상태에서만 true).
  bool get needsSpacing {
    return !(this == LaundryStatus.inUse ||
        this == LaundryStatus.needConfirm ||
        this == LaundryStatus.completed);
  }
}
