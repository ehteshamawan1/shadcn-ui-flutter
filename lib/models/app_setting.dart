import 'package:hive/hive.dart';

part 'app_setting.g.dart';

/// Categories for app settings - used to group dropdown options
class SettingCategory {
  static const String workTypes = 'work_types';
  static const String equipmentCategories = 'equipment_categories';
  static const String equipmentActions = 'equipment_actions';
  static const String sagTypes = 'sag_types';
  static const String regions = 'regions';
  static const String pricingModels = 'pricing_models';
  static const String affugterTypes = 'affugter_types';
  static const String affugterBrands = 'affugter_brands';
  static const String equipmentStatus = 'equipment_status';
  static const String hoseTypes = 'hose_types';
  static const String cableTypes = 'cable_types';
  static const String ventilatorTypes = 'ventilator_types';
  static const String fyrTypes = 'fyr_types';

  /// Get display name for category
  static String getDisplayName(String category) {
    switch (category) {
      case workTypes:
        return 'Arbejdstyper';
      case equipmentCategories:
        return 'Udstyrs kategorier';
      case equipmentActions:
        return 'Udstyrs handlinger';
      case sagTypes:
        return 'Sag typer';
      case regions:
        return 'Regioner';
      case pricingModels:
        return 'Prismodeller';
      case affugterTypes:
        return 'Affugter typer';
      case affugterBrands:
        return 'Affugter mærker';
      case equipmentStatus:
        return 'Udstyrs status';
      case hoseTypes:
        return 'Slange typer';
      case cableTypes:
        return 'Kabel typer';
      case ventilatorTypes:
        return 'Ventilator typer';
      case fyrTypes:
        return 'Fyr typer';
      default:
        return category;
    }
  }

  /// Get all categories
  static List<String> get all => [
        workTypes,
        equipmentCategories,
        equipmentActions,
        sagTypes,
        regions,
        pricingModels,
        affugterTypes,
        affugterBrands,
        equipmentStatus,
        hoseTypes,
        cableTypes,
        ventilatorTypes,
        fyrTypes,
      ];
}

@HiveType(typeId: 11)
class AppSetting extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String category;

  @HiveField(2)
  String value;

  @HiveField(3)
  String? label; // Display label (if different from value)

  @HiveField(4)
  int displayOrder;

  @HiveField(5)
  bool isActive;

  @HiveField(6)
  bool isDefault; // Whether this is a default/system value

  @HiveField(7)
  String createdAt;

  @HiveField(8)
  String updatedAt;

  @HiveField(9)
  Map<String, dynamic>? metadata; // Additional data (e.g., icon, color, description)

  AppSetting({
    required this.id,
    required this.category,
    required this.value,
    this.label,
    this.displayOrder = 0,
    this.isActive = true,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  /// Get display label (falls back to value if label is null)
  String get displayLabel => label ?? value;

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'value': value,
        'label': label,
        'displayOrder': displayOrder,
        'isActive': isActive,
        'isDefault': isDefault,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'metadata': metadata,
      };

  factory AppSetting.fromJson(Map<String, dynamic> json) => AppSetting(
        id: json['id'] as String,
        category: json['category'] as String,
        value: json['value'] as String,
        label: json['label'] as String?,
        displayOrder: json['displayOrder'] as int? ?? 0,
        isActive: json['isActive'] as bool? ?? true,
        isDefault: json['isDefault'] as bool? ?? false,
        createdAt: json['createdAt'] as String,
        updatedAt: json['updatedAt'] as String,
        metadata: json['metadata'] != null
            ? Map<String, dynamic>.from(json['metadata'] as Map)
            : null,
      );

  AppSetting copyWith({
    String? id,
    String? category,
    String? value,
    String? label,
    int? displayOrder,
    bool? isActive,
    bool? isDefault,
    String? createdAt,
    String? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return AppSetting(
      id: id ?? this.id,
      category: category ?? this.category,
      value: value ?? this.value,
      label: label ?? this.label,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
