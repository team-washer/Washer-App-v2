import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:washer/core/router/route_paths.dart';
import 'package:washer/shared/theme/icon.dart';
import 'package:washer/shared/theme/spacing.dart';
import 'package:washer/shared/theme/typography.dart';

class DgLoginButtonWidget extends StatelessWidget {
  const DgLoginButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: () {
          context.push(RoutePaths.authWebView);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            WasherIcon(type: WasherIconType.dgLogo, size: 12),
            AppGap.h10,
            Text(
              'DataGSM으로 로그인',
              style: WasherTypography.body1(Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
