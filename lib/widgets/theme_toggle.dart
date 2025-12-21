import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart' as theme_colors;
import 'ui/ska_button.dart';

/// Theme toggle widget for switching between light and dark mode
/// Matches React ThemeToggle.tsx component
class ThemeToggle extends StatelessWidget {
  /// Size of the icon button (default: icon size)
  final ButtonSize size;

  /// Show as icon only or with text
  final bool iconOnly;

  const ThemeToggle({
    super.key,
    this.size = ButtonSize.icon,
    this.iconOnly = true,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    if (iconOnly) {
      return SkaButton(
        variant: ButtonVariant.ghost,
        size: size,
        icon: Icon(
          isDark ? Icons.light_mode : Icons.dark_mode,
          size: 20,
        ),
        onPressed: () => _toggleTheme(themeProvider),
      );
    }

    return SkaButton(
      variant: ButtonVariant.ghost,
      size: size,
      icon: Icon(
        isDark ? Icons.light_mode : Icons.dark_mode,
        size: 20,
      ),
      text: isDark ? 'Lys tema' : 'Mørkt tema',
      onPressed: () => _toggleTheme(themeProvider),
    );
  }

  void _toggleTheme(ThemeProvider provider) {
    final newMode = provider.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    provider.setThemeMode(newMode);
  }
}

/// Theme toggle as a menu item for settings/dropdown menus
class ThemeToggleMenuItem extends StatelessWidget {
  const ThemeToggleMenuItem({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return ListTile(
      leading: Icon(
        isDark ? Icons.light_mode : Icons.dark_mode,
        color: theme_colors.AppColors.foreground,
      ),
      title: Text(isDark ? 'Lys tema' : 'Mørkt tema'),
      subtitle: Text(
        isDark
            ? 'Skift til lyst tema'
            : 'Skift til mørkt tema',
      ),
      onTap: () {
        final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
        themeProvider.setThemeMode(newMode);
      },
    );
  }
}

/// Theme toggle as a switch for settings screens
class ThemeToggleSwitch extends StatelessWidget {
  const ThemeToggleSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return SwitchListTile(
      secondary: Icon(
        isDark ? Icons.dark_mode : Icons.light_mode,
        color: theme_colors.AppColors.foreground,
      ),
      title: const Text('Mørkt tema'),
      subtitle: Text(
        isDark
            ? 'Aktiveret - Skånsomt for øjnene'
            : 'Deaktiveret - Standard lyst tema',
      ),
      value: isDark,
      onChanged: (value) {
        themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
      },
    );
  }
}
