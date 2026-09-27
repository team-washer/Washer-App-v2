import 'package:flutter/material.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/features/reservation/data/models/local/machine_model.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_typography.dart';
import 'package:washer/shared/ui/dialog/laundry_status_dialog.dart';

/// 기기 1대의 이름/사용 가능 여부를 보여주는 타일. 탭하면 상태 다이얼로그를 띄운다.
class MachineStatusTile extends StatelessWidget {
  const MachineStatusTile({super.key, required this.machine});

  final MachineModel machine;

  @override
  Widget build(BuildContext context) {
    final machineType = machine.type == 'WASHER'
        ? LaundryMachineType.washer
        : LaundryMachineType.dryer;
    final isAvailable = machine.isAvailable;
    final machineState = machine.machineState;

    return GestureDetector(
      onTap: () async {
        await showDialog(
          context: context,
          builder: (_) => LaundryStatusDialog(
            machineType: machineType,
            machineName: machine.name,
            machineId: machine.machineId,
            isUsed: !isAvailable,
            isUnavailable: machine.isUnavailable,
            isCleaning: machine.isCleaning,
            machineState: machineState,
            roomNumber: machine.roomNumber,
            expectedTime: machine.expectedCompletionTime,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: 17.5,
          vertical: AppSpacing.v12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.circular,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              machineType.icon(
                color: isAvailable
                    ? WasherColor.mainColor300
                    : WasherColor.baseGray300,
              ),
              AppGap.h12,
              Text(
                machine.name,
                style: WasherTypography.body1(
                  isAvailable
                      ? WasherColor.baseGray800
                      : WasherColor.baseGray500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
