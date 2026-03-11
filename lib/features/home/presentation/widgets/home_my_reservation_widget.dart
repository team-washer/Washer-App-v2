import 'package:flutter/material.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/enums/laundry_status.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/core/ui/buttons/custom_small_button.dart';
import 'package:washer/core/ui/reservation_state_widget.dart';
import 'package:washer/features/reservation/data/models/laundry_machine_model.dart';

part 'local_widgets/my_machine_card.dart';
part 'local_widgets/my_reservation_card.dart';
part 'local_widgets/reservation_card.dart';
part 'local_widgets/reservation_body.dart';
part 'local_widgets/reservation_bottom_section.dart';

class HomeMyReservationWidget extends StatelessWidget {
  final List<MachineModel> machines;

  const HomeMyReservationWidget({super.key, required this.machines});

  @override
  Widget build(BuildContext context) {
    final myMachine = machines
        .where((m) => m.userId != null && m.operatingState == 'running')
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('301호 예약 현황', style: WasherTypography.h2()),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.v16),
          child: myMachine != null
              ? _MyMachineCard(machine: myMachine)
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.v24),
                    child: Text(
                      '현재 예약하거나 사용중인 기기가 없습니다.',
                      style: WasherTypography.body1(WasherColor.baseGray300),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
