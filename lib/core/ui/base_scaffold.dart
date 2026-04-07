import 'package:flutter/material.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/ui/washer_appbar.dart';

class BaseScaffold extends StatelessWidget {
  final Widget body;
  final bool showAppBar;
  final bool hasNotification;
  final Widget? bottomNavigationBar;
  final bool useSafeArea;

  const BaseScaffold({
    super.key,
    required this.body,
    this.showAppBar = false,
    this.hasNotification = false,
    this.bottomNavigationBar,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: AppPadding.screenHPadding.copyWith(
        top: showAppBar ? AppSpacing.v12 : 0,
      ),
      child: body,
    );

    return Scaffold(
      backgroundColor: WasherColor.backgroundColor,
      appBar: showAppBar
          ? WasherAppbar(hasNotification: hasNotification)
          : null,
      body: useSafeArea
          ? SafeArea(
              bottom: false,
              child: content,
            )
          : content,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
