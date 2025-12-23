import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:project_setting/presentation/common/scaffold/base_scaffold.dart';
import 'package:project_setting/presentation/common/scaffold/bottom_navigation_bar.dart';

final currentTabProvider = StateProvider<NavTabType>((ref) => NavTabType.home);

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);

    return BaseScaffold(
      showAppBar: true,
      body: _buildBody(currentTab),
      bottomNavigationBar: WasherBottomNavigationBar(
        currentTab: currentTab,
        onTabChanged: (tab) =>
            ref.read(currentTabProvider.notifier).state = tab,
      ),
    );
  }

  Widget _buildBody(NavTabType currentTab) {
    return IndexedStack(
      index: NavTabType.values.indexOf(currentTab),
      children: const [
        // TODO: DryerScreen으로 교체
        Placeholder(),
        // TODO: HomeScreen으로 교체
        Placeholder(),
        // TODO: WasherScreen으로 교체
        Placeholder(),
      ],
    );
  }
}
