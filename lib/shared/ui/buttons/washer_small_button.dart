import 'package:flutter/material.dart';
import 'package:washer/shared/theme/washer_typography.dart';
import 'package:washer/shared/ui/buttons/washer_text_button.dart';

/// 카드 안 등에 쓰는 작은 버튼(body2 흰색 글자).
class WasherSmallButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onPressed;

  const WasherSmallButton({
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
