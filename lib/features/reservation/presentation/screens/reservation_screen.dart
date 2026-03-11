import 'package:flutter/material.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/features/reservation/presentation/widgets/reservation_base_scaffold.dart';
import 'package:washer/features/reservation/presentation/widgets/reservation_list_widget.dart';

class ReservationScreen extends StatelessWidget {
  final LaundryMachineType laundryMachineType;

  const ReservationScreen({super.key, required this.laundryMachineType});

  @override
  Widget build(BuildContext context) {
    return ReservationBaseScaffold(
      sectionTitle: Text(
        '${laundryMachineType.text}기 예약 현황',
        style: WasherTypography.h2(),
      ),
      reservationList: ReservationListWidget(laundryMachineType: laundryMachineType),
    );
  }
}
