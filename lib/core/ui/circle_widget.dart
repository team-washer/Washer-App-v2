import 'package:flutter/material.dart';
import 'package:washer/core/theme/color.dart';

enum CircleColor { red, blue }

extension CircleColorX on CircleColor {
  Color get toColor {
    switch (this) {
      case CircleColor.red:
        return WasherColor.errorColor;
      case CircleColor.blue:
        return WasherColor.mainColor600;
    }
  }
}

class CircleWidget extends StatelessWidget {
  final CircleColor color;
  static const double _size = 4;

  const CircleWidget({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: color.toColor,
        shape: BoxShape.circle
      ),
    );
  }
}
