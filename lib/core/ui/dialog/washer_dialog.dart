import 'package:flutter/material.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/core/ui/buttons/custom_big_button.dart';

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
              backColor: backColor ?? WasherColor.baseGray200,
              confirmColor: confirmColor ?? WasherColor.mainColor500,
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
      // confirmText가 빈 문자열이면 단일 버튼(backButton)만 표시.
      // CustomBigButton 내부에 Expanded가 있으므로 반드시 Row 내부에 배치해야 
      // 세로 방향(Column)의 unbounded height 에러가 발생하지 않습니다.
      return Row(
        children: [
          CustomBigButton(
            text: backText,
            onPressed: onBackPressed,
            color: backColor,
          ),
        ],
      );
    }
    
    return Row(
      children: [
        CustomBigButton(
          text: backText,
          onPressed: onBackPressed,
          color: backColor,
        ),
        AppGap.h4,
        CustomBigButton(
          text: confirmText,
          onPressed: onConfirmPressed,
          color: confirmColor,
        ),
      ],
    );
  }
}
