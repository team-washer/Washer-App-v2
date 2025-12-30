import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:project_setting/core/enums/laundry_machine_type.dart';
import 'package:project_setting/presentation/common/scaffold/base_scaffold.dart';
import 'package:project_setting/presentation/common/scaffold/bottom_navigation_bar.dart';
import 'package:project_setting/presentation/home/screen/home_screen.dart';
import 'package:project_setting/presentation/reservation/screens/reservation_screen.dart';

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
        ReservationScreen(
          laundryMachineType: LaundryMachineType.dryer,
        ),
        HomeScreen(),
        ReservationScreen(
          laundryMachineType: LaundryMachineType.washer,
        ),
      ],
    );
  }
}
