import 'package:flutter/material.dart';
import 'package:project_setting/core/theme/color.dart';
import 'package:project_setting/core/theme/typography.dart';
import 'package:project_setting/presentation/common/buttons/custom_big_button.dart';

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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: WasherTypography.subTitle3(),
          ),
          content,
          Row(
            children: [
              CustomBigButton(
                text: backText ?? "뒤로가기",
                onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                color: backColor ?? WasherColor.baseGray200,
              ),
              const SizedBox(width: 4),
              CustomBigButton(
                text: confirmText ?? "확인",
                onPressed:
                    onConfirmPressed ?? () => Navigator.of(context).pop(),
                color: confirmColor ?? WasherColor.mainColor500,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
