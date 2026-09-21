import 'package:flutter/material.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/features/report/presentation/widgets/report_broken_dialog.dart';
import 'package:washer/features/reservation/presentation/widgets/machine_card_layout_helpers.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_icon.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_typography.dart';
import 'package:washer/shared/ui/buttons/washer_big_button.dart';

/// 예약 가능 상태의 카드 하단. 예약 버튼과 고장 신고 버튼을 보여준다.
class MachineCardAvailableFooter extends StatelessWidget {
  const MachineCardAvailableFooter({
    super.key,
    required this.laundryMachineType,
    this.onReserve,
    required this.machineId,
    required this.machineName,
    this.trailing,
  });

  final LaundryMachineType laundryMachineType;
  final VoidCallback? onReserve;
  final int machineId;
  final String machineName;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isReserveEnabled = onReserve != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        withTrailing(
          Text(
            '미사용 중',
            style: WasherTypography.body2(WasherColor.baseGray500),
          ),
          trailing,
        ),
        AppGap.v12,
        Row(
          children: [
            Expanded(
              child: WasherBigButton(
                text: '예약',
                onPressed: onReserve,
                color: isReserveEnabled
                    ? WasherColor.mainColor400
                    : WasherColor.baseGray300,
              ),
            ),
            AppGap.h8,
            WasherIconButton(
              type: WasherIconType.warningCircle,
              color: WasherColor.errorColor,
              size: 33,
              padding: EdgeInsets.zero,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    child: ReportBrokenDialog(
                      machineId: machineId,
                      deviceId: machineName,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
