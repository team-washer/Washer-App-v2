import 'package:flutter/material.dart';

import 'package:washer/core/theme/spacing.dart';

class WasherTextButton extends StatelessWidget {
  final String text;
  final TextStyle typography;
  final Color color;
  final VoidCallback onPressed;

  const WasherTextButton({
    super.key,
    required this.text,
    required this.typography,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: _buildButtonStyle(),
        child: Text(text, style: typography),
      ),
    );
  }

  ButtonStyle _buildButtonStyle() {
    return ElevatedButton.styleFrom(
      padding: AppPadding.button,
      backgroundColor: color,
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.circular,
      ),
    );
  }
}
