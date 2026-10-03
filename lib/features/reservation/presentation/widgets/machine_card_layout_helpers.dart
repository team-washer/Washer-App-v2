import 'package:flutter/material.dart';
import 'package:washer/shared/theme/app_spacing.dart';

/// 텍스트 블록의 마지막 줄 우측에 [trailing]을 같은 줄로 붙인다.
/// [trailing]이 null이면 텍스트 블록을 그대로 반환한다.
Widget withTrailing(Widget textBlock, Widget? trailing) {
  if (trailing == null) return textBlock;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(child: textBlock),
      AppGap.h8,
      trailing,
    ],
  );
}

/// 공백뿐인 문자열도 비어 있는 것으로 본다.
bool hasText(String? value) => value != null && value.trim().isNotEmpty;
