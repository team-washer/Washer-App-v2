import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_icon.dart';
import 'package:washer/shared/theme/washer_typography.dart';

/// 설정 다이얼로그. 로그아웃/회원탈퇴 메뉴를 제공한다.
/// 메뉴를 누르면 먼저 다이얼로그를 닫은 뒤 각 콜백을 실행한다.
class SettingDialog extends StatelessWidget {
  final Future<void> Function() onLogoutTap;
  final Future<void> Function() onWithdrawTap;

  const SettingDialog({
    super.key,
    required this.onLogoutTap,
    required this.onWithdrawTap,
  });

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
            Text(
              '설정',
              style: WasherTypography.subTitle3(WasherColor.baseGray700),
            ),
            AppGap.v16,
            _SettingMenuItem(
              icon: WasherIconType.logout,
              label: '로그아웃',
              onTap: () async {
                Navigator.of(context).pop();
                await onLogoutTap();
              },
            ),
            AppGap.v8,
            _SettingMenuItem(
              icon: WasherIconType.withDraw,
              label: '회원탈퇴',
              onTap: () async {
                Navigator.of(context).pop();
                await onWithdrawTap();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 설정 다이얼로그 안의 메뉴 한 줄(아이콘 + 라벨 + 화살표).
class _SettingMenuItem extends StatelessWidget {
  final WasherIconType icon;
  final String label;
  final VoidCallback onTap;

  const _SettingMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.medium,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 10.h),
          child: Row(
            children: [
              WasherIcon(
                type: icon,
                size: 20,
                color: WasherColor.negative,
              ),
              AppGap.h12,
              Text(
                label,
                style: WasherTypography.body2(WasherColor.negative),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                size: 20.sp,
                color: WasherColor.negative,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
