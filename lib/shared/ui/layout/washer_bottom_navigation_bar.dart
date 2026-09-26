import 'package:flutter/material.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_icon.dart';
import 'package:washer/shared/theme/washer_typography.dart';
import 'package:washer/shared/ui/layout/nav_tab_type.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 건조기/홈/세탁기 3개 탭을 보여주는 하단 네비게이션 바.
/// 탭 선택 상태는 호출부([currentTab])가 관리하고 변경은 [onTabChanged]로 전달한다.
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
    return Theme(
      data: Theme.of(context).copyWith(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: BottomNavigationBar(
        selectedLabelStyle: WasherTypography.body2(),
        unselectedLabelStyle: WasherTypography.body2(),
        currentIndex: NavTabType.values.indexOf(currentTab),
        onTap: (index) => onTabChanged(NavTabType.values[index]),
        backgroundColor: Colors.white,
        selectedItemColor: WasherColor.baseGray500,
        unselectedItemColor: WasherColor.baseGray300,
        type: BottomNavigationBarType.fixed,
        items: NavTabType.values.map((tab) {
          return BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: WasherIcon(
                type: tab.iconType,
                color: currentTab == tab
                    ? WasherColor.baseGray500
                    : WasherColor.baseGray300,
              ),
            ),
            label: tab.label,
          );
        }).toList(),
      ),
    );
  }
}
