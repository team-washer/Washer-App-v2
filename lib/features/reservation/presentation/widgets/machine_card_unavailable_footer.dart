import 'package:flutter/material.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/features/reservation/presentation/widgets/machine_card_layout_helpers.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_typography.dart';

/// 고장 등으로 사용할 수 없는 기기의 카드 하단 안내.
class MachineCardUnavailableFooter extends StatelessWidget {
  const MachineCardUnavailableFooter({
    super.key,
    required this.laundryMachineType,
    this.trailing,
  });

  final LaundryMachineType laundryMachineType;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return withTrailing(
      Text(
        '${laundryMachineType.text} 기기 고장으로 인해 당분간 사용할 수 없습니다.',
        style: WasherTypography.body2(WasherColor.errorColor),
      ),
      trailing,
    );
  }
}
