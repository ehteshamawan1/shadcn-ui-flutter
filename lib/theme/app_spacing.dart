import 'package:flutter/material.dart';

/// Spacing system matching Tailwind CSS spacing scale
/// 1 unit = 4px (0.25rem)
class AppSpacing {
  static const double s0 = 0;
  static const double s1 = 4.0; // 0.25rem
  static const double s2 = 8.0; // 0.5rem
  static const double s3 = 12.0; // 0.75rem
  static const double s4 = 16.0; // 1rem
  static const double s5 = 20.0; // 1.25rem
  static const double s6 = 24.0; // 1.5rem
  static const double s8 = 32.0; // 2rem
  static const double s10 = 40.0; // 2.5rem
  static const double s12 = 48.0; // 3rem
  static const double s16 = 64.0; // 4rem
  static const double s20 = 80.0; // 5rem
  static const double s24 = 96.0; // 6rem

  // Common padding presets
  static const EdgeInsets p0 = EdgeInsets.zero;
  static const EdgeInsets p1 = EdgeInsets.all(s1);
  static const EdgeInsets p2 = EdgeInsets.all(s2);
  static const EdgeInsets p3 = EdgeInsets.all(s3);
  static const EdgeInsets p4 = EdgeInsets.all(s4);
  static const EdgeInsets p5 = EdgeInsets.all(s5);
  static const EdgeInsets p6 = EdgeInsets.all(s6);
  static const EdgeInsets p8 = EdgeInsets.all(s8);

  // Horizontal padding presets (px-*)
  static const EdgeInsets px1 = EdgeInsets.symmetric(horizontal: s1);
  static const EdgeInsets px2 = EdgeInsets.symmetric(horizontal: s2);
  static const EdgeInsets px3 = EdgeInsets.symmetric(horizontal: s3);
  static const EdgeInsets px4 = EdgeInsets.symmetric(horizontal: s4);
  static const EdgeInsets px6 = EdgeInsets.symmetric(horizontal: s6);
  static const EdgeInsets px8 = EdgeInsets.symmetric(horizontal: s8);

  // Vertical padding presets (py-*)
  static const EdgeInsets py1 = EdgeInsets.symmetric(vertical: s1);
  static const EdgeInsets py2 = EdgeInsets.symmetric(vertical: s2);
  static const EdgeInsets py3 = EdgeInsets.symmetric(vertical: s3);
  static const EdgeInsets py4 = EdgeInsets.symmetric(vertical: s4);
  static const EdgeInsets py6 = EdgeInsets.symmetric(vertical: s6);
  static const EdgeInsets py8 = EdgeInsets.symmetric(vertical: s8);

  // Gap/spacing for flex layouts (space-y-*, space-x-*)
  static const double gapXs = s1;
  static const double gapSm = s2;
  static const double gapMd = s4;
  static const double gapLg = s6;
  static const double gapXl = s8;

  /// Create custom EdgeInsets with individual sides
  static EdgeInsets only({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return EdgeInsets.only(
      left: left ?? 0,
      top: top ?? 0,
      right: right ?? 0,
      bottom: bottom ?? 0,
    );
  }

  /// Create custom symmetric EdgeInsets
  static EdgeInsets symmetric({
    double? horizontal,
    double? vertical,
  }) {
    return EdgeInsets.symmetric(
      horizontal: horizontal ?? 0,
      vertical: vertical ?? 0,
    );
  }

  /// Create uniform padding
  static EdgeInsets all(double value) => EdgeInsets.all(value);
}
