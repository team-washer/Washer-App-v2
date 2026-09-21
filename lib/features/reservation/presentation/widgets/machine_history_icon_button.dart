import 'package:flutter/material.dart';
import 'package:washer/features/history/presentation/widgets/history_dialog.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_icon.dart';

/// 기기 사용 이력 다이얼로그를 여는 아이콘 버튼.
class MachineHistoryIconButton extends StatelessWidget {
  const MachineHistoryIconButton({
    super.key,
    required this.machineId,
    required this.machineName,
  });

  final int machineId;
  final String machineName;

  @override
  Widget build(BuildContext context) {
    return WasherIconButton(
      type: WasherIconType.historyCircle,
      color: WasherColor.baseGray300,
      size: 33,
      padding: EdgeInsets.zero,
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => HistoryDialog(
            machineId: machineId,
            machineName: machineName,
          ),
        );
      },
    );
  }
}
