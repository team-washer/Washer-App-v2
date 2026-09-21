import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:washer/features/alarm/presentation/providers/alarm_provider.dart';

import 'package:washer/shared/ui/layout/base_scaffold.dart';
import 'package:washer/shared/ui/layout/nav_tab_type.dart';
import 'package:washer/shared/ui/layout/washer_bottom_navigation_bar.dart';

/// 로그인 이후 메인 화면의 공통 틀. 앱바와 하단 탭 바를 두고,
/// 각 탭 화면은 [navigationShell]이 본문으로 렌더링한다.
class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = NavTabType.values[navigationShell.currentIndex];
    final hasNotification = ref.watch(
      alarmProvider.select((state) => state.alarms.isNotEmpty),
    );

    return BaseScaffold(
      showAppBar: true,
      hasNotification: hasNotification,
      body: navigationShell,
      bottomNavigationBar: WasherBottomNavigationBar(
        currentTab: currentTab,
        onTabChanged: (tab) {
          // 현재 탭을 다시 누르면 해당 브랜치의 초기 위치로 되돌린다.
          navigationShell.goBranch(
            tab.index,
            initialLocation: tab.index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
