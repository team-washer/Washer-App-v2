import 'package:flutter/material.dart';
import 'package:washer/core/theme/color.dart';

class WasherTheme {
  WasherTheme._();

  static ThemeData themeData = ThemeData(
    scaffoldBackgroundColor: WasherColor.backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: WasherColor.backgroundColor,
      foregroundColor: WasherColor.baseGray,
      elevation: 0,
      centerTitle: true,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: WasherColor.mainColor500,
    ),
  );
}
