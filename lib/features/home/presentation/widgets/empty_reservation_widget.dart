import 'package:flutter/material.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/typography.dart';

class EmptyReservationWidget extends StatelessWidget {
  const EmptyReservationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Text(
          '현재 예약하거나 사용중인 기기가 없습니다.',
          style: WasherTypography.body1(WasherColor.baseGray300),
        ),
      ),
    );
  }
}
