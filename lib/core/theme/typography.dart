import 'package:flutter/material.dart';
import 'package:washer/core/theme/color.dart';

class WasherTypography {
  WasherTypography._();

  // ============================================
  // Font Configuration - 폰트 설정
  // ============================================

  /// 앱 기본 폰트 패밀리
  static const String _fontFamily = 'SUIT';

  /// 기본 텍스트 색상
  static const Color _defaultColor = WasherColor.baseGray700;

  // ============================================
  // Private Helper - 내부 헬퍼 메서드
  // ============================================

  /// SUIT 폰트 기반 TextStyle 생성
  static TextStyle _suitBase({
    required double fontSize,
    required FontWeight fontWeight,
    double height = 1,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontWeight: fontWeight,
      fontSize: fontSize,
      height: height,
      color: color,
    );
  }

  // ============================================
  // Headline Styles - 헤드라인 스타일
  // ============================================

  static TextStyle h1([Color? color]) => _suitBase(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: color ?? _defaultColor,
  );

  static TextStyle h2([Color? color]) => _suitBase(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: color ?? _defaultColor,
  );

  // ============================================
  // Subtitle Styles - 서브타이틀 스타일
  // ============================================

  static TextStyle subTitle1([Color? color]) => _suitBase(
    fontSize: 20,
    fontWeight: FontWeight.normal,
    color: color ?? _defaultColor,
  );

  static TextStyle subTitle2([Color? color]) => _suitBase(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: color ?? _defaultColor,
  );

  static TextStyle subTitle3([Color? color]) => _suitBase(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    color: color ?? _defaultColor,
  );

  static TextStyle subTitle4([Color? color]) => _suitBase(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: color ?? _defaultColor,
  );

  // ============================================
  // Body Styles - 본문 스타일
  // ============================================

  static TextStyle body1([Color? color]) => _suitBase(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: color ?? _defaultColor,
  );

  static TextStyle body2([Color? color]) => _suitBase(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: color ?? _defaultColor,
  );

  static TextStyle body3([Color? color]) => _suitBase(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: color ?? _defaultColor,
  );

  static TextStyle body4([Color? color]) => _suitBase(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: color ?? _defaultColor,
  );

  // ============================================
  // Caption Style - 캡션 스타일
  // ============================================

  static TextStyle caption([Color? color]) => _suitBase(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: color ?? _defaultColor,
  );
}