import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import 'ui/ska_badge.dart';

/// Attention badge widget for showing notification indicators
/// Used in headers and list items to show items requiring attention
class AttentionBadge extends StatelessWidget {
  /// Number of items requiring attention
  final int count;

  /// Size of the badge
  final bool small;

  /// Custom icon
  final IconData? icon;

  const AttentionBadge({
    super.key,
    required this.count,
    this.small = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return const SizedBox.shrink();
    }

    return SkaBadge(
      text: count > 99 ? '99+' : count.toString(),
      variant: BadgeVariant.error,
      small: small,
      icon: icon != null ? Icon(icon, size: small ? 12 : 14) : null,
    );
  }
}

/// Bell icon with attention badge for header notifications
class AttentionBellIcon extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const AttentionBellIcon({
    super.key,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            count > 0 ? Icons.notifications_active : Icons.notifications_outlined,
            color: AppColors.foreground,
            size: 24,
          ),
          if (count > 0)
            Positioned(
              right: -2,
              top: -2,
              child: SkaBadgeCount(
                count: count,
                backgroundColor: AppColors.error,
              ),
            ),
        ],
      ),
      onPressed: onTap,
      tooltip: count > 0 ? '$count sag${count > 1 ? 'er' : ''} kræver opmærksomhed' : 'Notifikationer',
    );
  }
}

/// Attention indicator for list items
class AttentionIndicator extends StatelessWidget {
  final String? note;
  final bool compact;

  const AttentionIndicator({
    super.key,
    this.note,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Icon(
        Icons.priority_high,
        color: AppColors.error,
        size: 20,
      );
    }

    return Container(
      padding: AppSpacing.p2,
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.priority_high,
            color: AppColors.error,
            size: 16,
          ),
          if (note != null) ...[
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                note!,
                style: AppTypography.xs.copyWith(
                  color: AppColors.error,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else ...[
            const SizedBox(width: 6),
            Text(
              'Kræver opmærksomhed',
              style: AppTypography.xs.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Full attention card for detailed display
class AttentionCard extends StatelessWidget {
  final String note;
  final String? acknowledgedBy;
  final String? acknowledgedAt;
  final VoidCallback? onAcknowledge;

  const AttentionCard({
    super.key,
    required this.note,
    this.acknowledgedBy,
    this.acknowledgedAt,
    this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final isAcknowledged = acknowledgedBy != null;

    return Container(
      padding: AppSpacing.p4,
      decoration: BoxDecoration(
        color: isAcknowledged ? AppColors.successLight : AppColors.errorLight,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: isAcknowledged
              ? AppColors.success.withOpacity(0.3)
              : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAcknowledged ? Icons.check_circle : Icons.warning,
                color: isAcknowledged ? AppColors.success : AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAcknowledged ? 'Bekræftet' : 'Kræver opmærksomhed',
                  style: AppTypography.smSemibold.copyWith(
                    color: isAcknowledged ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note,
            style: AppTypography.sm.copyWith(
              color: AppColors.foreground,
            ),
          ),
          if (isAcknowledged) ...[
            const SizedBox(height: 8),
            Text(
              'Bekræftet af $acknowledgedBy',
              style: AppTypography.xs.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
            if (acknowledgedAt != null)
              Text(
                acknowledgedAt!,
                style: AppTypography.xs.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
          ] else if (onAcknowledge != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAcknowledge,
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Bekræft'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.primaryForeground,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
