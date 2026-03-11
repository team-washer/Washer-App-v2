import 'package:flutter/material.dart';
import 'package:washer/core/theme/spacing.dart';

class ReservationBaseScaffold extends StatelessWidget {
  final Widget sectionTitle;
  final Widget reservationList;

  const ReservationBaseScaffold({
    super.key,
    required this.sectionTitle,
    required this.reservationList,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle,
        AppGap.v16,
        Expanded(child: reservationList),
      ],
    );
  }
}
