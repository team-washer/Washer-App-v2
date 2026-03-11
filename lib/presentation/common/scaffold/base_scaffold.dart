import 'package:flutter/material.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/presentation/common/scaffold/washer_appbar.dart';

class BaseScaffold extends StatelessWidget {
  final Widget body;
  final bool showAppBar;
  final bool hasNotification;
  final Widget? bottomNavigationBar;

  const BaseScaffold({
    super.key,
    required this.body,
    this.showAppBar = false,
    this.hasNotification = false,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WasherColor.backgroundColor,
      appBar: showAppBar
          ? WasherAppbar(hasNotification: hasNotification)
          : null,
      body: SafeArea(
        child: Padding(
          padding: AppPadding.screenHPadding,
          child: body,
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
