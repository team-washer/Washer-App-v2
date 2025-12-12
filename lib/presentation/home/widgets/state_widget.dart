import 'package:flutter/material.dart';
import 'package:project_setting/core/enums/washer_dryer_status.dart';
import 'package:project_setting/core/theme/typography.dart';

class StateWidget extends StatelessWidget {
  final WasherDryerStatus status;

  const StateWidget({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.5, vertical: 4),
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: BorderRadius.circular(1000),
      ),
      child: Text(
        status.label,
        style: WasherTypography.body4(Colors.white),
      ),
    );
  }
}
