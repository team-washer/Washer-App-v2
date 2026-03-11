import 'package:flutter/material.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';

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
        borderRadius: AppRadius.circular,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          machineType.icon(
            color: isUsed ? WasherColor.baseGray200 : WasherColor.mainColor400,
          ),
          const SizedBox(width: AppSpacing.h12),
          Text(
            '$machine-${floor}F-$side$number',
            style: WasherTypography.body3(
              isUsed ? WasherColor.baseGray200 : WasherColor.baseGray700,
            ),
          ),
        ],
      ),
    );
  }
}
