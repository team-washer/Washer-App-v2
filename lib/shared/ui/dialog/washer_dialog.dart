import 'package:flutter/material.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_typography.dart';
import 'package:washer/shared/ui/buttons/washer_big_button.dart';

/// 앱 공통 확인 다이얼로그(제목 + 본문 + 뒤로가기/확인 버튼).
/// 버튼 문구·색·콜백을 생략하면 기본값(닫기)으로 동작하며,
/// [confirmText]가 빈 문자열이면 뒤로가기 버튼 하나만 표시한다.
class WasherDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final String? backText;
  final String? confirmText;
  final Color? backColor;
  final Color? confirmColor;
  final VoidCallback? onBackPressed;
  final VoidCallback? onConfirmPressed;

  const WasherDialog({
    super.key,
    required this.title,
    required this.content,
    this.backText,
    this.confirmText,
    this.backColor,
    this.confirmColor,
    this.onBackPressed,
    this.onConfirmPressed,
  });

  void _pop(BuildContext context) => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
            _WasherDialogHeader(title: title),
            content,
            _WasherDialogActions(
              backText: backText ?? "뒤로가기",
              confirmText: confirmText ?? "확인",
              backColor: backColor ?? WasherColor.baseGray300,
              confirmColor: confirmColor ?? WasherColor.mainColor400,
              onBackPressed: onBackPressed ?? () => _pop(context),
              onConfirmPressed: onConfirmPressed ?? () => _pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _WasherDialogHeader extends StatelessWidget {
  final String title;

  const _WasherDialogHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: WasherTypography.subTitle3(),
    );
  }
}

class _WasherDialogActions extends StatelessWidget {
  final String backText;
  final String confirmText;
  final Color backColor;
  final Color confirmColor;
  final VoidCallback onBackPressed;
  final VoidCallback onConfirmPressed;

  const _WasherDialogActions({
    required this.backText,
    required this.confirmText,
    required this.backColor,
    required this.confirmColor,
    required this.onBackPressed,
    required this.onConfirmPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (confirmText.isEmpty) {
      return Row(
        children: [
          Expanded(
            child: WasherBigButton(
              text: backText,
              onPressed: onBackPressed,
              color: backColor,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: WasherBigButton(
            text: backText,
            onPressed: onBackPressed,
            color: backColor,
          ),
        ),
        AppGap.h4,
        Expanded(
          child: WasherBigButton(
            text: confirmText,
            onPressed: onConfirmPressed,
            color: confirmColor,
          ),
        ),
      ],
    );
  }
}
