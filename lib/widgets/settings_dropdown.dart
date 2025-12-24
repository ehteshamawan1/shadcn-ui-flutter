import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// Settings dropdown menu for accessing Administration
class SettingsDropdown extends StatelessWidget {
  const SettingsDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.settings,
        size: 20,
      ),
      tooltip: 'Administration',
      offset: const Offset(0, 40),
      onSelected: (value) {
        if (value == 'admin') {
          // Navigate to Admin Settings
          Navigator.pushNamed(context, '/admin-settings');
        }
      },
      itemBuilder: (context) => [
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
      ],
    );
  }
}
