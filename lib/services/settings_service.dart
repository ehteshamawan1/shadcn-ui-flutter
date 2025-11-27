import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/app_setting.dart';
import 'sync_service.dart';

/// Service for managing application settings (dynamic dropdown options)
class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String appSettingsBox = 'app_settings';
  final _uuid = const Uuid();
  final SyncService _syncService = SyncService();
  bool _initialized = false;

  Box<AppSetting>? _box;

  /// Initialize the settings service
  Future<void> init() async {
    if (_initialized) return;

    // Register adapter if not already registered
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(AppSettingAdapter());
    }

    _box = await Hive.openBox<AppSetting>(appSettingsBox);
    _initialized = true;

    // Seed default values if empty
    if (_box!.isEmpty) {
      await _seedDefaultSettings();
    }
  }

  /// Get all settings for a category
  List<AppSetting> getSettingsByCategory(String category) {
    if (_box == null) return [];
    return _box!.values
        .where((s) => s.category == category && s.isActive)
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  /// Get all active values for a category (just the value strings)
  List<String> getValues(String category) {
    return getSettingsByCategory(category).map((s) => s.value).toList();
  }

  /// Get all active options for a category as dropdown items
  List<DropdownOption> getDropdownOptions(String category) {
    return getSettingsByCategory(category)
        .map((s) => DropdownOption(value: s.value, label: s.displayLabel))
        .toList();
  }

  /// Get a single setting by ID
  AppSetting? getSetting(String id) {
    return _box?.get(id);
  }

  /// Add a new setting
  Future<AppSetting> addSetting({
    required String category,
    required String value,
    String? label,
    int? displayOrder,
    Map<String, dynamic>? metadata,
  }) async {
    final existingSettings = getSettingsByCategory(category);
    final order = displayOrder ?? existingSettings.length;

    final setting = AppSetting(
      id: _uuid.v4(),
      category: category,
      value: value,
      label: label,
      displayOrder: order,
      isActive: true,
      isDefault: false,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      metadata: metadata,
    );

    await _box?.put(setting.id, setting);
    await _syncService.queueChange(
      entityType: 'app_setting',
      operation: 'upsert',
      payload: setting.toJson(),
    );

    return setting;
  }

  /// Update an existing setting
  Future<void> updateSetting(AppSetting setting) async {
    final updated = setting.copyWith(
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _box?.put(updated.id, updated);
    await _syncService.queueChange(
      entityType: 'app_setting',
      operation: 'upsert',
      payload: updated.toJson(),
    );
  }

  /// Delete a setting (soft delete - sets isActive to false)
  Future<void> deleteSetting(String id) async {
    final setting = _box?.get(id);
    if (setting != null) {
      // Don't allow deleting default settings
      if (setting.isDefault) {
        throw Exception('Cannot delete default settings');
      }
      final updated = setting.copyWith(
        isActive: false,
        updatedAt: DateTime.now().toIso8601String(),
      );
      await _box?.put(id, updated);
      await _syncService.queueChange(
        entityType: 'app_setting',
        operation: 'upsert',
        payload: updated.toJson(),
      );
    }
  }

  /// Hard delete a setting
  Future<void> hardDeleteSetting(String id) async {
    final setting = _box?.get(id);
    if (setting != null && !setting.isDefault) {
      await _box?.delete(id);
      await _syncService.queueChange(
        entityType: 'app_setting',
        operation: 'delete',
        payload: {'id': id},
      );
    }
  }

  /// Reorder settings within a category
  Future<void> reorderSettings(String category, List<String> orderedIds) async {
    for (int i = 0; i < orderedIds.length; i++) {
      final setting = _box?.get(orderedIds[i]);
      if (setting != null) {
        final updated = setting.copyWith(
          displayOrder: i,
          updatedAt: DateTime.now().toIso8601String(),
        );
        await _box?.put(updated.id, updated);
      }
    }
  }

  /// Get all settings (for admin)
  List<AppSetting> getAllSettings() {
    return _box?.values.toList() ?? [];
  }

  /// Get all categories that have settings
  List<String> getCategories() {
    final categories = _box?.values.map((s) => s.category).toSet().toList() ?? [];
    categories.sort();
    return categories;
  }

  /// Seed default settings
  Future<void> _seedDefaultSettings() async {
    debugPrint('Seeding default app settings...');

    final defaults = <String, List<Map<String, dynamic>>>{
      // Work Types
      SettingCategory.workTypes: [
        {'value': 'Opsætning', 'label': 'Opsætning'},
        {'value': 'Nedtagning', 'label': 'Nedtagning'},
        {'value': 'Tilsyn', 'label': 'Tilsyn'},
        {'value': 'Målinger', 'label': 'Målinger'},
        {'value': 'Skimmel', 'label': 'Skimmel'},
        {'value': 'Boring af drænhuller', 'label': 'Boring af drænhuller'},
        {'value': 'Andet', 'label': 'Andet'},
      ],

      // Equipment Categories
      SettingCategory.equipmentCategories: [
        {'value': 'Affugter', 'label': 'Affugter'},
        {'value': 'Varmeblaeser', 'label': 'Varmeblæser'},
        {'value': 'Ventilator', 'label': 'Ventilator'},
        {'value': 'Kaloriferer', 'label': 'Kaloriferer'},
        {'value': 'Generator', 'label': 'Generator'},
        {'value': 'Fyr', 'label': 'Fyr'},
        {'value': 'Tower', 'label': 'Tower'},
        {'value': 'Qube', 'label': 'Qube'},
        {'value': 'Draenhulsblaeser', 'label': 'Drænhulsblæser'},
        {'value': 'Andet', 'label': 'Andet'},
      ],

      // Equipment Actions
      SettingCategory.equipmentActions: [
        {'value': 'opsaet', 'label': 'Opsæt'},
        {'value': 'nedtag', 'label': 'Nedtag'},
        {'value': 'tilfoej', 'label': 'Tilføj'},
        {'value': 'defekt', 'label': 'Defekt'},
        {'value': 'afmeld', 'label': 'Afmeld'},
      ],

      // Sag Types
      SettingCategory.sagTypes: [
        {'value': 'udtørring', 'label': 'Udtørring'},
        {'value': 'varme', 'label': 'Varme'},
        {'value': 'begge', 'label': 'Begge'},
      ],

      // Regions
      SettingCategory.regions: [
        {'value': 'sjælland', 'label': 'Sjælland'},
        {'value': 'fyn', 'label': 'Fyn'},
        {'value': 'jylland', 'label': 'Jylland'},
      ],

      // Pricing Models
      SettingCategory.pricingModels: [
        {'value': 'dagsleje', 'label': 'Dagsleje (individuelle priser)'},
        {'value': 'fast_pris_per_lejlighed', 'label': 'Fast pris per lejlighed'},
        {'value': 'fast_pris_per_m2', 'label': 'Fast pris per m²'},
      ],

      // Affugter Types
      SettingCategory.affugterTypes: [
        {'value': 'adsorption', 'label': 'Adsorption'},
        {'value': 'kondens', 'label': 'Kondens'},
        {'value': 'varme', 'label': 'Varme'},
      ],

      // Affugter Brands
      SettingCategory.affugterBrands: [
        {'value': 'Master', 'label': 'Master'},
        {'value': 'Fral', 'label': 'Fral'},
        {'value': 'Qube', 'label': 'Qube'},
        {'value': 'Dantherm', 'label': 'Dantherm'},
        {'value': 'Andet', 'label': 'Andet'},
      ],

      // Equipment Status
      SettingCategory.equipmentStatus: [
        {'value': 'hjemme', 'label': 'Hjemme'},
        {'value': 'udlejet', 'label': 'Udlejet'},
        {'value': 'defekt', 'label': 'Defekt'},
      ],

      // Hose Types
      SettingCategory.hoseTypes: [
        {'value': 'Varmtvandsslange ø32', 'label': 'Varmtvandsslange ø32'},
        {'value': 'Varmtvandsslange ø50', 'label': 'Varmtvandsslange ø50'},
        {'value': 'Flexslange ø127', 'label': 'Flexslange ø127'},
        {'value': 'Flexslange ø102', 'label': 'Flexslange ø102'},
        {'value': 'Flexslange ø152', 'label': 'Flexslange ø152'},
        {'value': 'Poseslange ø200', 'label': 'Poseslange ø200'},
        {'value': 'Poseslange ø250', 'label': 'Poseslange ø250'},
        {'value': 'Poseslange ø315', 'label': 'Poseslange ø315'},
        {'value': 'Andet', 'label': 'Andet'},
      ],

      // Cable Types
      SettingCategory.cableTypes: [
        {'value': '230V kabel', 'label': '230V kabel'},
        {'value': '16 A kabel', 'label': '16 A kabel'},
        {'value': '32 A kabel', 'label': '32 A kabel'},
        {'value': '63 A kabel', 'label': '63 A kabel'},
        {'value': '16 A tavle', 'label': '16 A tavle'},
        {'value': '32 A tavle', 'label': '32 A tavle'},
        {'value': '63 A tavle', 'label': '63 A tavle'},
        {'value': '16 A split', 'label': '16 A split'},
        {'value': '16/32 overgang', 'label': '16/32 overgang'},
        {'value': '32/63 overgang', 'label': '32/63 overgang'},
        {'value': '16/230 stikprop', 'label': '16/230 stikprop'},
        {'value': 'CEE230/230 prop', 'label': 'CEE230/230 prop'},
        {'value': 'Forlængerkabel', 'label': 'Forlængerkabel'},
        {'value': 'Netværkskabel', 'label': 'Netværkskabel'},
        {'value': 'Andet', 'label': 'Andet'},
      ],

      // Ventilator Types
      SettingCategory.ventilatorTypes: [
        {'value': 'Ventilator stor', 'label': 'Ventilator stor'},
        {'value': 'Ventilator lille', 'label': 'Ventilator lille'},
      ],

      // Fyr Types
      SettingCategory.fyrTypes: [
        {'value': 'Fyr med tank', 'label': 'Fyr med tank'},
        {'value': 'Fyr uden tank', 'label': 'Fyr uden tank'},
      ],
    };

    for (final category in defaults.keys) {
      final values = defaults[category]!;
      for (int i = 0; i < values.length; i++) {
        final setting = AppSetting(
          id: _uuid.v4(),
          category: category,
          value: values[i]['value'] as String,
          label: values[i]['label'] as String?,
          displayOrder: i,
          isActive: true,
          isDefault: true,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );
        await _box?.put(setting.id, setting);
      }
    }

    debugPrint('✅ Default app settings seeded');
  }

  /// Clear all settings and reseed defaults
  Future<void> resetToDefaults() async {
    await _box?.clear();
    await _seedDefaultSettings();
  }
}

/// Simple dropdown option class
class DropdownOption {
  final String value;
  final String label;

  DropdownOption({required this.value, required this.label});
}
