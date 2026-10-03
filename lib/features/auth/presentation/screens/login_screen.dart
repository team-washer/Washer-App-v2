import 'package:flutter/material.dart';
import 'package:washer/features/auth/presentation/widgets/dg_login_button.dart';
import 'package:washer/features/auth/presentation/widgets/login_logo.dart';
import 'package:washer/shared/theme/washer_color.dart';

/// 로그인 화면 — 로고와 DataGSM 로그인 버튼을 표시한다.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WasherColor.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LoginLogo(),
              const SizedBox(height: 32),
              const DgLoginButton(),
            ],
          ),
        ),
      ),
    );
  }
}
