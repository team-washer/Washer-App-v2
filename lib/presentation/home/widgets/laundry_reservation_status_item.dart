import 'package:flutter/material.dart';
import 'package:project_setting/core/enums/laundry_machine_type.dart';
import 'package:project_setting/core/theme/color.dart';
import 'package:project_setting/core/theme/typography.dart';

class LaundryReservationStatusItem extends StatelessWidget {
  final LaundryMachineType machineType;
  final int floor;
  final int number;
  final String side;
  final bool isUsed;

  const LaundryReservationStatusItem({
    super.key,
    required this.machineType,
    required this.floor,
    required this.number,
    required this.side,
    required this.isUsed,
  });

  @override
  Widget build(BuildContext context) {
    String machine = machineType.text;

    switch (machineType) {
      case LaundryMachineType.washer:
        machine = "Washer";
        break;
      case LaundryMachineType.dryer:
        machine = "Dryer";
        break;
    }

    return Container(
      width: double.infinity, // 최대 너비 차지
      padding: const EdgeInsets.symmetric(
        horizontal: 17.5,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          machineType.icon(
            color: isUsed ? WasherColor.baseGray200 : null,
          ),
          const SizedBox(width: 12),
          Text(
            '$machine-${floor}F-$side$number',
            style: WasherTypography.body3(
              isUsed ? WasherColor.baseGray200 : WasherColor.baseGray600,
            ),
          ),
        ],
      ),
    );
  }
}
