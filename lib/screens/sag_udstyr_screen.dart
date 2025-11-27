import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/blok.dart';
import '../models/equipment_log.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/filter_widget.dart';

/// Equipment item stored locally for a sag
class SagEquipment {
  final String id;
  final String category;
  final String type;
  final String? customText;
  final int quantity;
  final String? specifications;
  final String setupDate;
  final String? takedownDate;
  final String addedBy;
  final String? nfcId;
  final String status; // 'aktiv' | 'nedtaget'
  final String? maskinNr;
  final double? prisPrDag;
  final double? effekt;
  final String? blokId;
  final String? blokNavn;

  SagEquipment({
    required this.id,
    required this.category,
    required this.type,
    this.customText,
    required this.quantity,
    this.specifications,
    required this.setupDate,
    this.takedownDate,
    required this.addedBy,
    this.nfcId,
    required this.status,
    this.maskinNr,
    this.prisPrDag,
    this.effekt,
    this.blokId,
    this.blokNavn,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'type': type,
        'customText': customText,
        'quantity': quantity,
        'specifications': specifications,
        'setupDate': setupDate,
        'takedownDate': takedownDate,
        'addedBy': addedBy,
        'nfcId': nfcId,
        'status': status,
        'maskinNr': maskinNr,
        'prisPrDag': prisPrDag,
        'effekt': effekt,
        'blokId': blokId,
        'blokNavn': blokNavn,
      };

  factory SagEquipment.fromJson(Map<String, dynamic> json) => SagEquipment(
        id: json['id'] as String,
        category: json['category'] as String,
        type: json['type'] as String,
        customText: json['customText'] as String?,
        quantity: json['quantity'] as int? ?? 1,
        specifications: json['specifications'] as String?,
        setupDate: json['setupDate'] as String,
        takedownDate: json['takedownDate'] as String?,
        addedBy: json['addedBy'] as String,
        nfcId: json['nfcId'] as String?,
        status: json['status'] as String? ?? 'aktiv',
        maskinNr: json['maskinNr'] as String?,
        prisPrDag: (json['prisPrDag'] as num?)?.toDouble(),
        effekt: (json['effekt'] as num?)?.toDouble(),
        blokId: json['blokId'] as String?,
        blokNavn: json['blokNavn'] as String?,
      );

  SagEquipment copyWith({
    String? id,
    String? category,
    String? type,
    String? customText,
    int? quantity,
    String? specifications,
    String? setupDate,
    String? takedownDate,
    String? addedBy,
    String? nfcId,
    String? status,
    String? maskinNr,
    double? prisPrDag,
    double? effekt,
    String? blokId,
    String? blokNavn,
  }) {
    return SagEquipment(
      id: id ?? this.id,
      category: category ?? this.category,
      type: type ?? this.type,
      customText: customText ?? this.customText,
      quantity: quantity ?? this.quantity,
      specifications: specifications ?? this.specifications,
      setupDate: setupDate ?? this.setupDate,
      takedownDate: takedownDate ?? this.takedownDate,
      addedBy: addedBy ?? this.addedBy,
      nfcId: nfcId ?? this.nfcId,
      status: status ?? this.status,
      maskinNr: maskinNr ?? this.maskinNr,
      prisPrDag: prisPrDag ?? this.prisPrDag,
      effekt: effekt ?? this.effekt,
      blokId: blokId ?? this.blokId,
      blokNavn: blokNavn ?? this.blokNavn,
    );
  }
}

/// Equipment category definition
class EquipmentCategory {
  final String name;
  final List<EquipmentType> types;
  final IconData icon;

  const EquipmentCategory({
    required this.name,
    required this.types,
    required this.icon,
  });
}

class EquipmentType {
  final String name;
  final String? description;
  final bool hasVariableEffect;
  final bool hasDetailedForm;

  const EquipmentType({
    required this.name,
    this.description,
    this.hasVariableEffect = false,
    this.hasDetailedForm = false,
  });
}

class SagUdstyrsScreen extends StatefulWidget {
  final String sagId;

  const SagUdstyrsScreen({super.key, required this.sagId});

  @override
  State<SagUdstyrsScreen> createState() => _SagUdstyrsScreenState();
}

class _SagUdstyrsScreenState extends State<SagUdstyrsScreen> {
  final _dbService = DatabaseService();
  final _uuid = const Uuid();

  List<SagEquipment> _equipment = [];
  List<SagEquipment> _filteredEquipment = [];
  List<Blok> _blokke = [];
  List<EquipmentLog> _equipmentLogs = [];

  bool _loading = true;

  // Filters
  String _searchTerm = '';
  String _statusFilter = 'all';
  String _categoryFilter = 'all';
  String _blokFilter = 'all';

  // Form state
  String? _selectedCategory;
  String? _selectedType;
  String? _selectedBlokId;
  String _maskinNr = '';
  String _customText = '';
  String _specifications = '';
  int _quantity = 1;
  double _prisPrDag = 0;
  double _effekt = 0;

  // All 10 equipment categories matching React Native
  static const List<EquipmentCategory> _equipmentCategories = [
    EquipmentCategory(
      name: 'Affugter',
      icon: Icons.water_drop,
      types: [
        EquipmentType(name: 'Fral', description: 'Klik for detaljer'),
        EquipmentType(name: 'Master', description: 'Klik for detaljer'),
        EquipmentType(name: 'Andet', description: 'Klik for detaljer'),
      ],
    ),
    EquipmentCategory(
      name: 'Varmeblaeser',
      icon: Icons.heat_pump,
      types: [
        EquipmentType(
          name: 'Varmeblaeser',
          description: 'Variabel effekt',
          hasVariableEffect: true,
          hasDetailedForm: true,
        ),
      ],
    ),
    EquipmentCategory(
      name: 'Ventilator',
      icon: Icons.air,
      types: [
        EquipmentType(name: 'Ventilator stor', description: 'Klik for detaljer', hasDetailedForm: true),
        EquipmentType(name: 'Ventilator lille', description: 'Klik for detaljer', hasDetailedForm: true),
      ],
    ),
    EquipmentCategory(
      name: 'Kaloriferer',
      icon: Icons.local_fire_department,
      types: [
        EquipmentType(
          name: 'Kaloriferer',
          description: 'Variabel effekt',
          hasVariableEffect: true,
          hasDetailedForm: true,
        ),
      ],
    ),
    EquipmentCategory(
      name: 'Generator',
      icon: Icons.electrical_services,
      types: [
        EquipmentType(name: 'Generator', description: 'Klik for detaljer', hasDetailedForm: true),
      ],
    ),
    EquipmentCategory(
      name: 'Fyr',
      icon: Icons.fireplace,
      types: [
        EquipmentType(name: 'Fyr med tank', description: 'Klik for detaljer', hasDetailedForm: true),
        EquipmentType(name: 'Fyr uden tank', description: 'Klik for detaljer', hasDetailedForm: true),
      ],
    ),
    EquipmentCategory(
      name: 'Tower',
      icon: Icons.cell_tower,
      types: [
        EquipmentType(name: 'Tower', description: 'Klik for detaljer', hasDetailedForm: true),
      ],
    ),
    EquipmentCategory(
      name: 'Qube',
      icon: Icons.view_in_ar,
      types: [
        EquipmentType(name: 'Qube', description: 'Klik for detaljer', hasDetailedForm: true),
      ],
    ),
    EquipmentCategory(
      name: 'Draenhulsblaeser',
      icon: Icons.wb_sunny,
      types: [
        EquipmentType(name: 'Draenhulsblaeser', description: 'Klik for detaljer', hasDetailedForm: true),
      ],
    ),
    EquipmentCategory(
      name: 'Andet',
      icon: Icons.more_horiz,
      types: [
        EquipmentType(name: 'Andet', description: 'Fritekst beskrivelse', hasDetailedForm: true),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    // Load blokke for this sag
    _blokke = _dbService.getBlokkeBySag(widget.sagId);

    // Load equipment logs for this sag
    _equipmentLogs = _dbService.getEquipmentLogsBySag(widget.sagId);

    // For now, equipment data is derived from equipment logs
    // In production, this would be stored separately or in a dedicated table
    _equipment = _buildEquipmentFromLogs();

    _applyFilters();

    setState(() => _loading = false);
  }

  /// Build equipment list from equipment logs
  /// Each 'tilfoej' action represents adding equipment, 'nedtag' removes it
  List<SagEquipment> _buildEquipmentFromLogs() {
    final Map<String, SagEquipment> equipmentMap = {};

    for (final log in _equipmentLogs) {
      if (log.action == 'tilfoej' || log.action == 'opsaet') {
        final data = log.data;
        final eq = SagEquipment(
          id: log.id,
          category: log.category,
          type: data['type'] as String? ?? log.category,
          customText: data['customText'] as String?,
          quantity: data['quantity'] as int? ?? 1,
          specifications: data['specifications'] as String?,
          setupDate: log.timestamp,
          addedBy: log.user,
          nfcId: data['nfcId'] as String?,
          status: 'aktiv',
          maskinNr: data['maskinNr'] as String?,
          prisPrDag: (data['prisPrDag'] as num?)?.toDouble(),
          effekt: (data['effekt'] as num?)?.toDouble(),
          blokId: log.blokId,
          blokNavn: data['blokNavn'] as String?,
        );
        equipmentMap[log.id] = eq;
      } else if (log.action == 'nedtag') {
        final targetId = log.data['equipmentId'] as String? ?? log.id;
        if (equipmentMap.containsKey(targetId)) {
          equipmentMap[targetId] = equipmentMap[targetId]!.copyWith(
            status: 'nedtaget',
            takedownDate: log.timestamp,
          );
        }
      }
    }

    return equipmentMap.values.toList()
      ..sort((a, b) => b.setupDate.compareTo(a.setupDate));
  }

  void _applyFilters() {
    _filteredEquipment = _equipment.where((eq) {
      // Search filter
      final matchesSearch = _searchTerm.isEmpty ||
          eq.type.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          (eq.customText?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false) ||
          (eq.specifications?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false) ||
          (eq.maskinNr?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false) ||
          (eq.blokNavn?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false);

      // Status filter
      final matchesStatus = _statusFilter == 'all' || eq.status == _statusFilter;

      // Category filter
      final matchesCategory = _categoryFilter == 'all' || eq.category == _categoryFilter;

      // Blok filter
      final matchesBlok = _blokFilter == 'all' ||
          eq.blokId == _blokFilter ||
          (_blokFilter == 'ingen' && (eq.blokId == null || eq.blokId!.isEmpty));

      return matchesSearch && matchesStatus && matchesCategory && matchesBlok;
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'aktiv':
        return AppColors.success;
      case 'nedtaget':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'aktiv':
        return Icons.check_circle;
      case 'nedtaget':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  IconData _getCategoryIcon(String category) {
    final cat = _equipmentCategories.firstWhere(
      (c) => c.name == category,
      orElse: () => _equipmentCategories.last,
    );
    return cat.icon;
  }

  List<String> _getUniqueCategories() {
    final categories = _equipment.map((e) => e.category).toSet().toList();
    categories.sort();
    return categories;
  }

  bool _needsDetailedForm(String? category) {
    if (category == null) return false;
    final cat = _equipmentCategories.firstWhere(
      (c) => c.name == category,
      orElse: () => _equipmentCategories.last,
    );
    return cat.types.any((t) => t.hasDetailedForm);
  }

  bool _hasVariableEffect(String? type) {
    if (type == null) return false;
    return type == 'Varmeblaeser' || type == 'Kaloriferer';
  }

  /// Validate machine number format for Affugter (x-xxxx, x-xxxxx, x-xxx)
  bool _validateMaskinNr(String value, String category) {
    if (category != 'Affugter') return true;
    if (value.isEmpty) return true;
    return RegExp(r'^\d-\d{3,5}$').hasMatch(value);
  }

  void _resetForm() {
    setState(() {
      _selectedCategory = null;
      _selectedType = null;
      _selectedBlokId = null;
      _maskinNr = '';
      _customText = '';
      _specifications = '';
      _quantity = 1;
      _prisPrDag = 0;
      _effekt = 0;
    });
  }

  Future<void> _addEquipment() async {
    if (_selectedCategory == null || _selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vaelg venligst kategori og type')),
      );
      return;
    }

    // Validation for Affugter
    if (_selectedCategory == 'Affugter') {
      if (_selectedType == 'Andet') {
        if (_customText.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Indtast venligst beskrivelse for affugteren')),
          );
          return;
        }
      } else {
        if (_maskinNr.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Indtast venligst maskin nr. for affugteren')),
          );
          return;
        }
        if (!_validateMaskinNr(_maskinNr, 'Affugter')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maskin nr. skal vaere i formatet x-xxxx (fx 1-2345)')),
          );
          return;
        }
      }
      // Affugter can only have quantity 1
      _quantity = 1;
    }

    // Validation for Andet category
    if (_selectedType == 'Andet' && _selectedCategory != 'Affugter' && _customText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indtast venligst beskrivelse for fritekst')),
      );
      return;
    }

    final currentUser = AuthService().currentUser;
    final userName = currentUser?.name ?? 'Ukendt';
    final blok = _selectedBlokId != null && _selectedBlokId!.isNotEmpty
        ? _blokke.firstWhere((b) => b.id == _selectedBlokId, orElse: () => _blokke.first)
        : null;

    final equipmentLog = EquipmentLog(
      id: _uuid.v4(),
      sagId: widget.sagId,
      blokId: _selectedBlokId,
      category: _selectedCategory!,
      action: 'tilfoej',
      data: {
        'type': _selectedType,
        'customText': _customText.isNotEmpty ? _customText : null,
        'quantity': _quantity,
        'specifications': _specifications.isNotEmpty ? _specifications : null,
        'maskinNr': _maskinNr.isNotEmpty ? _maskinNr : null,
        'prisPrDag': _prisPrDag > 0 ? _prisPrDag : null,
        'effekt': _effekt > 0 ? _effekt : null,
        'blokNavn': blok?.navn,
        'status': 'aktiv',
      },
      timestamp: DateTime.now().toIso8601String(),
      user: userName,
      note: 'Udstyr tilfojet: $_selectedCategory - $_selectedType${blok != null ? ' (${blok.navn})' : ''}',
    );

    await _dbService.addEquipmentLog(equipmentLog);

    _resetForm();
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Udstyr tilfojet${blok != null ? ' til ${blok.navn}' : ''}'),
        backgroundColor: AppColors.success,
      ),
    );

    _loadData();
  }

  Future<void> _changeStatus(SagEquipment equipment, String newStatus) async {
    final currentUser = AuthService().currentUser;
    final userName = currentUser?.name ?? 'Ukendt';

    final equipmentLog = EquipmentLog(
      id: _uuid.v4(),
      sagId: widget.sagId,
      blokId: equipment.blokId,
      category: equipment.category,
      action: newStatus == 'nedtaget' ? 'nedtag' : 'opsaet',
      data: {
        'equipmentId': equipment.id,
        'type': equipment.type,
        'previousStatus': equipment.status,
        'newStatus': newStatus,
        'maskinNr': equipment.maskinNr,
      },
      timestamp: DateTime.now().toIso8601String(),
      user: userName,
      note: 'Status aendret: ${equipment.category} - ${equipment.type} (${equipment.status} -> $newStatus)',
    );

    await _dbService.addEquipmentLog(equipmentLog);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Status opdateret')),
    );

    _loadData();
  }

  void _showAddEquipmentDialog() {
    _resetForm();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tilfoej nyt udstyr',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Vaelg udstyrskategori fra listen nedenfor',
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category selection
                          if (_selectedCategory == null) ...[
                            Text(
                              'Vaelg udstyr kategori (${_equipmentCategories.length} kategorier)',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 12),
                            ...List.generate(_equipmentCategories.length, (index) {
                              final category = _equipmentCategories[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: OutlinedButton(
                                  onPressed: () {
                                    setDialogState(() {
                                      _selectedCategory = category.name;
                                      // Auto-select type if only one
                                      if (category.types.length == 1) {
                                        _selectedType = category.types.first.name;
                                        _quantity = category.name == 'Affugter' ? 1 : 1;
                                      }
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.all(16),
                                    alignment: Alignment.centerLeft,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(category.icon, color: AppColors.primary),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${index + 1}. ${category.name}',
                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                            ),
                                            Text(
                                              '${category.types.length} typer tilgaengelige',
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],

                          // Selected category indicator and form
                          if (_selectedCategory != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(_getCategoryIcon(_selectedCategory!), color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Valgt: $_selectedCategory',
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        if (_selectedType != null)
                                          Text(
                                            'Type: $_selectedType',
                                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                          ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setDialogState(() {
                                        _selectedCategory = null;
                                        _selectedType = null;
                                      });
                                    },
                                    child: const Text('Skift'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Type selection if category has multiple types
                            if (_selectedType == null) ...[
                              const Text('Vaelg type', style: TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              ..._equipmentCategories
                                  .firstWhere((c) => c.name == _selectedCategory)
                                  .types
                                  .map((type) => Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: OutlinedButton(
                                          onPressed: () {
                                            setDialogState(() {
                                              _selectedType = type.name;
                                              _quantity = _selectedCategory == 'Affugter' ? 1 : 1;
                                            });
                                          },
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.all(12),
                                            alignment: Alignment.centerLeft,
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(type.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                              if (type.description != null)
                                                Text(
                                                  type.description!,
                                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                                ),
                                            ],
                                          ),
                                        ),
                                      )),
                            ],

                            // Form fields when type is selected
                            if (_selectedType != null) ...[
                              // Blok assignment
                              const Text('Tildel til blok (valgfri)', style: TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedBlokId,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Vaelg en blok...',
                                ),
                                items: [
                                  const DropdownMenuItem(value: '', child: Text('Ingen blok (generelt udstyr)')),
                                  ..._blokke.map((blok) => DropdownMenuItem(
                                        value: blok.id,
                                        child: Row(
                                          children: [
                                            const Icon(Icons.apartment, size: 16),
                                            const SizedBox(width: 8),
                                            Text(blok.navn),
                                          ],
                                        ),
                                      )),
                                ],
                                onChanged: (value) {
                                  setDialogState(() => _selectedBlokId = value);
                                },
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Vaelg hvilken blok dette udstyr skal tilhoere.',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                              const SizedBox(height: 16),

                              // Affugter specific fields
                              if (_selectedCategory == 'Affugter') ...[
                                if (_selectedType == 'Fral' || _selectedType == 'Master') ...[
                                  const Text('Maskin nr. *', style: TextStyle(fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      hintText: 'x-xxxx (fx 1-2345)',
                                      errorText: _maskinNr.isNotEmpty && !_validateMaskinNr(_maskinNr, 'Affugter')
                                          ? 'Format skal vaere x-xxxx (fx 1-2345)'
                                          : null,
                                    ),
                                    onChanged: (value) => setDialogState(() => _maskinNr = value),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                if (_selectedType == 'Andet') ...[
                                  const Text('Beskrivelse af affugteren *', style: TextStyle(fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'fx "uden nummer" eller "stor kineser"',
                                    ),
                                    onChanged: (value) => setDialogState(() => _customText = value),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                // Affugter quantity is always 1
                                const Text('Antal', style: TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                TextField(
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    enabled: false,
                                  ),
                                  controller: TextEditingController(text: '1'),
                                  enabled: false,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Affugtere kan ikke bulk opsaettes - kun 1 ad gangen',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ],

                              // Non-Affugter fields
                              if (_selectedCategory != 'Affugter') ...[
                                // Maskin nr for detailed form categories
                                if (_needsDetailedForm(_selectedCategory)) ...[
                                  const Text('Maskin nr. / Registreringsnummer', style: TextStyle(fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'Indtast maskin nr...',
                                    ),
                                    onChanged: (value) => setDialogState(() => _maskinNr = value),
                                  ),
                                  const SizedBox(height: 16),

                                  const Text('Pris per dag (DKK)', style: TextStyle(fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'Indtast pris...',
                                    ),
                                    onChanged: (value) => setDialogState(() => _prisPrDag = double.tryParse(value) ?? 0),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Custom text for Andet
                                if (_selectedType == 'Andet') ...[
                                  const Text('Beskrivelse *', style: TextStyle(fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'Indtast beskrivelse af udstyret',
                                    ),
                                    onChanged: (value) => setDialogState(() => _customText = value),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Quantity
                                const Text('Antal', style: TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                  controller: TextEditingController(text: _quantity.toString()),
                                  onChanged: (value) => setDialogState(() => _quantity = int.tryParse(value) ?? 1),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Effekt for Varmeblaeser and Kaloriferer
                              if (_hasVariableEffect(_selectedType)) ...[
                                const Text('Effekt (kW)', style: TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Indtast effekt...',
                                  ),
                                  onChanged: (value) => setDialogState(() => _effekt = double.tryParse(value) ?? 0),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Specifications/notes
                              const Text('Eventuelle specifikationer eller noter', style: TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              TextField(
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Eventuelle specifikationer eller noter',
                                ),
                                onChanged: (value) => setDialogState(() => _specifications = value),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Actions
                  if (_selectedCategory != null && _selectedType != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Annuller'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addEquipment,
                            child: const Text('Tilfoej udstyr'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEquipmentLogsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Equipment Log',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _equipmentLogs.isEmpty
                    ? const Center(
                        child: Text('Ingen equipment logs fundet', style: TextStyle(color: Colors.grey)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _equipmentLogs.length,
                        itemBuilder: (context, index) {
                          final log = _equipmentLogs[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(log.category, style: const TextStyle(fontSize: 12)),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      const SizedBox(width: 8),
                                      Chip(
                                        label: Text(log.action, style: const TextStyle(fontSize: 12)),
                                        backgroundColor: log.action == 'tilfoej'
                                            ? AppColors.success.withValues(alpha: 0.2)
                                            : AppColors.error.withValues(alpha: 0.2),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      const Spacer(),
                                      Text(
                                        _formatDate(log.timestamp),
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (log.note != null)
                                    Text(log.note!, style: const TextStyle(fontWeight: FontWeight.w500)),
                                  if (log.data['maskinNr'] != null)
                                    Text('Maskin Nr: ${log.data['maskinNr']}'),
                                  if (log.data['blokNavn'] != null)
                                    Text('Blok: ${log.data['blokNavn']}'),
                                  Text('Af: ${log.user}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Header with actions
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Udstyrsoversigt',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_filteredEquipment.length} udstyr vist',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _showEquipmentLogsDialog,
                icon: const Icon(Icons.history),
                label: Text('Log (${_equipmentLogs.length})'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showAddEquipmentDialog,
                icon: const Icon(Icons.add),
                label: const Text('Tilfoej udstyr'),
              ),
            ],
          ),
        ),

        // Standardized Filter Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilterBar(
            filters: [
              FilterConfig(
                id: 'search',
                label: 'Søg',
                type: FilterType.search,
                hint: 'Søg i udstyr...',
              ),
              FilterConfig(
                id: 'status',
                label: 'Status',
                type: FilterType.dropdown,
                options: [
                  FilterOption(value: 'aktiv', label: 'Aktiv', color: AppColors.success),
                  FilterOption(value: 'nedtaget', label: 'Nedtaget', color: AppColors.error),
                ],
                allOptionLabel: 'Alle statusser',
              ),
              FilterConfig(
                id: 'category',
                label: 'Kategori',
                type: FilterType.dropdown,
                options: _getUniqueCategories()
                    .map((cat) => FilterOption(value: cat, label: cat))
                    .toList(),
                allOptionLabel: 'Alle kategorier',
              ),
              FilterConfig(
                id: 'blok',
                label: 'Blok',
                type: FilterType.dropdown,
                options: [
                  const FilterOption(value: 'ingen', label: 'Ingen blok'),
                  ..._blokke.map((blok) => FilterOption(value: blok.id, label: blok.navn)),
                ],
                allOptionLabel: 'Alle blokke',
              ),
            ],
            values: {
              'search': _searchTerm,
              'status': _statusFilter == 'all' ? 'alle' : _statusFilter,
              'category': _categoryFilter == 'all' ? 'alle' : _categoryFilter,
              'blok': _blokFilter == 'all' ? 'alle' : _blokFilter,
            },
            onFilterChanged: (filterId, value) {
              setState(() {
                switch (filterId) {
                  case 'search':
                    _searchTerm = value?.toString() ?? '';
                    break;
                  case 'status':
                    _statusFilter = value == 'alle' ? 'all' : value?.toString() ?? 'all';
                    break;
                  case 'category':
                    _categoryFilter = value == 'alle' ? 'all' : value?.toString() ?? 'all';
                    break;
                  case 'blok':
                    _blokFilter = value == 'alle' ? 'all' : value?.toString() ?? 'all';
                    break;
                }
                _applyFilters();
              });
            },
            onReset: () {
              setState(() {
                _searchTerm = '';
                _statusFilter = 'all';
                _categoryFilter = 'all';
                _blokFilter = 'all';
                _applyFilters();
              });
            },
          ),
        ),

        // Results Header
        FilterResultsHeader(
          resultCount: _filteredEquipment.length,
          itemLabel: 'udstyr',
          activeFilters: {
            if (_statusFilter != 'all') 'status': _statusFilter,
            if (_categoryFilter != 'all') 'category': _categoryFilter,
            if (_blokFilter != 'all') 'blok': _blokke.firstWhere((b) => b.id == _blokFilter, orElse: () => _blokke.first).navn,
          },
          onReset: (_statusFilter != 'all' || _categoryFilter != 'all' || _blokFilter != 'all' || _searchTerm.isNotEmpty)
              ? () {
                  setState(() {
                    _searchTerm = '';
                    _statusFilter = 'all';
                    _categoryFilter = 'all';
                    _blokFilter = 'all';
                    _applyFilters();
                  });
                }
              : null,
        ),

        const SizedBox(height: 8),

        // Equipment list or empty state
        Expanded(
          child: _filteredEquipment.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        _equipment.isEmpty
                            ? 'Intet udstyr tilfojet endnu'
                            : 'Ingen udstyr matcher de valgte filtre',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _showAddEquipmentDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Tilfoej foerste udstyr'),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 350,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _filteredEquipment.length,
                  itemBuilder: (context, index) {
                    final eq = _filteredEquipment[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                Icon(_getCategoryIcon(eq.category), color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        eq.category,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Text(
                                        eq.type,
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(_getStatusIcon(eq.status), color: _getStatusColor(eq.status), size: 20),
                              ],
                            ),

                            if (eq.maskinNr != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Nr: ${eq.maskinNr}',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
                              ),
                            ],

                            if (eq.blokNavn != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.apartment, size: 14, color: Colors.purple),
                                  const SizedBox(width: 4),
                                  Text(
                                    eq.blokNavn!,
                                    style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.w500, fontSize: 13),
                                  ),
                                ],
                              ),
                            ],

                            const Spacer(),

                            // Details
                            Row(
                              children: [
                                const Icon(Icons.inventory_2, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text('Antal: ${eq.quantity}', style: const TextStyle(fontSize: 13)),
                              ],
                            ),

                            if (eq.prisPrDag != null && eq.prisPrDag! > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${eq.prisPrDag!.toStringAsFixed(0)} DKK/dag',
                                style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                            ],

                            if (eq.effekt != null && eq.effekt! > 0) ...[
                              const SizedBox(height: 4),
                              Text('Effekt: ${eq.effekt} kW', style: const TextStyle(fontSize: 13)),
                            ],

                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'Opsat: ${_formatDate(eq.setupDate).split(' ').first}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),

                            if (eq.takedownDate != null) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.cancel, size: 14, color: AppColors.error),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Nedtaget: ${_formatDate(eq.takedownDate!).split(' ').first}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.error),
                                  ),
                                ],
                              ),
                            ],

                            const Spacer(),

                            // Status dropdown
                            DropdownButtonFormField<String>(
                              value: eq.status,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                border: const OutlineInputBorder(),
                                fillColor: _getStatusColor(eq.status).withValues(alpha: 0.1),
                                filled: true,
                              ),
                              items: const [
                                DropdownMenuItem(value: 'aktiv', child: Text('Aktiv')),
                                DropdownMenuItem(value: 'nedtaget', child: Text('Nedtaget')),
                              ],
                              onChanged: eq.status == 'nedtaget'
                                  ? null
                                  : (value) {
                                      if (value != null && value != eq.status) {
                                        _changeStatus(eq, value);
                                      }
                                    },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
