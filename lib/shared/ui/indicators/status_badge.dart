import 'package:flutter/material.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_typography.dart';

/// 예약/기기 상태를 색상 배경의 알약 모양으로 보여주는 배지.
/// [textStyle]을 생략하면 흰색 body4를 사용한다.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final TextStyle? textStyle;

  const StatusBadge({
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
        borderRadius: AppRadius.circular,
      ),
      child: Text(
        label,
        style: textStyle ?? WasherTypography.body4(Colors.white),
      ),
    );
  }
}
