import 'package:flutter/material.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 앱 전역 텍스트 스타일 (SUIT 폰트, screenutil `.sp` 적용).
/// 색상을 생략하면 기본 회색(baseGray700)을 사용한다.
class WasherTypography {
  WasherTypography._();

  static const String _fontFamily = 'SUIT';
  static const Color _defaultColor = WasherColor.baseGray700;

  static TextStyle _suitBase({
    required double fontSize,
    required FontWeight fontWeight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontWeight: fontWeight,
      fontSize: fontSize.sp,
      color: color ?? _defaultColor,
    );
  }

  // Headline Styles
  static TextStyle h1([Color? color]) => _suitBase(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: color,
  );
  static TextStyle h2([Color? color]) => _suitBase(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: color,
  );

  // Subtitle Styles
  static TextStyle subTitle1([Color? color]) => _suitBase(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: color,
  );
  static TextStyle subTitle2([Color? color]) => _suitBase(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: color,
  );
  static TextStyle subTitle3([Color? color]) => _suitBase(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: color,
  );
  static TextStyle subTitle4([Color? color]) => _suitBase(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: color,
  );

  // Body Styles
  static TextStyle body1([Color? color]) => _suitBase(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: color,
  );
  static TextStyle body2([Color? color]) => _suitBase(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: color,
  );
  static TextStyle body3([Color? color]) => _suitBase(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: color,
  );
  static TextStyle body4([Color? color]) => _suitBase(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: color,
  );

  // Caption Style
  static TextStyle caption([Color? color]) => _suitBase(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: color,
  );
}
