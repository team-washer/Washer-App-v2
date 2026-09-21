import 'package:flutter/material.dart';
import 'package:washer/shared/theme/washer_typography.dart';
import 'package:washer/shared/ui/buttons/washer_text_button.dart';

/// 다이얼로그 하단 등에 쓰는 큰 버튼(body1 흰색 글자). [onPressed]가 null이면 비활성.
class WasherBigButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback? onPressed;

  const WasherBigButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return WasherTextButton(
      text: text,
      typography: WasherTypography.body1(
        Colors.white,
      ),
      color: color,
      onPressed: onPressed,
    );
  }
}
