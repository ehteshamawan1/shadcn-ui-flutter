import 'package:hive/hive.dart';

part 'kostpris.g.dart';

/// Price categories for kostpriser
class PriceCategory {
  // Labor rates
  static const String laborOpsaetning = 'labor_opsaetning';
  static const String laborNedtagning = 'labor_nedtagning';
  static const String laborTilsyn = 'labor_tilsyn';
  static const String laborMaalinger = 'labor_maalinger';
  static const String laborSkimmel = 'labor_skimmel';
  static const String laborBoring = 'labor_boring';
  static const String laborAndet = 'labor_andet';

  // Equipment daily rates
  static const String equipmentAffugter = 'equipment_affugter';
  static const String equipmentVarmeblaesser = 'equipment_varmeblaesser';
  static const String equipmentVentilator = 'equipment_ventilator';
  static const String equipmentKaloriferer = 'equipment_kaloriferer';
  static const String equipmentGenerator = 'equipment_generator';
  static const String equipmentFyr = 'equipment_fyr';
  static const String equipmentTower = 'equipment_tower';
  static const String equipmentQube = 'equipment_qube';
  static const String equipmentDraenhulsblaesser = 'equipment_draenhulsblaesser';
  static const String equipmentAndet = 'equipment_andet';

  // Blok pricing
  static const String blokPerLejlighed = 'blok_per_lejlighed';
  static const String blokPerM2 = 'blok_per_m2';

  // Overhead and other costs
  static const String overheadPercent = 'overhead_percent';
  static const String equipmentDriftPercent = 'equipment_drift_percent';

  /// Get display name for category
  static String getDisplayName(String category) {
    switch (category) {
      // Labor
      case laborOpsaetning:
        return 'Opsætning (time)';
      case laborNedtagning:
        return 'Nedtagning (time)';
      case laborTilsyn:
        return 'Tilsyn (time)';
      case laborMaalinger:
        return 'Målinger (time)';
      case laborSkimmel:
        return 'Skimmel (time)';
      case laborBoring:
        return 'Boring af drænhuller (time)';
      case laborAndet:
        return 'Andet arbejde (time)';
      // Equipment
      case equipmentAffugter:
        return 'Affugter (dag)';
      case equipmentVarmeblaesser:
        return 'Varmeblæser (dag)';
      case equipmentVentilator:
        return 'Ventilator (dag)';
      case equipmentKaloriferer:
        return 'Kaloriferer (dag)';
      case equipmentGenerator:
        return 'Generator (dag)';
      case equipmentFyr:
        return 'Fyr (dag)';
      case equipmentTower:
        return 'Tower (dag)';
      case equipmentQube:
        return 'Qube (dag)';
      case equipmentDraenhulsblaesser:
        return 'Drænhulsblæser (dag)';
      case equipmentAndet:
        return 'Andet udstyr (dag)';
      // Blok
      case blokPerLejlighed:
        return 'Per lejlighed';
      case blokPerM2:
        return 'Per m²';
      // Overhead
      case overheadPercent:
        return 'Overhead (%)';
      case equipmentDriftPercent:
        return 'Udstyrsdrift (%)';
      default:
        return category;
    }
  }

  /// Get category group
  static String getGroup(String category) {
    if (category.startsWith('labor_')) return 'Timer';
    if (category.startsWith('equipment_')) return 'Udstyr';
    if (category.startsWith('blok_')) return 'Blokke';
    return 'Overhead';
  }

  /// Get all labor categories
  static List<String> get laborCategories => [
    laborOpsaetning,
    laborNedtagning,
    laborTilsyn,
    laborMaalinger,
    laborSkimmel,
    laborBoring,
    laborAndet,
  ];

  /// Get all equipment categories
  static List<String> get equipmentCategories => [
    equipmentAffugter,
    equipmentVarmeblaesser,
    equipmentVentilator,
    equipmentKaloriferer,
    equipmentGenerator,
    equipmentFyr,
    equipmentTower,
    equipmentQube,
    equipmentDraenhulsblaesser,
    equipmentAndet,
  ];

  /// Get all blok categories
  static List<String> get blokCategories => [
    blokPerLejlighed,
    blokPerM2,
  ];

  /// Get all overhead categories
  static List<String> get overheadCategories => [
    overheadPercent,
    equipmentDriftPercent,
  ];

  /// Get all categories
  static List<String> get all => [
    ...laborCategories,
    ...equipmentCategories,
    ...blokCategories,
    ...overheadCategories,
  ];
}

/// Global price configuration - both cost prices (admin only) and default sales prices
@HiveType(typeId: 12)
class Kostpris extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String category; // From PriceCategory

  @HiveField(2)
  double kostpris; // Cost price (admin only) - used for profitability

  @HiveField(3)
  double salgspris; // Default sales price - shown on invoices

  @HiveField(4)
  String? description;

  @HiveField(5)
  bool isActive;

  @HiveField(6)
  String createdAt;

  @HiveField(7)
  String updatedAt;

  Kostpris({
    required this.id,
    required this.category,
    required this.kostpris,
    required this.salgspris,
    this.description,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get display name
  String get displayName => PriceCategory.getDisplayName(category);

  /// Get group name
  String get groupName => PriceCategory.getGroup(category);

  /// Calculate profit margin
  double get profitMargin => salgspris > 0 ? ((salgspris - kostpris) / salgspris) * 100 : 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'kostpris': kostpris,
    'salgspris': salgspris,
    'description': description,
    'isActive': isActive,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory Kostpris.fromJson(Map<String, dynamic> json) => Kostpris(
    id: json['id'] as String,
    category: json['category'] as String,
    kostpris: (json['kostpris'] as num).toDouble(),
    salgspris: (json['salgspris'] as num).toDouble(),
    description: json['description'] as String?,
    isActive: json['isActive'] as bool? ?? true,
    createdAt: json['createdAt'] as String,
    updatedAt: json['updatedAt'] as String,
  );

  Kostpris copyWith({
    String? id,
    String? category,
    double? kostpris,
    double? salgspris,
    String? description,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return Kostpris(
      id: id ?? this.id,
      category: category ?? this.category,
      kostpris: kostpris ?? this.kostpris,
      salgspris: salgspris ?? this.salgspris,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Case-specific sales price override
@HiveType(typeId: 13)
class SagPris extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String sagId;

  @HiveField(2)
  String category; // From PriceCategory

  @HiveField(3)
  double salgspris; // Overridden sales price for this case

  @HiveField(4)
  String? note;

  @HiveField(5)
  String createdAt;

  @HiveField(6)
  String updatedAt;

  SagPris({
    required this.id,
    required this.sagId,
    required this.category,
    required this.salgspris,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get display name
  String get displayName => PriceCategory.getDisplayName(category);

  Map<String, dynamic> toJson() => {
    'id': id,
    'sagId': sagId,
    'category': category,
    'salgspris': salgspris,
    'note': note,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory SagPris.fromJson(Map<String, dynamic> json) => SagPris(
    id: json['id'] as String,
    sagId: json['sagId'] as String,
    category: json['category'] as String,
    salgspris: (json['salgspris'] as num).toDouble(),
    note: json['note'] as String?,
    createdAt: json['createdAt'] as String,
    updatedAt: json['updatedAt'] as String,
  );

  SagPris copyWith({
    String? id,
    String? sagId,
    String? category,
    double? salgspris,
    String? note,
    String? createdAt,
    String? updatedAt,
  }) {
    return SagPris(
      id: id ?? this.id,
      sagId: sagId ?? this.sagId,
      category: category ?? this.category,
      salgspris: salgspris ?? this.salgspris,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
