import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';

/// Badge variants matching shadcn/ui badge component
enum BadgeVariant {
  default_, // gray background
  primary, // blue primary color
  secondary, // lighter gray
  success, // green
  warning, // orange
  error, // red/destructive
  outline, // border only
}

/// SKA-DAN themed badge component for status indicators and labels
class SkaBadge extends StatelessWidget {
  final String text;
  final BadgeVariant variant;
  final Widget? icon;
  final bool small;

  const SkaBadge({
    super.key,
    required this.text,
    this.variant = BadgeVariant.default_,
    this.icon,
    this.small = false,
  });

  /// Factory constructor for status badges
  factory SkaBadge.status({
    required String text,
    required String status,
    Widget? icon,
    bool small = false,
  }) {
    final variant = _getStatusVariant(status);
    return SkaBadge(
      text: text,
      variant: variant,
      icon: icon,
      small: small,
    );
  }

  /// Factory constructor for case type badges
  factory SkaBadge.caseType(String type, {bool small = false}) {
    return SkaBadge(
      text: type,
      variant: BadgeVariant.primary,
      small: small,
    );
  }

  /// Factory constructor for region badges
  factory SkaBadge.region(String region, {bool small = false}) {
    return SkaBadge(
      text: region,
      variant: BadgeVariant.default_,
      small: small,
    );
  }

  static BadgeVariant _getStatusVariant(String status) {
    switch (status.toLowerCase()) {
      case 'aktiv':
      case 'active':
        return BadgeVariant.primary;
      case 'afsluttet':
      case 'completed':
        return BadgeVariant.success;
      case 'udlejet':
      case 'rented':
        return BadgeVariant.warning;
      case 'defekt':
      case 'broken':
        return BadgeVariant.error;
      case 'hjemme':
      case 'home':
        return BadgeVariant.success;
      default:
        return BadgeVariant.default_;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();
    final fontSize = small ? AppTypography.textXs : AppTypography.textSm;

    return Container(
      padding: small
          ? AppSpacing.symmetric(horizontal: AppSpacing.s2, vertical: AppSpacing.s1)
          : AppSpacing.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s1),
      decoration: BoxDecoration(
        color: colors['background'],
        borderRadius: AppRadius.radiusMd,
        border: variant == BadgeVariant.outline
            ? Border.all(color: colors['border']!, width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            IconTheme(
              data: IconThemeData(
                color: colors['foreground'],
                size: small ? 12 : 14,
              ),
              child: icon!,
            ),
            SizedBox(width: small ? 4 : 6),
          ],
          Text(
            text,
            style: AppTypography.style(
              size: fontSize,
              weight: AppTypography.fontMedium,
              color: colors['foreground'],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Color> _getColors() {
    switch (variant) {
      case BadgeVariant.default_:
        return {
          'background': AppColors.secondary,
          'foreground': AppColors.secondaryForeground,
          'border': AppColors.border,
        };
      case BadgeVariant.primary:
        return {
          'background': AppColors.primary,
          'foreground': AppColors.primaryForeground,
          'border': AppColors.primary,
        };
      case BadgeVariant.secondary:
        return {
          'background': AppColors.backgroundSecondary,
          'foreground': AppColors.foreground,
          'border': AppColors.border,
        };
      case BadgeVariant.success:
        return {
          'background': AppColors.successLight,
          'foreground': AppColors.success,
          'border': AppColors.success,
        };
      case BadgeVariant.warning:
        return {
          'background': AppColors.warningLight,
          'foreground': AppColors.warning,
          'border': AppColors.warning,
        };
      case BadgeVariant.error:
        return {
          'background': AppColors.errorLight,
          'foreground': AppColors.error,
          'border': AppColors.error,
        };
      case BadgeVariant.outline:
        return {
          'background': Colors.transparent,
          'foreground': AppColors.foreground,
          'border': AppColors.border,
        };
    }
  }
}

/// Badge specifically for displaying counts
class SkaBadgeCount extends StatelessWidget {
  final int count;
  final Color? backgroundColor;
  final Color? textColor;

  const SkaBadgeCount({
    super.key,
    required this.count,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: const BoxConstraints(
        minWidth: 20,
        minHeight: 20,
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: AppTypography.style(
            size: 11,
            weight: AppTypography.fontSemibold,
            color: textColor ?? AppColors.primaryForeground,
          ),
        ),
      ),
    );
  }
}
