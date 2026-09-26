import 'package:flutter/material.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_icon.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_typography.dart';

/// 로그인 화면 헤더 — 로고 및 로그인 제목 표시
class LoginLogo extends StatelessWidget {
  const LoginLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        WasherIcon(type: WasherIconType.logo, size: 40),
        AppGap.v12,
        Flexible(
          child: Text(
            '로그인',
            style: WasherTypography.h1(WasherColor.baseGray700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
