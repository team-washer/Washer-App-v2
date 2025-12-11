import 'package:flutter/material.dart';
import 'package:project_setting/core/theme/typography.dart';

class StateWidget extends StatelessWidget {
  final String text;
  final Color color;

  const StateWidget({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color),
      child: Text("", style: WasherTypography.body4(Colors.white)),
    );
  }
}
