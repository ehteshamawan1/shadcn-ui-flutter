import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';
import 'app_radius.dart';

/// Shadow system matching Tailwind CSS shadows
class AppShadows {
  static const shadowSm = [
    BoxShadow(
      color: Color(0x0D000000), // rgba(0, 0, 0, 0.05)
      blurRadius: 2,
      offset: Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  static const shadow = [
    BoxShadow(
      color: Color(0x1A000000), // rgba(0, 0, 0, 0.1)
      blurRadius: 4,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static const shadowMd = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 6,
      offset: Offset(0, 4),
      spreadRadius: -1,
    ),
  ];

  static const shadowLg = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 15,
      offset: Offset(0, 10),
      spreadRadius: -3,
    ),
  ];
}

/// Responsive breakpoints
class Breakpoints {
  static const double sm = 640;
  static const double md = 768;
  static const double lg = 1024;
  static const double xl = 1280;
  static const double xxl = 1536;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < md;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= md && width < lg;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= lg;

  static bool isExtraLarge(BuildContext context) =>
      MediaQuery.of(context).size.width >= xl;
}

/// Main theme configuration
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Get the light theme data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color scheme
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.primaryForeground,
        secondary: AppColors.secondary,
        onSecondary: AppColors.secondaryForeground,
        error: AppColors.error,
        onError: Colors.white,
        surface: AppColors.background,
        onSurface: AppColors.foreground,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.background,

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.foreground),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
          side: BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          elevation: 0,
          padding: AppSpacing.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.radiusMd,
          ),
          textStyle: AppTypography.style(
            size: AppTypography.textSm,
            weight: AppTypography.fontMedium,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.foreground,
          side: BorderSide(color: AppColors.border, width: 1),
          elevation: 0,
          padding: AppSpacing.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.radiusMd,
          ),
          textStyle: AppTypography.style(
            size: AppTypography.textSm,
            weight: AppTypography.fontMedium,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.foreground,
          padding: AppSpacing.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.radiusMd,
          ),
          textStyle: AppTypography.style(
            size: AppTypography.textSm,
            weight: AppTypography.fontMedium,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: AppSpacing.symmetric(
          horizontal: AppSpacing.s3,
          vertical: AppSpacing.s2,
        ),
        labelStyle: AppTypography.style(
          size: AppTypography.textSm,
          color: AppColors.mutedForeground,
        ),
        hintStyle: AppTypography.style(
          size: AppTypography.textSm,
          color: AppColors.mutedForeground,
        ),
      ),

      // Icon theme
      iconTheme: IconThemeData(
        color: AppColors.foreground,
        size: 24,
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.secondary,
        labelStyle: AppTypography.style(
          size: AppTypography.textXs,
          weight: AppTypography.fontMedium,
          color: AppColors.secondaryForeground,
        ),
        padding: AppSpacing.symmetric(horizontal: AppSpacing.s2, vertical: AppSpacing.s1),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusMd,
        ),
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
          side: BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      // Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.top(AppRadius.lg),
        ),
      ),

      // Text theme
      textTheme: TextTheme(
        displayLarge: AppTypography.xl3Bold.copyWith(color: AppColors.foreground),
        displayMedium: AppTypography.xl2Bold.copyWith(color: AppColors.foreground),
        displaySmall: AppTypography.xlBold.copyWith(color: AppColors.foreground),
        headlineLarge: AppTypography.xl2Bold.copyWith(color: AppColors.foreground),
        headlineMedium: AppTypography.xlBold.copyWith(color: AppColors.foreground),
        headlineSmall: AppTypography.lgBold.copyWith(color: AppColors.foreground),
        titleLarge: AppTypography.lgSemibold.copyWith(color: AppColors.foreground),
        titleMedium: AppTypography.baseSemibold.copyWith(color: AppColors.foreground),
        titleSmall: AppTypography.smSemibold.copyWith(color: AppColors.foreground),
        bodyLarge: AppTypography.base.copyWith(color: AppColors.foreground),
        bodyMedium: AppTypography.sm.copyWith(color: AppColors.foreground),
        bodySmall: AppTypography.xs.copyWith(color: AppColors.mutedForeground),
        labelLarge: AppTypography.baseMedium.copyWith(color: AppColors.foreground),
        labelMedium: AppTypography.smMedium.copyWith(color: AppColors.foreground),
        labelSmall: AppTypography.xsMedium.copyWith(color: AppColors.mutedForeground),
      ),
    );
  }

  /// Get the dark theme data (for future dark mode support)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.primaryForeground,
        secondary: AppColors.secondary,
        onSecondary: AppColors.secondaryForeground,
        error: AppColors.error,
        onError: Colors.white,
        surface: AppColors.background,
        onSurface: AppColors.foreground,
      ),

      scaffoldBackgroundColor: AppColors.background,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.foreground),
      ),

      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
          side: BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          elevation: 0,
          padding: AppSpacing.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.radiusMd,
          ),
          textStyle: AppTypography.style(
            size: AppTypography.textSm,
            weight: AppTypography.fontMedium,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.foreground,
          side: BorderSide(color: AppColors.border, width: 1),
          elevation: 0,
          padding: AppSpacing.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.radiusMd,
          ),
          textStyle: AppTypography.style(
            size: AppTypography.textSm,
            weight: AppTypography.fontMedium,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.foreground,
          padding: AppSpacing.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.radiusMd,
          ),
          textStyle: AppTypography.style(
            size: AppTypography.textSm,
            weight: AppTypography.fontMedium,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.secondary,
        border: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: AppSpacing.symmetric(
          horizontal: AppSpacing.s3,
          vertical: AppSpacing.s2,
        ),
        labelStyle: AppTypography.style(
          size: AppTypography.textSm,
          color: AppColors.mutedForeground,
        ),
        hintStyle: AppTypography.style(
          size: AppTypography.textSm,
          color: AppColors.mutedForeground,
        ),
      ),

      iconTheme: IconThemeData(
        color: AppColors.foreground,
        size: 24,
      ),

      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.secondary,
        labelStyle: AppTypography.style(
          size: AppTypography.textXs,
          weight: AppTypography.fontMedium,
          color: AppColors.secondaryForeground,
        ),
        padding: AppSpacing.symmetric(horizontal: AppSpacing.s2, vertical: AppSpacing.s1),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusMd,
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
          side: BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.top(AppRadius.lg),
        ),
      ),

      textTheme: TextTheme(
        displayLarge: AppTypography.xl3Bold.copyWith(color: AppColors.foreground),
        displayMedium: AppTypography.xl2Bold.copyWith(color: AppColors.foreground),
        displaySmall: AppTypography.xlBold.copyWith(color: AppColors.foreground),
        headlineLarge: AppTypography.xl2Bold.copyWith(color: AppColors.foreground),
        headlineMedium: AppTypography.xlBold.copyWith(color: AppColors.foreground),
        headlineSmall: AppTypography.lgBold.copyWith(color: AppColors.foreground),
        titleLarge: AppTypography.lgSemibold.copyWith(color: AppColors.foreground),
        titleMedium: AppTypography.baseSemibold.copyWith(color: AppColors.foreground),
        titleSmall: AppTypography.smSemibold.copyWith(color: AppColors.foreground),
        bodyLarge: AppTypography.base.copyWith(color: AppColors.foreground),
        bodyMedium: AppTypography.sm.copyWith(color: AppColors.foreground),
        bodySmall: AppTypography.xs.copyWith(color: AppColors.mutedForeground),
        labelLarge: AppTypography.baseMedium.copyWith(color: AppColors.foreground),
        labelMedium: AppTypography.smMedium.copyWith(color: AppColors.foreground),
        labelSmall: AppTypography.xsMedium.copyWith(color: AppColors.mutedForeground),
      ),
    );
  }
}
