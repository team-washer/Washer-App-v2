import 'package:flutter/material.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/features/reservation/presentation/widgets/reservation_base_scaffold.dart';
import 'package:washer/features/reservation/presentation/widgets/reservation_section_widget.dart';
import 'package:washer/features/reservation/presentation/widgets/reservation_title_widget.dart';

class ReservationScreen extends StatelessWidget {
  final LaundryMachineType laundryMachineType;

  const ReservationScreen({super.key, required this.laundryMachineType});

  @override
  Widget build(BuildContext context) {
    return ReservationBaseScaffold(
      sectionTitle: ReservationTitleWidget(
        laundryMachineType: laundryMachineType,
      ),
      reservationList: ReservationSectionWidget(
        laundryMachineType: laundryMachineType,
      ),
    );
  }
}
