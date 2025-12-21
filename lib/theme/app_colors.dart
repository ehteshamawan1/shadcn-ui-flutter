import 'package:flutter/material.dart';

/// Color palette matching React app CSS variables
/// Based on Tailwind CSS colors and shadcn/ui theme
class AppColors {
  static bool _isDark = false;

  /// Update dynamic color mode (called by ThemeProvider)
  static void setBrightness(Brightness brightness) {
    _isDark = brightness == Brightness.dark;
  }

  static bool get isDark => _isDark;

  // Primary (Blue) - HSL(221.2, 83.2%, 53.3%)
  static const primary = Color(0xFF2563EB);
  static const primaryForeground = Color(0xFFF8FAFC);
  static const primaryDark = Color(0xFF1D4ED8); // Darker for hover

  // Background (light + dark)
  static const _lightBackground = Color(0xFFFFFFFF);
  static const _lightBackgroundSecondary = Color(0xFFF9FAFB); // gray-50
  static const _lightGradientFrom = Color(0xFFEFF6FF); // blue-50
  static const _lightGradientTo = Color(0xFFE0E7FF); // indigo-100

  static const _darkBackground = Color(0xFF020617); // slate-950
  static const _darkBackgroundSecondary = Color(0xFF0F172A); // slate-900
  static const _darkGradientFrom = Color(0xFF0F172A); // slate-900
  static const _darkGradientTo = Color(0xFF1E293B); // slate-800

  static Color get background => _isDark ? _darkBackground : _lightBackground;
  static Color get backgroundSecondary => _isDark ? _darkBackgroundSecondary : _lightBackgroundSecondary;
  static Color get backgroundGradientFrom => _isDark ? _darkGradientFrom : _lightGradientFrom;
  static Color get backgroundGradientTo => _isDark ? _darkGradientTo : _lightGradientTo;

  // Foreground/Text - HSL(222.2, 84%, 4.9%)
  static const _lightForeground = Color(0xFF020817);
  static const _lightMutedForeground = Color(0xFF64748B); // gray-500
  static const _lightSubtleForeground = Color(0xFF6B7280); // gray-600

  static const _darkForeground = Color(0xFFF8FAFC); // slate-50
  static const _darkMutedForeground = Color(0xFF94A3B8); // slate-400
  static const _darkSubtleForeground = Color(0xFFCBD5E1); // slate-300

  static Color get foreground => _isDark ? _darkForeground : _lightForeground;
  static Color get mutedForeground => _isDark ? _darkMutedForeground : _lightMutedForeground;
  static Color get lightForeground => _isDark ? _darkSubtleForeground : _lightSubtleForeground;

  // Status Colors
  static const success = Color(0xFF16A34A); // green-600
  static const successLight = Color(0xFFDCFCE7); // green-50
  static const warning = Color(0xFFEA580C); // orange-600
  static const warningLight = Color(0xFFFFF7ED); // orange-50
  static const error = Color(0xFFDC2626); // red-600
  static const errorLight = Color(0xFFFEF2F2); // red-50

  // Border
  static const _lightBorder = Color(0xFFE2E8F0); // gray-200
  static const _lightBorderLight = Color(0xFFF1F5F9); // gray-100
  static const _darkBorder = Color(0xFF1E293B); // slate-800
  static const _darkBorderLight = Color(0xFF334155); // slate-700

  static Color get border => _isDark ? _darkBorder : _lightBorder;
  static Color get borderLight => _isDark ? _darkBorderLight : _lightBorderLight;

  // Card
  static const _lightCard = Color(0xFFFFFFFF);
  static const _darkCard = Color(0xFF0F172A); // slate-900
  static Color get card => _isDark ? _darkCard : _lightCard;
  static Color get cardForeground => _isDark ? _darkForeground : _lightForeground;

  // Secondary
  static const _lightSecondary = Color(0xFFF1F5F9); // gray-100
  static const _darkSecondary = Color(0xFF1E293B); // slate-800
  static Color get secondary => _isDark ? _darkSecondary : _lightSecondary;
  static Color get secondaryForeground => _isDark ? _darkForeground : _lightForeground;

  // Title (blue-900)
  static const _lightTitleBlue = Color(0xFF1E3A8A);
  static const _darkTitleBlue = Color(0xFFBFDBFE); // blue-200
  static Color get titleBlue => _isDark ? _darkTitleBlue : _lightTitleBlue;

  // Blue shades for version info box and various components
  static const blue50 = Color(0xFFEFF6FF);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue200 = Color(0xFFBFDBFE);
  static const blue600 = Color(0xFF2563EB);
  static const blue700 = Color(0xFF1D4ED8);
  static const blue900 = Color(0xFF1E3A8A);

  // Gray shades for various uses
  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF1F5F9);
  static const gray200 = Color(0xFFE2E8F0);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF64748B);
  static const gray600 = Color(0xFF6B7280);

  // Green shades
  static const green50 = Color(0xFFDCFCE7);
  static const green600 = Color(0xFF16A34A);

  // Orange shades
  static const orange50 = Color(0xFFFFF7ED);
  static const orange600 = Color(0xFFEA580C);

  // Red shades
  static const red50 = Color(0xFFFEF2F2);
  static const red600 = Color(0xFFDC2626);

  // Indigo shades
  static const indigo100 = Color(0xFFE0E7FF);

  // Hover states (10% darker)
  static Color hover(Color color) {
    return Color.lerp(color, Colors.black, 0.1) ?? color;
  }

  // Disabled states (50% opacity)
  static Color disabled(Color color) {
    return color.withOpacity(0.5);
  }
}
