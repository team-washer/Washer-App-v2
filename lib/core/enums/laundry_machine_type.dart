import 'package:flutter/material.dart';
import 'package:project_setting/core/theme/color.dart';
import 'package:project_setting/core/theme/icon.dart';

enum LaundryMachineType { washer, dryer }

extension LaundryMachineTypeExt on LaundryMachineType {
  Widget icon({
    Color? color,
    double size = 28,
  }) {
    final iconColor = color ?? WasherColor.mainColor400;

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

  String get text {
    switch (this) {
      case LaundryMachineType.washer:
        return "세탁";

      case LaundryMachineType.dryer:
        return "건조";
    }
  }
}
