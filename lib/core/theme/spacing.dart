import 'package:flutter/material.dart';

/// 앱 전체에서 사용되는 간격 및 여백 상수
///
/// 사용 예시:
/// ```dart
/// SizedBox(height: AppSpacing.v16)
/// Container(padding: AppPadding.card)
/// BorderRadius.circular(AppSpacing.cardRadius)
/// ```
class AppSpacing {
  AppSpacing._();

  // ============================================
  // Padding Units - 컴포넌트별 패딩
  // ============================================

  /// 카드 컴포넌트 기본 패딩
  static const double cardPadding = 16;

  /// 콘텐츠 영역 기본 패딩
  static const double contentPadding = 12;

  // ============================================
  // Border Radius - 모서리 둥글기
  // ============================================

  /// 카드 컴포넌트 기본 radius
  static const double cardRadius = 12;

  // ============================================
  // Vertical Gap - 세로 간격
  // ============================================

  /// 매우 작은 세로 간격 (2px)
  static const double v2 = 2;

  /// 작은 세로 간격 (4px)
  static const double v4 = 4;

  /// 기본 세로 간격 (8px)
  static const double v8 = 8;

  /// 중간 세로 간격 (10px)
  static const double v10 = 10;

  /// 중간 세로 간격 (12px)
  static const double v12 = 12;

  /// 큰 세로 간격 (16px)
  static const double v16 = 16;

  /// 매우 큰 세로 간격 (24px)
  static const double v24 = 24;

  // ============================================
  // Horizontal Gap - 가로 간격
  // ============================================

  /// 매우 작은 가로 간격 (2px)
  static const double h2 = 2;

  /// 작은 가로 간격 (4px)
  static const double h4 = 4;

  /// 기본 가로 간격 (8px)
  static const double h8 = 8;

  /// 기본 가로 간격 (10px)
  static const double h10 = 8;

  /// 중간 가로 간격 (12px)
  static const double h12 = 12;

  /// 큰 가로 간격 (16px)
  static const double h16 = 16;

  /// 매우 큰 가로 간격 (24px)
  static const double h24 = 24;
}

class AppPadding {
  AppPadding._();

  // ============================================
  // All - 모든 방향 동일한 패딩
  // ============================================

  /// 카드 컴포넌트용 패딩 (16px all)
  static const EdgeInsets card = EdgeInsets.all(AppSpacing.cardPadding);

  /// 콘텐츠 영역용 패딩 (12px all)
  static const EdgeInsets content = EdgeInsets.all(AppSpacing.contentPadding);

  static const EdgeInsets button = EdgeInsets.symmetric(
    vertical: 8,
    horizontal: 33.5,
  );
  static const EdgeInsets appBarPadding = EdgeInsets.symmetric(
    vertical: 12,
    horizontal: 32,
  );

  static const EdgeInsets screenHPadding = EdgeInsets.symmetric(horizontal: 32);
}

class AppGap {
  AppGap._();

  // ============================================
  // Vertical Gaps - 세로 간격
  // ============================================

  static const Widget v2 = SizedBox(height: AppSpacing.v2);
  static const Widget v4 = SizedBox(height: AppSpacing.v4);
  static const Widget v8 = SizedBox(height: AppSpacing.v8);
  static const Widget v10 = SizedBox(height: AppSpacing.v10);
  static const Widget v12 = SizedBox(height: AppSpacing.v12);
  static const Widget v16 = SizedBox(height: AppSpacing.v16);
  static const Widget v24 = SizedBox(height: AppSpacing.v24);

  // ============================================
  // Horizontal Gaps - 가로 간격
  // ============================================

  static const Widget h2 = SizedBox(width: AppSpacing.h2);
  static const Widget h4 = SizedBox(width: AppSpacing.h4);
  static const Widget h8 = SizedBox(width: AppSpacing.h8);
  static const Widget h10 = SizedBox(width: AppSpacing.h10);
  static const Widget h12 = SizedBox(width: AppSpacing.h12);
  static const Widget h16 = SizedBox(width: AppSpacing.h16);
  static const Widget h24 = SizedBox(width: AppSpacing.h24);
}

class AppRadius {
  AppRadius._();

  /// 카드 모서리 둥글기
  static final BorderRadius card = BorderRadius.circular(AppSpacing.cardRadius);

  /// 작은 모서리 둥글기 (8px)
  static final BorderRadius small = BorderRadius.circular(8);

  /// 중간 모서리 둥글기 (12px)
  static final BorderRadius medium = BorderRadius.circular(12);

  /// 큰 모서리 둥글기 (16px)
  static final BorderRadius large = BorderRadius.circular(16);

  /// 완전히 둥근 모서리
  static final BorderRadius circular = BorderRadius.circular(999);
}
