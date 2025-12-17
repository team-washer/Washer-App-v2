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
  dryCircle,
  waterCircle,
  warningCircle,
  historyCircle,
}

extension WasherIconTypeExtension on WasherIconType {
  String get assetName {
    const assetMap = {
      WasherIconType.back: 'back.svg',
      WasherIconType.cancel: 'cancel.svg',
      WasherIconType.down: 'down.svg',
      WasherIconType.dry: 'dry.svg',
      WasherIconType.eye: 'eye.svg',
      WasherIconType.eyeOff: 'eye_off.svg',
      WasherIconType.history: 'history.svg',
      WasherIconType.home: 'home.svg',
      WasherIconType.logo: 'logo.svg',
      WasherIconType.logoWithTitle: 'logo_with_title.svg',
      WasherIconType.map: 'map.svg',
      WasherIconType.triangleWarning: 'triangle_warning.svg',
      WasherIconType.user: 'user.svg',
      WasherIconType.water: 'water.svg',
      WasherIconType.dryCircle: 'dry_circle.svg',
      WasherIconType.waterCircle: 'water_circle.svg',
      WasherIconType.warningCircle: 'warning_circle.svg',
      WasherIconType.historyCircle: 'history_circle.svg',
    };
    return assetMap[this] ?? 'default_icon.svg';
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
