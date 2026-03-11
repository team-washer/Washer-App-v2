import 'package:flutter/material.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/icon.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';

class HomeSectionHeaderWidget extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const HomeSectionHeaderWidget({
    super.key,
    required this.title,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionTitleWidget(title: title),
        _ViewAllButton(onTap: onViewAll),
      ],
    );
  }
}

class HomeSectionTitleWidget extends StatelessWidget {
  final String title;

  const HomeSectionTitleWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: WasherTypography.h2());
  }
}

class _ViewAllButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _ViewAllButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '전체보기',
            style: WasherTypography.body2(WasherColor.baseGray300),
          ),
          AppGap.h4,
          WasherIcon(
            type: WasherIconType.back,
            size: 16,
            color: WasherColor.baseGray300,
          ),
        ],
      ),
    );
  }
}
