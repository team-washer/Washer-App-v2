import 'package:flutter/material.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_typography.dart';
import 'package:washer/shared/ui/dialog/washer_dialog.dart';

/// 로그아웃 확인 다이얼로그. 확인이면 true, 취소면 false를 pop한다.
class LogoutConfirmDialog extends StatelessWidget {
  const LogoutConfirmDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: WasherDialog(
        title: '로그아웃',
        backText: '취소',
        confirmText: '로그아웃',
        confirmColor: WasherColor.errorColor,
        onBackPressed: () => Navigator.of(context).pop(false),
        onConfirmPressed: () => Navigator.of(context).pop(true),
        content: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.v16),
          child: Text(
            '로그아웃 하시겠습니까?',
            style: WasherTypography.subTitle4(),
          ),
        ),
      ),
    );
  }
}
