import 'package:flutter/material.dart';
import 'package:project_setting/core/theme/color.dart';
import 'package:project_setting/presentation/common/scaffold/bottom_navigation_bar.dart';
import 'package:project_setting/presentation/common/scaffold/washer_appbar.dart';

class BaseScaffold extends StatelessWidget {
  final Widget body;
  final bool showAppBar;
  final bool showBottomNav;
  final bool hasNotification;
  final NavTabType? currentTab;
  final ValueChanged<NavTabType>? onTabChanged;

  const BaseScaffold({
    super.key,
    required this.body,
    this.showAppBar = true,
    this.showBottomNav = true,
    this.hasNotification = false,
    this.currentTab,
    this.onTabChanged,
  }) : assert(
         !showBottomNav || (currentTab != null && onTabChanged != null),
         'showBottomNav이 true일 때 currentTab과 onTabChanged는 필수입니다.',
       );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: WasherColor.backgroundColor,
        appBar: showAppBar
            ? WasherAppbar(hasNotification: hasNotification)
            : null,
        body: _buildBody(),
        bottomNavigationBar: showBottomNav
            ? WasherBottomNavigationBar(
                currentTab: currentTab!,
                onTabChanged: onTabChanged!,
              )
            : null,
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: body,
    );
  }
}
