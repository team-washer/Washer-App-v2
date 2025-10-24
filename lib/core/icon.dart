import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum WasherIconType {
  back,
  cancel,
  down,
  dry,
  eye,
  eyeOff,
  history,
  home,
  logo,
  logoWithTitle,
  map,
  triangleWarning,
  user,
  water,
}

extension WasherIconTypeExtension on WasherIconType {
  String get assetName {
    switch (this) {
      case WasherIconType.back:
        return 'back.svg';
      case WasherIconType.cancel:
        return 'cancel.svg';
      case WasherIconType.down:
        return 'down.svg';
      case WasherIconType.dry:
        return 'dry.svg';
      case WasherIconType.eye:
        return 'eye.svg';
      case WasherIconType.eyeOff:
        return 'eye_off.svg';
      case WasherIconType.history:
        return 'history.svg';
      case WasherIconType.home:
        return 'home.svg';
      case WasherIconType.logo:
        return 'logo.svg';
      case WasherIconType.logoWithTitle:
        return 'logo_with_title.svg';
      case WasherIconType.map:
        return 'map.svg';
      case WasherIconType.triangleWarning:
        return 'triangle_warning.svg';
      case WasherIconType.user:
        return 'user.svg';
      case WasherIconType.water:
        return 'water.svg';
    }
  }
}

/// 디자인 시스템 공용 아이콘 위젯
class WasherIcon extends StatelessWidget {
  final WasherIconType type;
  final double size;
  final Color? color;
  final VoidCallback? onTap;

  const WasherIcon({
    super.key,
    required this.type,
    this.size = 24.0,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = SvgPicture.asset(
      'assets/icons/${type.assetName}',
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );

    return onTap != null
        ? GestureDetector(onTap: onTap, child: iconWidget)
        : iconWidget;
  }
}