import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum WasherIconType {
  back,
  home,
  map,
  history,
  cancel,
  down,
  notification,
  eye,
  eyeOff,
  dry,
  water,
  user,
  logo,
  logoWithTitle,
  triangleWarning,
  warningCircle,
  dryCircle,
  waterCircle,
  historyCircle,
  dgWhite,
}

/// [WasherIconType]을 SVG 파일명으로 변환하는 확장
extension WasherIconTypeExtension on WasherIconType {
  /// SVG 파일명 반환
  String get assetName {
    const assetMap = {
      WasherIconType.back: 'back.svg',
      WasherIconType.home: 'home.svg',
      WasherIconType.map: 'map.svg',
      WasherIconType.history: 'history.svg',
      WasherIconType.cancel: 'cancel.svg',
      WasherIconType.down: 'down.svg',
      WasherIconType.notification: 'notification.svg',
      WasherIconType.eye: 'eye.svg',
      WasherIconType.eyeOff: 'eye_off.svg',
      WasherIconType.dry: 'dry.svg',
      WasherIconType.water: 'water.svg',
      WasherIconType.user: 'user.svg',
      WasherIconType.logo: 'logo.svg',
      WasherIconType.logoWithTitle: 'logo_with_title.svg',
      WasherIconType.triangleWarning: 'triangle_warning.svg',
      WasherIconType.warningCircle: 'warning_circle.svg',
      WasherIconType.dryCircle: 'dry_circle.svg',
      WasherIconType.waterCircle: 'water_circle.svg',
      WasherIconType.historyCircle: 'history_circle.svg',
      WasherIconType.dgWhite: 'DG_white.svg',
    };
    return assetMap[this] ?? 'default_icon.svg';
  }

  /// assets 폴더의 전체 경로 반환
  String get assetPath => 'assets/icons/$assetName';
}

class WasherIcon extends StatelessWidget {
  /// 아이콘 타입
  final WasherIconType type;

  /// 아이콘 크기 (기본값: 24.0)
  final double size;

  /// 아이콘 색상 (null일 경우 원본 색상 사용)
  final Color? color;

  const WasherIcon({
    super.key,
    required this.type,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = SvgPicture.asset(
      type.assetPath,
      width: size.w,
      height: size.h,
      colorFilter: _buildColorFilter(),
    );
    return iconWidget;
  }

  /// 색상 필터 생성
  /// color가 null이면 null 반환 (원본 색상 사용)
  ColorFilter? _buildColorFilter() {
    return color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null;
  }
}

/// 터치 가능한 아이콘 버튼 위젯
class WasherIconButton extends StatelessWidget {
  final WasherIconType type;
  final double size;
  final Color? color;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const WasherIconButton({
    super.key,
    required this.type,
    this.size = 24.0,
    this.color,
    this.onTap,
    this.padding = const EdgeInsets.all(8.0),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size.w / 2 + 8.r),
        child: Padding(
          padding: padding,
          child: WasherIcon(
            type: type,
            size: size,
            color: color,
          ),
        ),
      ),
    );
  }
}
