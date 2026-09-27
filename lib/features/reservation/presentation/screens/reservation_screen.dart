import 'package:flutter/material.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/features/reservation/presentation/widgets/reservation_machine_list.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_typography.dart';

/// 세탁기/건조기 예약 화면. 제목과 층별 기기 목록으로 구성된다.
class ReservationScreen extends StatelessWidget {
  final LaundryMachineType laundryMachineType;

  const ReservationScreen({super.key, required this.laundryMachineType});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${laundryMachineType.text}기 예약 현황',
          style: WasherTypography.subTitle1(WasherColor.baseGray800),
        ),
        AppGap.v16,
        Expanded(
          child: ReservationMachineList(
            laundryMachineType: laundryMachineType,
          ),
        ),
      ],
    );
  }
}
