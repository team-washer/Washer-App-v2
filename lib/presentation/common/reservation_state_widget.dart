import 'package:flutter/material.dart';
import 'package:project_setting/core/theme/typography.dart';

class ReservationStateWidget extends StatelessWidget {
  final String label;
  final Color color;
  final TextStyle? textStyle;

  const ReservationStateWidget({
    super.key,
    required this.label,
    required this.color,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.5, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1000),
      ),
      child: Text(
        label,
        style: textStyle == null
            ? textStyle
            : WasherTypography.body4(Colors.white),
      ),
    );
  }
}
