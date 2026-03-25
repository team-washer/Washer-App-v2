import 'package:flutter/material.dart';
import 'package:washer/features/auth/presentation/widgets/auth_base_scaffold.dart';
import 'package:washer/features/auth/presentation/widgets/dg_login_button_widget.dart';
import 'package:washer/features/auth/presentation/widgets/login_logo_widget.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthBaseScaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LoginLogoWidget(),
            const SizedBox(height: 32),
            const DgLoginButtonWidget(),
          ],
        ),
      ),
    );
  }
}
