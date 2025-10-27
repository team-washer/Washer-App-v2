import 'package:flutter/material.dart';
import 'package:project_setting/core/theme/color.dart';

class WasherTheme {
  static ThemeData themeData = ThemeData(
    scaffoldBackgroundColor: WasherColor.backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: WasherColor.backgroundColor,
      foregroundColor: WasherColor.baseGray,
      elevation: 0,
      centerTitle: true,
    ),
  );
}
