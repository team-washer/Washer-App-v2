import 'package:flutter/material.dart';
import 'package:project_setting/core/theme/typography.dart';
import 'package:project_setting/presentation/common/buttons/washer_text_button.dart';

class CustomSmallButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onPressed;

  const CustomSmallButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return WasherTextButton(
      text: text,
      typography: WasherTypography.body2(Colors.white),
      color: color,
      onPressed: onPressed,
    );
  }
}
