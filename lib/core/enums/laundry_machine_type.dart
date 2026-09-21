import 'package:flutter/material.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_icon.dart';

/// 기기 종류(세탁기/건조기).
enum LaundryMachineType { washer, dryer }

extension LaundryMachineTypeExt on LaundryMachineType {
  /// 기기 종류에 맞는 원형 아이콘 위젯.
  Widget icon({
    Color? color,
    double size = 28,
  }) {
    final iconColor = color ?? WasherColor.mainColor300;

    switch (this) {
      case LaundryMachineType.washer:
        return WasherIcon(
          type: WasherIconType.waterCircle,
          color: iconColor,
          size: size,
        );

      case LaundryMachineType.dryer:
        return WasherIcon(
          type: WasherIconType.dryCircle,
          color: iconColor,
          size: size,
        );
    }
  }

  /// 화면에 표시할 종류 이름.
  String get text {
    switch (this) {
      case LaundryMachineType.washer:
        return "세탁";

      case LaundryMachineType.dryer:
        return "건조";
    }
  }

  /// 서버 API에서 사용하는 종류 문자열.
  String get apiValue {
    switch (this) {
      case LaundryMachineType.washer:
        return 'WASHER';
      case LaundryMachineType.dryer:
        return 'DRYER';
    }
  }
}
