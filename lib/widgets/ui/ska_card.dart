import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_theme.dart';

/// SKA-DAN themed card component matching React shadcn/ui card
class SkaCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final bool hoverable;
  final List<BoxShadow>? shadow;

  const SkaCard({
    super.key,
    this.child,
    this.padding,
    this.onTap,
    this.hoverable = false,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: shadow ?? AppShadows.shadowSm,
      ),
      child: Padding(
        padding: padding ?? AppSpacing.p6,
        child: child,
      ),
    );

    if (onTap != null || hoverable) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusLg,
        hoverColor: AppColors.secondary.withOpacity(0.5),
        child: card,
      );
    }

    return card;
  }
}

/// Card header component with title and optional description
class SkaCardHeader extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? trailing;
  final EdgeInsets? padding;

  const SkaCardHeader({
    super.key,
    required this.title,
    this.description,
    this.trailing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? AppSpacing.p6,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.lgSemibold.copyWith(
                    color: AppColors.cardForeground,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description!,
                    style: AppTypography.sm.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 16),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Card content area
class SkaCardContent extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const SkaCardContent({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? AppSpacing.p6,
      child: child,
    );
  }
}

/// Card footer area
class SkaCardFooter extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const SkaCardFooter({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? AppSpacing.p6,
      child: child,
    );
  }
}

/// Complete card with header, content, and optional footer
class SkaCardComplete extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? headerTrailing;
  final Widget content;
  final Widget? footer;
  final VoidCallback? onTap;
  final bool hoverable;

  const SkaCardComplete({
    super.key,
    required this.title,
    this.description,
    this.headerTrailing,
    required this.content,
    this.footer,
    this.onTap,
    this.hoverable = false,
  });

  @override
  Widget build(BuildContext context) {
    return SkaCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      hoverable: hoverable,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkaCardHeader(
            title: title,
            description: description,
            trailing: headerTrailing,
          ),
          SkaCardContent(
            padding: AppSpacing.symmetric(horizontal: AppSpacing.s6),
            child: content,
          ),
          if (footer != null) ...[
            const Divider(height: 1),
            SkaCardFooter(child: footer!),
          ],
        ],
      ),
    );
  }
}
