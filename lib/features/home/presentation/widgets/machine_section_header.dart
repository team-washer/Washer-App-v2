import 'package:flutter/material.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_icon.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_typography.dart';

/// 기기 섹션 제목(좌)과 "전체보기" 버튼(우)으로 구성된 헤더
class MachineSectionHeader extends StatelessWidget {
  const MachineSectionHeader({
    super.key,
    required this.title,
    this.onViewAll,
  });

  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: WasherTypography.subTitle1(WasherColor.baseGray800),
        ),
        GestureDetector(
          onTap: onViewAll,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '전체보기',
                style: WasherTypography.body2(WasherColor.baseGray500),
              ),
              AppGap.h4,
              const WasherIcon(
                type: WasherIconType.back,
                size: 16,
                color: WasherColor.baseGray500,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
