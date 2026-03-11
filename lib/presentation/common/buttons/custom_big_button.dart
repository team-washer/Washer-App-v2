import 'package:flutter/material.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/presentation/common/buttons/washer_text_button.dart';

class CustomBigButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onPressed;

  const CustomBigButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return WasherTextButton(
      text: text,
      typography: WasherTypography.body4(Colors.white),
      color: color,
      onPressed: onPressed,
    );
  }
}
