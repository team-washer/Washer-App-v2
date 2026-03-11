import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:washer/core/router/route_paths.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/icon.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/presentation/common/scaffold/base_scaffold.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLogo(),
          const SizedBox(
            height: 32,
          ),
          _buildDgLoginButton(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        WasherIcon(
          type: WasherIconType.logo,
          size: 40,
        ),
        const SizedBox(width: AppSpacing.v12),
        Text(
          '로그인',
          style: WasherTypography.h1(WasherColor.baseGray700),
        ),
      ],
    );
  }

  Widget _buildDgLoginButton() {
    return Builder(
      builder: (context) => SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          onPressed: () => context.push(RoutePaths.authWebView),
          style: ElevatedButton.styleFrom(
            backgroundColor: WasherColor.mainColor600,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.small,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              WasherIcon(
                type: WasherIconType.dgWhite,
                size: 12,
              ),
              const SizedBox(width: 10),
              Text(
                'DG 로그인 하기',
                style: WasherTypography.body1(
                  Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
