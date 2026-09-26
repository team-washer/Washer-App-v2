import 'package:flutter/material.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_typography.dart';

/// 다이얼로그 본문의 "라벨: 값" 한 줄.
class DialogInfoRow extends StatelessWidget {
  const DialogInfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: WasherTypography.subTitle4(),
        ),
        AppGap.h8,
        Expanded(
          child: Text(
            value,
            style: WasherTypography.body1(),
          ),
        ),
      ],
    );
  }
}
