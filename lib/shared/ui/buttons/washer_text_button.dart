import 'package:flutter/material.dart';

import 'package:washer/shared/theme/app_spacing.dart';

/// 배경색 알약 모양의 텍스트 버튼 공통 구현. 크기별 버튼이 글자 스타일만 바꿔 재사용한다.
class WasherTextButton extends StatelessWidget {
  final String text;
  final TextStyle typography;
  final Color color;
  final VoidCallback? onPressed;

  const WasherTextButton({
    super.key,
    required this.text,
    required this.typography,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: _buildButtonStyle(),
      child: Text(text, style: typography),
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
