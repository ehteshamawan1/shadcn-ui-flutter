import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// Settings dropdown menu for accessing Backup, Administration, and Indstillinger
class SettingsDropdown extends StatelessWidget {
  const SettingsDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.settings,
        size: 20,
      ),
      tooltip: 'Indstillinger',
      offset: const Offset(0, 40),
      onSelected: (value) {
        switch (value) {
          case 'backup':
            // Navigate to Settings screen (Backup tab is in Settings)
            Navigator.pushNamed(context, '/settings');
            break;
          case 'admin':
            // Navigate to Settings
            Navigator.pushNamed(context, '/settings');
            break;
          case 'settings':
            // Navigate to Admin Settings
            Navigator.pushNamed(context, '/admin-settings');
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'backup',
          child: Row(
            children: [
              Icon(
                Icons.backup,
                size: 16,
                color: AppColors.foreground,
              ),
              const SizedBox(width: AppSpacing.s2),
              Text(
                'Backup',
                style: AppTypography.smMedium.copyWith(
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'admin',
          child: Row(
            children: [
              Icon(
                Icons.admin_panel_settings,
                size: 16,
                color: AppColors.foreground,
              ),
              const SizedBox(width: AppSpacing.s2),
              Text(
                'Administration',
                style: AppTypography.smMedium.copyWith(
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(
                Icons.settings,
                size: 16,
                color: AppColors.foreground,
              ),
              const SizedBox(width: AppSpacing.s2),
              Text(
                'Indstillinger',
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
}
