import 'package:flutter/material.dart';
import 'package:project_setting/core/theme/color.dart';
import 'package:project_setting/core/theme/icon.dart';
import 'package:project_setting/core/theme/spacing.dart';
import 'package:project_setting/core/theme/typography.dart';

/// 네비게이션 탭 아이템 정의
enum NavTabType {
  dryer,
  home,
  washer,
}

extension NavTabTypeExtension on NavTabType {
  String get label {
    switch (this) {
      case NavTabType.dryer:
        return '건조기';
      case NavTabType.home:
        return '홈';
      case NavTabType.washer:
        return '세탁기';
    }
  }

  WasherIconType get iconType {
    switch (this) {
      case NavTabType.dryer:
        return WasherIconType.dry;
      case NavTabType.home:
        return WasherIconType.home;
      case NavTabType.washer:
        return WasherIconType.water;
    }
  }
}

/// 하단 네비게이션 바 위젯
class WasherBottomNavigationBar extends StatelessWidget {
  final NavTabType currentTab;
  final ValueChanged<NavTabType> onTabChanged;

  const WasherBottomNavigationBar({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: NavTabType.values.map((tab) {
              return _NavTabItem(
                tab: tab,
                isSelected: currentTab == tab,
                onTap: () => onTabChanged(tab),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// 개별 탭 아이템 위젯
class _NavTabItem extends StatelessWidget {
  final NavTabType tab;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTabItem({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? WasherColor.baseGray400
        : WasherColor.baseGray200;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WasherIcon(
            type: tab.iconType,
            color: color,
          ),
          SizedBox(height: AppSpacing.v2),
          Text(
            tab.label,
            style: WasherTypography.body2(color),
          ),
        ],
      ),
    );
  }
}
