import 'package:flutter/material.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/features/reservation/presentation/widgets/machine_card_layout_helpers.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_typography.dart';

/// 자동 통세척 중이라 잠시 사용할 수 없는 기기의 카드 하단 안내.
class MachineCardCleaningFooter extends StatelessWidget {
  const MachineCardCleaningFooter({
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
        '${laundryMachineType.text} 자동 통세척 중이라 잠시 사용할 수 없습니다.',
        style: WasherTypography.body2(WasherColor.baseGray500),
      ),
      trailing,
    );
  }
}
