import 'package:flutter/material.dart';

/// Typography system matching Tailwind CSS text utilities
class AppTypography {
  // Font sizes (matching Tailwind)
  static const double textXs = 12.0; // text-xs
  static const double textSm = 14.0; // text-sm
  static const double textBase = 16.0; // text-base
  static const double textLg = 18.0; // text-lg
  static const double textXl = 20.0; // text-xl
  static const double text2xl = 24.0; // text-2xl
  static const double text3xl = 30.0; // text-3xl

  // Font weights
  static const FontWeight fontNormal = FontWeight.w400;
  static const FontWeight fontMedium = FontWeight.w500;
  static const FontWeight fontSemibold = FontWeight.w600;
  static const FontWeight fontBold = FontWeight.w700;

  // Line heights
  static const double leadingTight = 1.25;
  static const double leadingNormal = 1.5;
  static const double leadingRelaxed = 1.625;

  // Letter spacing
  static const double trackingWider = 0.05;
  static const double trackingWidest = 0.1;

  /// Get TextStyle with specified size and weight
  static TextStyle style({
    double size = textBase,
    FontWeight weight = fontNormal,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // Pre-defined text styles matching common patterns
  static TextStyle get xs => style(size: textXs);
  static TextStyle get sm => style(size: textSm);
  static TextStyle get base => style(size: textBase);
  static TextStyle get lg => style(size: textLg);
  static TextStyle get xl => style(size: textXl);
  static TextStyle get xl2 => style(size: text2xl);
  static TextStyle get xl3 => style(size: text3xl);

  // With weights
  static TextStyle get xsMedium => style(size: textXs, weight: fontMedium);
  static TextStyle get smMedium => style(size: textSm, weight: fontMedium);
  static TextStyle get baseMedium => style(size: textBase, weight: fontMedium);
  static TextStyle get lgMedium => style(size: textLg, weight: fontMedium);

  static TextStyle get xsSemibold => style(size: textXs, weight: fontSemibold);
  static TextStyle get smSemibold => style(size: textSm, weight: fontSemibold);
  static TextStyle get baseSemibold => style(size: textBase, weight: fontSemibold);
  static TextStyle get lgSemibold => style(size: textLg, weight: fontSemibold);

  static TextStyle get xsBold => style(size: textXs, weight: fontBold);
  static TextStyle get smBold => style(size: textSm, weight: fontBold);
  static TextStyle get baseBold => style(size: textBase, weight: fontBold);
  static TextStyle get lgBold => style(size: textLg, weight: fontBold);
  static TextStyle get xlBold => style(size: textXl, weight: fontBold);
  static TextStyle get xl2Bold => style(size: text2xl, weight: fontBold);
  static TextStyle get xl3Bold => style(size: text3xl, weight: fontBold);
}
