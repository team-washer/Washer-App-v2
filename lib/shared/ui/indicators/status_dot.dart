import 'package:flutter/material.dart';
import 'package:washer/shared/theme/washer_color.dart';

/// [StatusDot]에서 쓸 수 있는 색상 종류.
enum StatusDotColor { red, blue }

/// [StatusDotColor]를 실제 [Color]로 변환한다.
extension StatusDotColorX on StatusDotColor {
  Color get toColor {
    switch (this) {
      case StatusDotColor.red:
        return WasherColor.errorColor;
      case StatusDotColor.blue:
        return WasherColor.mainColor500;
    }
  }
}

/// 알림 유무·필수 표시 등에 쓰는 4px 원형 점.
class StatusDot extends StatelessWidget {
  final StatusDotColor color;
  static const double _size = 4;

  const StatusDot({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(color: color.toColor, shape: BoxShape.circle),
    );
  }
}
