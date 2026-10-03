import 'package:flutter/material.dart';
import 'package:washer/shared/theme/washer_color.dart';

/// 앱 전역 [ThemeData] (배경색, 앱바, 로딩 인디케이터 색).
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
