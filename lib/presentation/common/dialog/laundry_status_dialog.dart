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

  final MachineState? machineState;
  final String? roomNumber;
  final String? expectedTime;

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

  LaundryStatusViewData get _viewData => LaundryStatusViewData.from(
    machineType: machineType,
    floor: floor,
    side: side,
    number: number,
    isUsed: isUsed,
    machineState: machineState,
    roomNumber: roomNumber,
    expectedTime: expectedTime,
  );

  @override
  Widget build(BuildContext context) {
    final vd = _viewData;

    return WasherDialog(
      title: vd.title,
      confirmText: vd.confirmText,
      onConfirmPressed: vd.onConfirmPressed == null
          ? null
          : () => vd.onConfirmPressed!.call(context),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppGap.v10,
          _InfoRow(label: "기기명", value: vd.machineId),
          AppGap.v8,
          _InfoRow(label: "상태", value: vd.statusText),
          AppGap.v10,
          _InfoRow(label: "사용호실", value: vd.roomText),
          AppGap.v10,
          _InfoRow(label: "특이사항", value: vd.notesText),
          AppGap.v10,
        ],
      ),
    );
  }
}

class LaundryStatusViewData {
  final String title;
  final String machineId;
  final String statusText;
  final String roomText;
  final String notesText;

  final String confirmText;
  final void Function(BuildContext context)? onConfirmPressed;

  LaundryStatusViewData({
    required this.title,
    required this.machineId,
    required this.statusText,
    required this.roomText,
    required this.notesText,
    required this.confirmText,
    required this.onConfirmPressed,
  });

  factory LaundryStatusViewData.from({
    required LaundryMachineType machineType,
    required int floor,
    required String side,
    required int number,
    required bool isUsed,
    required MachineState? machineState,
    required String? roomNumber,
    required String? expectedTime,
  }) {
    final machineName = machineType == LaundryMachineType.washer
        ? "Washer"
        : "Dryer";
    final machineId = '$machineName-${floor}F-$side$number';

    final title = machineType == LaundryMachineType.washer
        ? "세탁기 현황"
        : "건조기 현황";

    final statusText = _buildStatusText(isUsed, machineState);
    final roomText = roomNumber ?? "없음";
    final notesText = _buildNotesText(
      machineType: machineType,
      machineState: machineState,
      expectedTime: expectedTime,
    );

    final confirmText = isUsed ? "확인" : "예약하기";
    final onConfirmPressed = isUsed
        ? null
        : (BuildContext context) {
            // TODO: 예약 플로우 진입 (예: Navigator push / bloc event)
          };

    return LaundryStatusViewData(
      title: title,
      machineId: machineId,
      statusText: statusText,
      roomText: roomText,
      notesText: notesText,
      confirmText: confirmText,
      onConfirmPressed: onConfirmPressed,
    );
  }

  static String _buildStatusText(bool isUsed, MachineState? machineState) {
    if (!isUsed) return "사용 가능";
    if (machineState != null) return "사용중 (${machineState.text})";
    return "사용중";
  }

  static String _buildNotesText({
    required LaundryMachineType machineType,
    required MachineState? machineState,
    required String? expectedTime,
  }) {
    if (expectedTime == null) return "없음";

    if (machineState == MachineState.delayWash) {
      return "예약 만료까지: $expectedTime";
    }
    if (machineType == LaundryMachineType.dryer) {
      return "건조 완료 예정시간: $expectedTime";
    }
    return "세탁 완료 예정시간: $expectedTime";
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: WasherTypography.subTitle4()),
        AppGap.h8,
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
