import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_typography.dart';

/// 회원탈퇴 완료 안내 다이얼로그(닫기 버튼 하나).
class WithdrawCompleteDialog extends StatelessWidget {
  const WithdrawCompleteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        width: double.infinity,
        padding: AppPadding.card,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.v16),
              child: Text(
                '그동안 Washer를 사용해 주셔서 감사합니다.',
                style: WasherTypography.subTitle4(),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: WasherColor.mainColor400,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.medium,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
                child: Text(
                  '닫기',
                  style: WasherTypography.body1(Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
