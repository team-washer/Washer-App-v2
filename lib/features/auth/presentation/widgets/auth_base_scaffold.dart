import 'package:flutter/material.dart';
import 'package:washer/core/theme/color.dart';

/// 인증 메뉴의 기본 레이아웃 스캐폴드
class AuthBaseScaffold extends StatelessWidget {
  final Widget body;

  const AuthBaseScaffold({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WasherColor.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: body,
      ),
    );
  }
}
