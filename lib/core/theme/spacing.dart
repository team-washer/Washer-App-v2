import 'package:flutter/material.dart';

class AppSpacing {
  // padding (unit)
  static const double cardPadding = 16;
  static const double contentPadding = 12;

  // radius
  static const double cardRadius = 12;

  // gap - vertical
  static const double v2 = 2;
  static const double v4 = 4;
  static const double v8 = 8;
  static const double v12 = 12;
  static const double v16 = 16;
  static const double v24 = 24;

  // gap - horizontal
  static const double h2 = 2;
  static const double h4 = 4;
  static const double h8 = 8;
  static const double h12 = 12;
  static const double h16 = 16;
  static const double h24 = 24;
}

class AppPadding {
  static const EdgeInsets card = EdgeInsets.all(AppSpacing.cardPadding);
  static const EdgeInsets content = EdgeInsets.all(AppSpacing.contentPadding);

}
