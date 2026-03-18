import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:washer/core/router/route_paths.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/icon.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/features/auth/presentation/screens/auth_webview_screen.dart';

class DgLoginButtonWidget extends StatelessWidget {
  const DgLoginButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: () {
          unawaited(Future<void>.microtask(AuthWebViewScreen.preload));
          context.push(RoutePaths.authWebView);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: WasherColor.mainColor600,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            WasherIcon(type: WasherIconType.dgWhite, size: 12),
            AppGap.h10,
            Flexible(
              child: Text(
                'DG 로그인하기',
                style: WasherTypography.body1(Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}