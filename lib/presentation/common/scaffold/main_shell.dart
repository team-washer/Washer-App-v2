import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'base_scaffold.dart';
import 'bottom_navigation_bar.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final currentTab = NavTabType.values[navigationShell.currentIndex];

    return BaseScaffold(
      showAppBar: true,
      body: navigationShell,
      bottomNavigationBar: WasherBottomNavigationBar(
        currentTab: currentTab,
        onTabChanged: (tab) {
          navigationShell.goBranch(
            tab.index,
            initialLocation: tab.index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
