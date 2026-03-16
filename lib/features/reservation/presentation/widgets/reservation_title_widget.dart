import 'package:flutter/material.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/theme/typography.dart';

/// 예약 내역 제목 위젯 (세탁기/건조기 목록 제메이)
class ReservationTitleWidget extends StatelessWidget {
  final LaundryMachineType laundryMachineType;

  const ReservationTitleWidget({super.key, required this.laundryMachineType});

  @override
  Widget build(BuildContext context) {
    return Text(
      '${laundryMachineType.text}기 예약 현황',
      style: WasherTypography.h2(),
    );
  }
}
