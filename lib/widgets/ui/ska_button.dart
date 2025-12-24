import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';

/// Button variants matching shadcn/ui button component
enum ButtonVariant {
  primary, // default - filled primary color
  secondary, // gray background
  outline, // border with transparent background
  ghost, // transparent with hover
  destructive, // red/error color
  link, // text only, no background
}

/// Button sizes
enum ButtonSize {
  sm, // small - h-9 px-3
  md, // medium - h-10 px-4 (default)
  lg, // large - h-11 px-8
  xl, // extra large - h-12 px-4
  icon, // square icon button - h-10 w-10
}

/// SKA-DAN themed button component matching React shadcn/ui buttons
class SkaButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? child;
  final String? text;
  final Widget? icon;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool fullWidth;
  final bool loading;

  const SkaButton({
    super.key,
    this.onPressed,
    this.child,
    this.text,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.md,
    this.fullWidth = false,
    this.loading = false,
  }) : assert(child != null || text != null || icon != null, 'Either child, text, or icon must be provided');

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || loading;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: TextButton(
        onPressed: isDisabled ? null : onPressed,
        style: _getButtonStyle(isDisabled),
        child: _buildChild(),
      ),
    );
  }

  Widget _buildChild() {
    if (loading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getForegroundColor(false),
              ),
            ),
          ),
          if (text != null || child != null) ...[
            const SizedBox(width: 8),
            if (child != null) child! else Text(text!),
          ],
        ],
      );
    }

    if (child != null) return child!;

    if (icon != null && text == null) {
      return icon!;
    }

    if (icon != null && text != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(text!),
        ],
      );
    }

    if (icon != null) return icon!;

    return Text(text!);
  }

  ButtonStyle _getButtonStyle(bool isDisabled) {
    final backgroundColor = _getBackgroundColor(isDisabled);
    final foregroundColor = _getForegroundColor(isDisabled);
    final borderColor = _getBorderColor(isDisabled);
    final padding = _getPadding();
    final height = _getHeight();

    return TextButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      disabledBackgroundColor: AppColors.disabled(backgroundColor),
      disabledForegroundColor: AppColors.disabled(foregroundColor),
      padding: padding,
      minimumSize: Size(size == ButtonSize.icon ? height : 0, height),
      maximumSize: Size(
        size == ButtonSize.icon ? height : double.infinity,
        height,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusMd,
        side: borderColor != null
            ? BorderSide(
                color: isDisabled ? AppColors.disabled(borderColor) : borderColor,
                width: 1,
              )
            : BorderSide.none,
      ),
      elevation: 0,
      textStyle: AppTypography.style(
        size: AppTypography.textSm,
        weight: AppTypography.fontMedium,
      ),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.hovered)) {
            return _getHoverColor();
          }
          if (states.contains(WidgetState.pressed)) {
            return _getHoverColor().withOpacity(0.2);
          }
          return null;
        },
      ),
    );
  }

  Color _getBackgroundColor(bool isDisabled) {
    switch (variant) {
      case ButtonVariant.primary:
        return AppColors.primary;
      case ButtonVariant.secondary:
        return AppColors.secondary;
      case ButtonVariant.outline:
      case ButtonVariant.ghost:
      case ButtonVariant.link:
        return Colors.transparent;
      case ButtonVariant.destructive:
        return AppColors.error;
    }
  }

  Color _getForegroundColor(bool isDisabled) {
    switch (variant) {
      case ButtonVariant.primary:
        return AppColors.primaryForeground;
      case ButtonVariant.secondary:
        return AppColors.secondaryForeground;
      case ButtonVariant.outline:
      case ButtonVariant.ghost:
        return AppColors.foreground;
      case ButtonVariant.link:
        return AppColors.primary;
      case ButtonVariant.destructive:
        return Colors.white;
    }
  }

  Color? _getBorderColor(bool isDisabled) {
    switch (variant) {
      case ButtonVariant.outline:
        return AppColors.border;
      default:
        return null;
    }
  }

  Color _getHoverColor() {
    switch (variant) {
      case ButtonVariant.primary:
        return AppColors.primaryDark;
      case ButtonVariant.secondary:
        return AppColors.hover(AppColors.secondary);
      case ButtonVariant.outline:
      case ButtonVariant.ghost:
        return AppColors.secondary;
      case ButtonVariant.link:
        return Colors.transparent;
      case ButtonVariant.destructive:
        return AppColors.hover(AppColors.error);
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.sm:
        return AppSpacing.symmetric(
          horizontal: AppSpacing.s3,
          vertical: AppSpacing.s2,
        );
      case ButtonSize.md:
        return AppSpacing.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s2,
        );
      case ButtonSize.lg:
        return AppSpacing.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.s3,
        );
      case ButtonSize.xl:
        return AppSpacing.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s3,
        );
      case ButtonSize.icon:
        return EdgeInsets.zero;
    }
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.sm:
        return 36; // h-9
      case ButtonSize.md:
        return 40; // h-10
      case ButtonSize.lg:
        return 44; // h-11
      case ButtonSize.xl:
        return 56; // h-14 (increased for two-line content)
      case ButtonSize.icon:
        return 40; // h-10 w-10
    }
  }
}
