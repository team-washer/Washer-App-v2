import 'package:flutter/material.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/icon.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';

class LoginLogoWidget extends StatelessWidget {
  const LoginLogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        WasherIcon(type: WasherIconType.logo, size: 40),
        const SizedBox(width: AppSpacing.v12),
        Text('로그인', style: WasherTypography.h1(WasherColor.baseGray700)),
      ],
    );
  }
}
