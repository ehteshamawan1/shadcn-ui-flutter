import 'package:flutter/material.dart';

/// Border radius system matching Tailwind CSS rounded utilities
class AppRadius {
  static const double none = 0;
  static const double sm = 4.0; // rounded-sm
  static const double md = 6.0; // rounded-md
  static const double base = 8.0; // rounded (0.5rem)
  static const double lg = 12.0; // rounded-lg
  static const double xl = 16.0; // rounded-xl
  static const double xl2 = 20.0; // rounded-2xl
  static const double full = 9999.0; // rounded-full

  // BorderRadius presets
  static const BorderRadius radiusNone = BorderRadius.zero;
  static BorderRadius radiusSm = BorderRadius.circular(sm);
  static BorderRadius radiusMd = BorderRadius.circular(md);
  static BorderRadius radiusBase = BorderRadius.circular(base);
  static BorderRadius radiusLg = BorderRadius.circular(lg);
  static BorderRadius radiusXl = BorderRadius.circular(xl);
  static BorderRadius radiusXl2 = BorderRadius.circular(xl2);
  static BorderRadius radiusFull = BorderRadius.circular(full);

  // Individual corner radius
  static BorderRadius only({
    double topLeft = 0,
    double topRight = 0,
    double bottomLeft = 0,
    double bottomRight = 0,
  }) {
    return BorderRadius.only(
      topLeft: Radius.circular(topLeft),
      topRight: Radius.circular(topRight),
      bottomLeft: Radius.circular(bottomLeft),
      bottomRight: Radius.circular(bottomRight),
    );
  }

  // Top rounded (rounded-t-*)
  static BorderRadius top(double value) => only(
        topLeft: value,
        topRight: value,
      );

  // Bottom rounded (rounded-b-*)
  static BorderRadius bottom(double value) => only(
        bottomLeft: value,
        bottomRight: value,
      );

  // Left rounded (rounded-l-*)
  static BorderRadius left(double value) => only(
        topLeft: value,
        bottomLeft: value,
      );

  // Right rounded (rounded-r-*)
  static BorderRadius right(double value) => only(
        topRight: value,
        bottomRight: value,
      );

  /// Create custom BorderRadius from value
  static BorderRadius circular(double value) => BorderRadius.circular(value);
}
