import 'package:flutter/material.dart';
import 'package:project_setting/core/theme/color.dart';
import 'package:project_setting/core/theme/icon.dart';

enum LaundryMachineType { washer, dryer }

extension LaundryMachineTypeExt on LaundryMachineType {
  Widget get widget {
    switch (this) {
      case LaundryMachineType.washer:
        return WasherIcon(
          type: WasherIconType.waterCircle,
          color: WasherColor.mainColor400,
          size: 28,
        );
      case LaundryMachineType.dryer:
        return WasherIcon(
          type: WasherIconType.dryCircle,
          color: WasherColor.mainColor400,
          size: 28,
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
