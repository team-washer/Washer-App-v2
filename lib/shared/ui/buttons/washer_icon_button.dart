import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:washer/shared/theme/washer_icon.dart';

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
