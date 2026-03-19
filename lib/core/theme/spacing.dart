import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
  static double get cardPadding => 16.w;

  /// 콘텐츠 영역 기본 패딩
  static double get contentPadding => 12.w;

  // ============================================
  // Border Radius - 모서리 둥글기
  // ============================================

  /// 카드 컴포넌트 기본 radius
  static double get cardRadius => 12.r;

  // ============================================
  // Vertical Gap - 세로 간격
  // ============================================

  /// 매우 작은 세로 간격 (2px)
  static double get v2 => 2.h;

  /// 작은 세로 간격 (4px)
  static double get v4 => 4.h;

  /// 기본 세로 간격 (8px)
  static double get v8 => 8.h;

  /// 중간 세로 간격 (10px)
  static double get v10 => 10.h;

  /// 중간 세로 간격 (12px)
  static double get v12 => 12.h;

  /// 큰 세로 간격 (16px)
  static double get v16 => 16.h;

  /// 매우 큰 세로 간격 (24px)
  static double get v24 => 24.h;

  // ============================================
  // Horizontal Gap - 가로 간격
  // ============================================

  /// 매우 작은 가로 간격 (2px)
  static double get h2 => 2.w;

  /// 작은 가로 간격 (4px)
  static double get h4 => 4.w;

  /// 기본 가로 간격 (8px)
  static double get h8 => 8.w;

  /// 기본 가로 간격 (10px)
  static double get h10 => 10.w;

  /// 중간 가로 간격 (12px)
  static double get h12 => 12.w;

  /// 큰 가로 간격 (16px)
  static double get h16 => 16.w;

  /// 매우 큰 가로 간격 (24px)
  static double get h24 => 24.w;
}

class AppPadding {
  AppPadding._();

  // ============================================
  // All - 모든 방향 동일한 패딩
  // ============================================

  /// 카드 컴포넌트용 패딩 (16px all)
  static EdgeInsets get card => EdgeInsets.all(AppSpacing.cardPadding);

  /// 콘텐츠 영역용 패딩 (12px all)
  static EdgeInsets get content => EdgeInsets.all(AppSpacing.contentPadding);

  static EdgeInsets get button => EdgeInsets.symmetric(
    vertical: 8.h,
    horizontal: 33.5.w,
  );
  static EdgeInsets get appBarPadding => EdgeInsets.symmetric(
    vertical: 12.h,
    horizontal: 32.w,
  );

  static EdgeInsets get screenHPadding => EdgeInsets.symmetric(horizontal: 32.w);
}

class AppGap {
  AppGap._();

  // ============================================
  // Vertical Gaps - 세로 간격
  // ============================================

  static Widget get v2 => SizedBox(height: AppSpacing.v2);
  static Widget get v4 => SizedBox(height: AppSpacing.v4);
  static Widget get v8 => SizedBox(height: AppSpacing.v8);
  static Widget get v10 => SizedBox(height: AppSpacing.v10);
  static Widget get v12 => SizedBox(height: AppSpacing.v12);
  static Widget get v16 => SizedBox(height: AppSpacing.v16);
  static Widget get v24 => SizedBox(height: AppSpacing.v24);

  // ============================================
  // Horizontal Gaps - 가로 간격
  // ============================================

  static Widget get h2 => SizedBox(width: AppSpacing.h2);
  static Widget get h4 => SizedBox(width: AppSpacing.h4);
  static Widget get h8 => SizedBox(width: AppSpacing.h8);
  static Widget get h10 => SizedBox(width: AppSpacing.h10);
  static Widget get h12 => SizedBox(width: AppSpacing.h12);
  static Widget get h16 => SizedBox(width: AppSpacing.h16);
  static Widget get h24 => SizedBox(width: AppSpacing.h24);
}

class AppRadius {
  AppRadius._();

  /// 카드 모서리 둥글기
  static BorderRadius get card => BorderRadius.circular(AppSpacing.cardRadius);

  /// 작은 모서리 둥글기 (8px)
  static BorderRadius get small => BorderRadius.circular(8.r);

  /// 중간 모서리 둥글기 (12px)
  static BorderRadius get medium => BorderRadius.circular(12.r);

  /// 큰 모서리 둥글기 (16px)
  static BorderRadius get large => BorderRadius.circular(16.r);

  /// 완전히 둥근 모서리
  static BorderRadius get circular => BorderRadius.circular(999.r);
}
