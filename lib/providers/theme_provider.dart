import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart' as theme_colors;
import '../theme/app_theme.dart';

/// Legacy AppColors class for backwards compatibility
/// Uses the new theme system internally
class AppColors {
  AppColors._();

  // Primary brand color
  static const primary = theme_colors.AppColors.primary;

  // Status colors
  static const success = theme_colors.AppColors.success;
  static const warning = theme_colors.AppColors.warning;
  static const error = theme_colors.AppColors.error;
  static const info = Color(0xFF0EA5E9); // sky-500

  // Equipment status
  static const statusHjemme = theme_colors.AppColors.success;
  static const statusUdlejet = theme_colors.AppColors.primary;
  static const statusDefekt = theme_colors.AppColors.error;

  // Sag types
  static const typeUdtorring = Color(0xFF1D4ED8); // blue-700
  static const typeVarme = Color(0xFF7A1D0E); // deep red
  static const typeBegge = Color(0xFF5B21B6); // violet-800

  // Regions
  static const regionSjaelland = Color(0xFF064E3B); // emerald-900
  static const regionFyn = Color(0xFF7C2D12); // orange-900
  static const regionJylland = Color(0xFF7F1D1D); // red-900

  // Dark theme - Tailwind Slate palette
  static const slate50 = Color(0xFFf8fafc);
  static const slate700 = Color(0xFF334155);
  static const slate800 = Color(0xFF1e293b);
  static const slate900 = Color(0xFF0f172a);
  static const slate950 = Color(0xFF020617);

  // Light theme specific
  static Color get lightBorder => theme_colors.AppColors.border;
  static Color get lightMuted => theme_colors.AppColors.mutedForeground;

  /// Get status color for equipment
  static Color getEquipmentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'hjemme':
        return statusHjemme;
      case 'udlejet':
        return statusUdlejet;
      case 'defekt':
        return statusDefekt;
      default:
        return Colors.grey;
    }
  }

  /// Get color for sag type
  static Color getSagTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'udtørring':
        return typeUdtorring;
      case 'varme':
        return typeVarme;
      case 'begge':
        return typeBegge;
      default:
        return Colors.grey;
    }
  }

  /// Get color for region
  static Color getRegionColor(String? region) {
    switch (region?.toLowerCase()) {
      case 'sjælland':
        return regionSjaelland;
      case 'fyn':
        return regionFyn;
      case 'jylland':
        return regionJylland;
      default:
        return Colors.grey;
    }
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode();
  }

  String _prefKeyForCurrentUser() {
    final userId = AuthService().currentUser?.id;
    return userId != null ? 'theme_mode_$userId' : 'theme_mode_default';
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    // Try user-specific preference first, then fall back to legacy key
    final userKey = _prefKeyForCurrentUser();
    var themeModeString = prefs.getString(userKey);
    themeModeString ??= prefs.getString('theme_mode'); // backward compatibility

    // Default to light (white) theme when nothing stored and persist it
    themeModeString ??= 'light';
    if (!prefs.containsKey(userKey)) {
      await prefs.setString(userKey, themeModeString);
    }

    _themeMode = themeModeString == 'dark' ? ThemeMode.dark : ThemeMode.light;
    theme_colors.AppColors.setBrightness(
      _themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light,
    );
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    theme_colors.AppColors.setBrightness(
      _themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light,
    );
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKeyForCurrentUser(),
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  Future<void> reloadForCurrentUser() async {
    await _loadThemeMode();
  }

  // Use the new comprehensive theme system matching React app
  static ThemeData get lightTheme => AppTheme.lightTheme.copyWith(
        textTheme: GoogleFonts.interTextTheme(AppTheme.lightTheme.textTheme),
      );

  static ThemeData get darkTheme => AppTheme.darkTheme.copyWith(
        textTheme: GoogleFonts.interTextTheme(AppTheme.darkTheme.textTheme),
      );
}
