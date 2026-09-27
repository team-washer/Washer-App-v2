import 'package:flutter/material.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/ui/app_bar/washer_app_bar.dart';

/// 앱 공통 Scaffold. 배경색, 좌우 여백, SafeArea, (선택) 앱바를 일관되게 적용한다.
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
          ? WasherAppBar(hasNotification: hasNotification)
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
