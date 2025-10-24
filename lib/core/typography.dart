import 'package:flutter/material.dart';
import 'package:project_setting/core/color.dart';

class WasherTypography {
  WasherTypography._();

  static TextStyle _suitBase({
    required double fontSize,
    required FontWeight fontWeight,
    double height = 1,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: 'SUIT',
      fontWeight: fontWeight,
      fontSize: fontSize,
      height: height,
      color: color,
    );
  }

  // ---- headline ----
  static TextStyle h1([Color? color]) => _suitBase(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: color ?? WasherColor.baseGray,
  );

  static TextStyle h2([Color? color]) => _suitBase(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: color ?? WasherColor.baseGray,
  );

  static TextStyle h3([Color? color]) => _suitBase(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: color ?? WasherColor.baseGray,
  );

  static TextStyle h4([Color? color]) => _suitBase(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: color ?? WasherColor.baseGray,
  );

  // ---- subTitle ----
  static TextStyle subTitle1([Color? color]) => _suitBase(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: color ?? WasherColor.baseGray,
  );

  static TextStyle subTitle2([Color? color]) => _suitBase(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: color ?? WasherColor.baseGray,
  );

  static TextStyle subTitle3([Color? color]) => _suitBase(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    color: color ?? WasherColor.baseGray,
  );

  // ---- body ----
  static TextStyle body1([Color? color]) => _suitBase(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: color ?? WasherColor.baseGray,
  );

  static TextStyle body2([Color? color]) => _suitBase(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: color ?? WasherColor.baseGray,
  );

  // ---- smallTitle ----
  static TextStyle smallTile([Color? color]) => _suitBase(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: color ?? WasherColor.baseGray,
  );

  // ---- caption ----
  static TextStyle caption([Color? color]) => _suitBase(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: color ?? WasherColor.baseGray,
  );
}
