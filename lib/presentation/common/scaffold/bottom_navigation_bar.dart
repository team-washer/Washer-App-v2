import 'package:flutter/material.dart';
import 'package:project_setting/core/theme/color.dart';
import 'package:project_setting/core/theme/icon.dart';

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
    return BottomNavigationBar(
      currentIndex: NavTabType.values.indexOf(currentTab),
      onTap: (index) => onTabChanged(NavTabType.values[index]),
      backgroundColor: Colors.white,
      selectedItemColor: WasherColor.baseGray400,
      unselectedItemColor: WasherColor.baseGray200,
      type: BottomNavigationBarType.fixed,
      items: NavTabType.values.map((tab) {
        return BottomNavigationBarItem(
          icon: WasherIcon(
            type: tab.iconType,
            color: currentTab == tab
                ? WasherColor.baseGray400
                : WasherColor.baseGray200,
          ),
          label: tab.label,
        );
      }).toList(),
    );
  }
}
