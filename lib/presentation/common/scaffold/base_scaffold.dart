import 'package:flutter/material.dart';
import 'package:project_setting/core/theme/color.dart';
import 'package:project_setting/presentation/common/scaffold/washer_appbar.dart';

class BaseScaffold extends StatelessWidget {
  final Widget body;
  final bool showAppBar;
  final bool hasNotification;
  final Widget? bottomNavigationBar;

  const BaseScaffold({
    super.key,
    required this.body,
    this.showAppBar = true,
    this.hasNotification = false,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: WasherColor.backgroundColor,
        appBar: showAppBar
            ? WasherAppbar(hasNotification: hasNotification)
            : null,
        body: _buildBody(),
        bottomNavigationBar: bottomNavigationBar,
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
