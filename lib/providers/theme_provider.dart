import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

/// Centralized app colors - all colors should be defined here
class AppColors {
  AppColors._();

  // Primary brand color
  static const primary = Color(0xFF2563EB); // blue-600

  // Status colors
  static const success = Color(0xFF16A34A); // green-600
  static const warning = Color(0xFFF59E0B); // amber-500
  static const error = Color(0xFFDC2626); // red-600
  static const info = Color(0xFF0EA5E9); // sky-500

  // Equipment status
  static const statusHjemme = Color(0xFF16A34A); // green
  static const statusUdlejet = Color(0xFF2563EB); // blue
  static const statusDefekt = Color(0xFFDC2626); // red

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
  static const lightBorder = Color(0xFFE5E7EB); // gray-200
  static const lightMuted = Color(0xFF6B7280); // gray-500

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
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKeyForCurrentUser(),
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
    notifyListeners();
  }

  Future<void> reloadForCurrentUser() async {
    await _loadThemeMode();
  }

  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.interTextTheme(),
  );

  // Shadcn-ui dark theme colors (Tailwind slate)
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      surface: AppColors.slate900,
      onSurface: AppColors.slate50,
    ),
    scaffoldBackgroundColor: AppColors.slate950,
    cardColor: AppColors.slate900,
    dividerColor: AppColors.slate800,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.slate900,
      foregroundColor: AppColors.slate50,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.slate900,
    ),
    cardTheme: CardThemeData(
      color: AppColors.slate900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.slate800),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.slate800,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.slate700),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.slate700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: AppColors.slate800,
      selectedColor: AppColors.primary,
      side: BorderSide(color: AppColors.slate700),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: AppColors.slate900,
    ),
    dropdownMenuTheme: const DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.slate900),
      ),
    ),
    textTheme: GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    ),
  );
}
