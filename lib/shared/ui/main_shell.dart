import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:washer/features/alarm/presentation/providers/alarm_provider.dart';

import 'base_scaffold.dart';
import 'bottom_navigation_bar.dart';

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = NavTabType.values[navigationShell.currentIndex];
    final hasNotification =
        ref.watch(
          alarmProvider.select((state) => state.alarms.isNotEmpty),
        );

    return BaseScaffold(
      showAppBar: true,
      hasNotification: hasNotification,
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
