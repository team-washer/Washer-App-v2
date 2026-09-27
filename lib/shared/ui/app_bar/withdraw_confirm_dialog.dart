import 'package:flutter/material.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_typography.dart';
import 'package:washer/shared/ui/dialog/washer_dialog.dart';

/// 회원탈퇴 확인 다이얼로그. 확인이면 true, 취소면 false를 pop한다.
class WithdrawConfirmDialog extends StatelessWidget {
  const WithdrawConfirmDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: WasherDialog(
        title: '회원탈퇴',
        backText: '취소',
        confirmText: '회원탈퇴',
        confirmColor: WasherColor.errorColor,
        onBackPressed: () => Navigator.of(context).pop(false),
        onConfirmPressed: () => Navigator.of(context).pop(true),
        content: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.v16),
          child: Text(
            'Washer 회원탈퇴를 하시겠습니까?',
            style: WasherTypography.subTitle4(WasherColor.negative),
          ),
        ),
      ),
    );
  }
}
