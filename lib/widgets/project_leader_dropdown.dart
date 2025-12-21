import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../models/sag.dart';
import '../services/auth_service.dart';
import 'ui/ska_button.dart';
import 'ui/ska_badge.dart';

/// Project leader dropdown widget showing project leader contact information
/// Matches React ProjectLeaderDropdown.tsx component
class ProjectLeaderDropdown extends StatelessWidget {
  final Sag? currentSag;
  final bool showWhenEmpty;

  const ProjectLeaderDropdown({
    super.key,
    this.currentSag,
    this.showWhenEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    if (currentSag == null) {
      return showWhenEmpty ? _buildTrigger(context, enabled: false) : const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      tooltip: 'Projektleder info',
      child: _buildTrigger(context, enabled: true),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusLg,
        side: BorderSide(color: AppColors.border, width: 1),
      ),
      onSelected: (value) {
        if (value == 'economic') {
          Navigator.pushNamed(context, '/admin-settings');
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.business, size: 16, color: AppColors.foreground),
                  const SizedBox(width: 8),
                  Text(
                    'Projektinformation',
                    style: AppTypography.smSemibold.copyWith(
                      color: AppColors.foreground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Project leader name
              Row(
                children: [
                  Icon(Icons.person, size: 18, color: AppColors.foreground),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentSag!.byggeleder,
                      style: AppTypography.baseSemibold.copyWith(
                        color: AppColors.foreground,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Phone number with call button
              if (currentSag!.byggelederTlf != null) ...[
                Row(
                  children: [
                    Icon(Icons.phone, size: 18, color: AppColors.foreground),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        currentSag!.byggelederTlf!,
                        style: AppTypography.sm.copyWith(
                          color: AppColors.foreground,
                        ),
                      ),
                    ),
                    SkaButton(
                      variant: ButtonVariant.ghost,
                      size: ButtonSize.sm,
                      icon: const Icon(Icons.call, size: 16),
                      text: 'Ring',
                      onPressed: () => _makePhoneCall(currentSag!.byggelederTlf!),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Email with email button
              if (currentSag!.byggelederEmail != null) ...[
                Row(
                  children: [
                    Icon(Icons.email, size: 18, color: AppColors.foreground),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        currentSag!.byggelederEmail!,
                        style: AppTypography.sm.copyWith(
                          color: AppColors.foreground,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SkaButton(
                      variant: ButtonVariant.ghost,
                      size: ButtonSize.sm,
                      icon: const Icon(Icons.mail, size: 16),
                      text: 'Email',
                      onPressed: () => _sendEmail(currentSag!.byggelederEmail!),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              const Divider(height: 16),

              // Case information
              Text(
                'Sag information',
                style: AppTypography.xsSemibold.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
              const SizedBox(height: 8),

              if (currentSag!.bygherre != null) ...[
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: AppColors.mutedForeground),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        currentSag!.bygherre!,
                        style: AppTypography.xs.copyWith(
                          color: AppColors.foreground,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sag nummer',
                    style: AppTypography.xs.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  SkaBadge(
                    text: currentSag!.sagsnr,
                    variant: BadgeVariant.outline,
                    small: true,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Status',
                    style: AppTypography.xs.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  SkaBadge.status(
                    text: currentSag!.status,
                    status: currentSag!.status,
                    small: true,
                  ),
                ],
              ),
              if (currentSag!.sagType != null) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Type',
                      style: AppTypography.xs.copyWith(
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    SkaBadge.caseType(
                      currentSag!.sagType!,
                      small: true,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (AuthService().currentUser?.role == 'admin')
          const PopupMenuDivider(),
        if (AuthService().currentUser?.role == 'admin')
          PopupMenuItem<String>(
            value: 'economic',
            child: Row(
              children: [
                Icon(Icons.settings, size: 16, color: AppColors.foreground),
                const SizedBox(width: 8),
                Text(
                  'e-conomic API',
                  style: AppTypography.smMedium.copyWith(
                    color: AppColors.foreground,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTrigger(BuildContext context, {required bool enabled}) {
    final showLabel = MediaQuery.of(context).size.width >= Breakpoints.sm;
    final foreground = enabled ? AppColors.foreground : AppColors.mutedForeground;
    final border = enabled ? AppColors.border : AppColors.borderLight;

    return Container(
      padding: AppSpacing.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s2),
      decoration: BoxDecoration(
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.business, size: 16, color: foreground),
          if (showLabel) ...[
            const SizedBox(width: 8),
            Text(
              'Projektleder',
              style: AppTypography.smMedium.copyWith(
                color: foreground,
              ),
            ),
          ],
          const SizedBox(width: 6),
          Icon(Icons.expand_more, size: 16, color: foreground),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('Could not launch phone call to $phoneNumber');
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=SKA-DAN Sag ${currentSag?.sagsnr ?? ''}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('Could not launch email to $email');
    }
  }
}
