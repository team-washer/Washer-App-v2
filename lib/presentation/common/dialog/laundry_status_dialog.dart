import 'package:flutter/material.dart';
import 'package:project_setting/core/enums/laundry_machine_type.dart';
import 'package:project_setting/core/enums/machine_state.dart';
import 'package:project_setting/core/theme/color.dart';
import 'package:project_setting/core/theme/spacing.dart';
import 'package:project_setting/core/theme/typography.dart';
import 'package:project_setting/presentation/common/dialog/washer_dialog.dart';

class LaundryStatusDialog extends StatelessWidget {
  final LaundryMachineType machineType;
  final int floor;
  final String side;
  final int number;
  final bool isUsed;
  final MachineState? machineState; // 현재 기기 상태
  final String? roomNumber; // 예: "503호"
  final String? expectedTime; // 예: "25.08.18. 01:24"

  const LaundryStatusDialog({
    super.key,
    required this.machineType,
    required this.floor,
    required this.side,
    required this.number,
    required this.isUsed,
    this.machineState,
    this.roomNumber,
    this.expectedTime,
  });

  String get _machineId {
    String machine = machineType == LaundryMachineType.washer
        ? "Washer"
        : "Dryer";
    return '$machine-${floor}F-$side$number';
  }

  String get _statusText {
    if (!isUsed) return "사용 가능";
    if (machineState != null) return "사용중 (${machineState!.text})";
    return "사용중";
  }

  String get _specialNotes {
    if (expectedTime == null) return "없음";

    if (machineState == MachineState.delayWash) {
      return "예약 만료까지: $expectedTime";
    }
    if (machineType == LaundryMachineType.dryer) {
      return "건조 완료 예정시간: $expectedTime";
    }
    return "세탁 완료 예정시간: $expectedTime";
  }

  @override
  Widget build(BuildContext context) {
    return WasherDialog(
      title: "세탁기 현황",
      confirmText: isUsed ? "확인" : "예약하기",
      onConfirmPressed: isUsed
          ? null
          : () {
              // TODO: 예약 로직 수행
            },
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.v10),
          _buildInfoRow("기기명", _machineId),
          const SizedBox(height: AppSpacing.v8),
          _buildInfoRow("상태", _statusText),
          const SizedBox(height: AppSpacing.v10),
          _buildInfoRow("사용호실", roomNumber ?? "없음"),
          const SizedBox(height: AppSpacing.v10),
          _buildInfoRow("특이사항", _specialNotes),
          const SizedBox(height: AppSpacing.v10),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: WasherTypography.subTitle4(),
        ),
        const SizedBox(width: AppSpacing.h8),
        Expanded(
          child: Text(
            value,
            style: WasherTypography.body1(WasherColor.baseGray400),
          ),
        ),
      ],
    );
  }
}
