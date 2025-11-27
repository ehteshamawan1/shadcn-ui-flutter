import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';
import '../models/affugter.dart';
import '../models/app_setting.dart';
import '../providers/theme_provider.dart';
import '../widgets/filter_widget.dart';
import 'package:uuid/uuid.dart';

class AffugtereScreen extends StatefulWidget {
  const AffugtereScreen({super.key});

  @override
  State<AffugtereScreen> createState() => _AffugtereScreenState();
}

class _AffugtereScreenState extends State<AffugtereScreen> {
  final _dbService = DatabaseService();
  final _settingsService = SettingsService();
  List<Affugter> _affugtere = [];
  String _searchQuery = '';
  String _filterStatus = 'alle';
  String _filterType = 'alle';
  String _filterNfc = 'alle'; // 'alle', 'har_nfc', 'mangler_nfc'
  final TextEditingController _searchController = TextEditingController();

  // Dynamic dropdown options from settings
  List<DropdownOption> _typeOptions = [];
  List<DropdownOption> _brandOptions = [];
  List<DropdownOption> _statusOptions = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAffugtere();
  }

  Future<void> _loadSettings() async {
    await _settingsService.init();
    setState(() {
      _typeOptions = _settingsService.getDropdownOptions(SettingCategory.affugterTypes);
      _brandOptions = _settingsService.getDropdownOptions(SettingCategory.affugterBrands);
      _statusOptions = _settingsService.getDropdownOptions(SettingCategory.equipmentStatus);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadAffugtere() {
    setState(() {
      _affugtere = _dbService.getAllAffugtere();
      _affugtere.sort((a, b) => a.nr.compareTo(b.nr));
    });
  }

  List<Affugter> get _filteredAffugtere {
    var filtered = _affugtere;

    // Filter by status
    if (_filterStatus != 'alle') {
      filtered = filtered.where((a) => a.status == _filterStatus).toList();
    }

    // Filter by type
    if (_filterType != 'alle') {
      if (_filterType == 'udtørring') {
        filtered = filtered.where((a) {
          final type = a.type.toLowerCase();
          return type == 'adsorption' || type == 'kondens';
        }).toList();
      } else {
        filtered = filtered.where((a) => a.type.toLowerCase() == _filterType).toList();
      }
    }

    // Filter by NFC
    if (_filterNfc == 'har_nfc') {
      // Has NFC if nr follows pattern like "1-00001"
      filtered = filtered.where((a) => a.nr.contains('-') && a.nr.split('-').length == 2).toList();
    } else if (_filterNfc == 'mangler_nfc') {
      // Missing NFC if nr doesn't follow NFC pattern
      filtered = filtered.where((a) => !a.nr.contains('-') || a.nr.split('-').length != 2).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((a) =>
        a.nr.toLowerCase().contains(query) ||
        a.maerke.toLowerCase().contains(query) ||
        (a.model?.toLowerCase().contains(query) ?? false) ||
        a.type.toLowerCase().contains(query)
      ).toList();
    }

    return filtered;
  }

  bool _hasNfcTag(Affugter a) {
    return a.nr.contains('-') && a.nr.split('-').length == 2;
  }

  /// Check if a tag number already exists and return the device that has it
  Affugter? _findExistingTag(String tagNumber) {
    try {
      return _affugtere.firstWhere((a) => a.nr == tagNumber);
    } catch (_) {
      return null;
    }
  }

  void _showAddDialog() {
    final nrController = TextEditingController();
    String selectedType = 'adsorption';
    String selectedMaerke = 'Master';
    final modelController = TextEditingController();
    final serieController = TextEditingController();
    final noteController = TextEditingController();
    String selectedStatus = 'hjemme';
    String? tagError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.air,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Tilføj udstyr'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NFC Tag section
                  Text(
                    'NFC Tag Nummer',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nrController,
                    decoration: InputDecoration(
                      labelText: 'Tag nummer',
                      hintText: 'Scan eller indtast tag nummer',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      errorText: tagError,
                      prefixIcon: const Icon(Icons.tag),
                    ),
                    onChanged: (value) {
                      final existing = _findExistingTag(value);
                      setDialogState(() {
                        if (existing != null) {
                          tagError = 'Tag bruges af: ${existing.maerke} ${existing.model ?? ''} (${existing.status})';
                        } else {
                          tagError = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.nfc, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Du kan scanne et NFC-tag for automatisk udfyldning.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Equipment details section
                  Text(
                    'Udstyr Detaljer',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: _typeOptions.map((opt) => DropdownMenuItem(
                            value: opt.value,
                            child: Text(opt.label),
                          )).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => selectedType = value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedMaerke,
                          decoration: const InputDecoration(
                            labelText: 'Mærke',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: _brandOptions.map((opt) => DropdownMenuItem(
                            value: opt.value,
                            child: Text(opt.label),
                          )).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => selectedMaerke = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: modelController,
                          decoration: const InputDecoration(
                            labelText: 'Model',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: serieController,
                          decoration: const InputDecoration(
                            labelText: 'Serienummer',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _statusOptions.map((opt) => DropdownMenuItem(
                      value: opt.value,
                      child: Text(opt.label),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedStatus = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Noter',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuller'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Tilføj'),
              onPressed: tagError != null ? null : () async {
                if (nrController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tag nummer er påkrævet')),
                  );
                  return;
                }

                // Final duplicate check
                final existing = _findExistingTag(nrController.text);
                if (existing != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tag ${nrController.text} bruges allerede af ${existing.maerke} ${existing.model ?? ''}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final now = DateTime.now().toIso8601String();
                final affugter = Affugter(
                  id: const Uuid().v4(),
                  nr: nrController.text,
                  type: selectedType,
                  maerke: selectedMaerke,
                  model: modelController.text.isNotEmpty ? modelController.text : null,
                  serie: serieController.text.isNotEmpty ? serieController.text : null,
                  note: noteController.text.isNotEmpty ? noteController.text : null,
                  status: selectedStatus,
                  createdAt: now,
                  updatedAt: now,
                );

                await _dbService.addAffugter(affugter);
                if (mounted) {
                  Navigator.pop(context);
                  _loadAffugtere();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Affugter ${affugter.nr} tilføjet'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Affugter affugter) {
    final nrController = TextEditingController(text: affugter.nr);
    String selectedType = affugter.type;
    String selectedMaerke = affugter.maerke;
    final modelController = TextEditingController(text: affugter.model ?? '');
    final serieController = TextEditingController(text: affugter.serie ?? '');
    final noteController = TextEditingController(text: affugter.note ?? '');
    String selectedStatus = affugter.status;
    String? tagError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.edit,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Rediger Affugter'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nrController,
                    decoration: InputDecoration(
                      labelText: 'NFC Tag Nummer',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      errorText: tagError,
                    ),
                    onChanged: (value) {
                      if (value != affugter.nr) {
                        final existing = _findExistingTag(value);
                        setDialogState(() {
                          if (existing != null) {
                            tagError = 'Tag bruges af: ${existing.maerke} ${existing.model ?? ''}';
                          } else {
                            tagError = null;
                          }
                        });
                      } else {
                        setDialogState(() => tagError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _getValidValue(selectedType, _typeOptions),
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: _typeOptions.map((opt) => DropdownMenuItem(
                            value: opt.value,
                            child: Text(opt.label),
                          )).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => selectedType = value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _getValidValue(selectedMaerke, _brandOptions),
                          decoration: const InputDecoration(
                            labelText: 'Mærke',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: _brandOptions.map((opt) => DropdownMenuItem(
                            value: opt.value,
                            child: Text(opt.label),
                          )).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => selectedMaerke = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: modelController,
                          decoration: const InputDecoration(
                            labelText: 'Model',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: serieController,
                          decoration: const InputDecoration(
                            labelText: 'Serienummer',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _getValidValue(selectedStatus, _statusOptions),
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _statusOptions.map((opt) => DropdownMenuItem(
                      value: opt.value,
                      child: Text(opt.label),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedStatus = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Noter',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuller'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Gem'),
              onPressed: tagError != null ? null : () async {
                // Check for duplicate if tag changed
                if (nrController.text != affugter.nr) {
                  final existing = _findExistingTag(nrController.text);
                  if (existing != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tag ${nrController.text} bruges allerede'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                }

                final now = DateTime.now().toIso8601String();
                final updated = Affugter(
                  id: affugter.id,
                  nr: nrController.text,
                  type: selectedType,
                  maerke: selectedMaerke,
                  model: modelController.text.isNotEmpty ? modelController.text : null,
                  serie: serieController.text.isNotEmpty ? serieController.text : null,
                  note: noteController.text.isNotEmpty ? noteController.text : null,
                  status: selectedStatus,
                  currentSagId: affugter.currentSagId,
                  createdAt: affugter.createdAt,
                  updatedAt: now,
                );

                await _dbService.updateAffugter(updated);
                if (mounted) {
                  Navigator.pop(context);
                  _loadAffugtere();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Affugter opdateret'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Get valid value from options list, fallback to first option or 'Andet' if not found
  String? _getValidValue(String value, List<DropdownOption> options) {
    if (options.isEmpty) return null;
    final hasValue = options.any((opt) => opt.value == value);
    if (hasValue) return value;
    // Try to find 'Andet' as fallback
    final andetOption = options.firstWhere(
      (opt) => opt.value.toLowerCase() == 'andet',
      orElse: () => options.first,
    );
    return andetOption.value;
  }

  void _deleteAffugter(Affugter affugter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slet affugter'),
        content: Text('Er du sikker på at du vil slette ${affugter.maerke} - ${affugter.nr}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuller'),
          ),
          FilledButton(
            onPressed: () async {
              await _dbService.deleteAffugter(affugter.id);
              if (mounted) {
                Navigator.pop(context);
                _loadAffugtere();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Affugter slettet'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Slet'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    return AppColors.getEquipmentStatusColor(status);
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'hjemme':
        return Icons.home;
      case 'udlejet':
        return Icons.local_shipping;
      case 'defekt':
        return Icons.warning;
      default:
        return Icons.help_outline;
    }
  }

  Map<String, int> get _statusCounts {
    return {
      'hjemme': _affugtere.where((a) => a.status == 'hjemme').length,
      'udlejet': _affugtere.where((a) => a.status == 'udlejet').length,
      'defekt': _affugtere.where((a) => a.status == 'defekt').length,
    };
  }

  Map<String, int> get _typeCounts {
    final adsorption = _affugtere.where((a) => a.type.toLowerCase() == 'adsorption').length;
    final kondens = _affugtere.where((a) => a.type.toLowerCase() == 'kondens').length;
    final varme = _affugtere.where((a) => a.type.toLowerCase() == 'varme').length;
    return {
      'adsorption': adsorption,
      'kondens': kondens,
      'varme': varme,
      'udtørring': adsorption + kondens,
    };
  }

  Map<String, int> get _nfcCounts {
    return {
      'har_nfc': _affugtere.where((a) => _hasNfcTag(a)).length,
      'mangler_nfc': _affugtere.where((a) => !_hasNfcTag(a)).length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final counts = _statusCounts;
    final typeCounts = _typeCounts;
    final nfcCounts = _nfcCounts;
    final filtered = _filteredAffugtere;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Udstyr Oversigt'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Standardized Summary Cards
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SummaryCardsFilter(
              options: [
                FilterOption(
                  value: 'hjemme',
                  label: 'Hjemme',
                  count: counts['hjemme'] ?? 0,
                  icon: Icons.home,
                  color: _getStatusColor('hjemme'),
                ),
                FilterOption(
                  value: 'udlejet',
                  label: 'Udlejet',
                  count: counts['udlejet'] ?? 0,
                  icon: Icons.local_shipping,
                  color: _getStatusColor('udlejet'),
                ),
                FilterOption(
                  value: 'defekt',
                  label: 'Defekt',
                  count: counts['defekt'] ?? 0,
                  icon: Icons.warning,
                  color: _getStatusColor('defekt'),
                ),
              ],
              selectedValue: _filterStatus,
              onChanged: (value) => setState(() => _filterStatus = value),
              totalCount: _affugtere.length,
              allLabel: 'Total',
            ),
          ),

          // Standardized Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: FilterBar(
              filters: [
                FilterConfig(
                  id: 'search',
                  label: 'Søg',
                  type: FilterType.search,
                  hint: 'Søg efter tag, mærke, model...',
                ),
                FilterConfig(
                  id: 'type',
                  label: 'Type',
                  type: FilterType.dropdown,
                  options: [
                    FilterOption(value: 'udtørring', label: 'Udtørring', count: typeCounts['udtørring']),
                    FilterOption(value: 'adsorption', label: 'Adsorption', count: typeCounts['adsorption']),
                    FilterOption(value: 'kondens', label: 'Kondens', count: typeCounts['kondens']),
                    FilterOption(value: 'varme', label: 'Varme', count: typeCounts['varme']),
                  ],
                  allOptionLabel: 'Alle typer',
                ),
                FilterConfig(
                  id: 'nfc',
                  label: 'NFC',
                  type: FilterType.tristate,
                  options: [
                    FilterOption(value: 'har_nfc', label: 'Har NFC', count: nfcCounts['har_nfc'], icon: Icons.nfc),
                    FilterOption(value: 'mangler_nfc', label: 'Mangler NFC', count: nfcCounts['mangler_nfc'], icon: Icons.nfc),
                  ],
                ),
              ],
              values: {
                'search': _searchQuery,
                'type': _filterType,
                'nfc': _filterNfc,
              },
              onFilterChanged: (filterId, value) {
                setState(() {
                  switch (filterId) {
                    case 'search':
                      _searchQuery = value?.toString() ?? '';
                      _searchController.text = _searchQuery;
                      break;
                    case 'type':
                      _filterType = value?.toString() ?? 'alle';
                      break;
                    case 'nfc':
                      _filterNfc = value?.toString() ?? 'alle';
                      break;
                  }
                });
              },
              onReset: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                  _filterStatus = 'alle';
                  _filterType = 'alle';
                  _filterNfc = 'alle';
                });
              },
            ),
          ),

          // Standardized Results Header
          FilterResultsHeader(
            resultCount: filtered.length,
            itemLabel: 'udstyr',
            activeFilters: {
              if (_filterStatus != 'alle') 'status': _filterStatus,
              if (_filterType != 'alle') 'type': _filterType,
              if (_filterNfc != 'alle') 'nfc': _filterNfc == 'har_nfc' ? 'med NFC' : 'uden NFC',
            },
            onReset: (_filterStatus != 'alle' || _filterType != 'alle' || _filterNfc != 'alle' || _searchQuery.isNotEmpty)
                ? () => setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                      _filterStatus = 'alle';
                      _filterType = 'alle';
                      _filterNfc = 'alle';
                    })
                : null,
          ),
          const SizedBox(height: 8),

          // List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.air, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _filterStatus != 'alle'
                              ? 'Ingen resultater'
                              : 'Ingen affugtere',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final affugter = filtered[index];
                      return _buildAffugterCard(affugter);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tilføj'),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    int count,
    Color color,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
    double maxWidth,
  ) {
    // Calculate card width based on available space
    final cardWidth = (maxWidth - 36) / 4; // 4 cards with 12px spacing
    final minWidth = 120.0;
    final actualWidth = cardWidth.clamp(minWidth, 200.0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: actualWidth,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAffugterCard(Affugter affugter) {
    final statusColor = _getStatusColor(affugter.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEditDialog(affugter),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getStatusIcon(affugter.status),
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            affugter.nr,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            affugter.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // NFC badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _hasNfcTag(affugter)
                                ? AppColors.success.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.nfc,
                                size: 12,
                                color: _hasNfcTag(affugter) ? AppColors.success : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _hasNfcTag(affugter) ? 'NFC' : 'Mangler',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _hasNfcTag(affugter) ? AppColors.success : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${affugter.maerke}${affugter.model != null ? ' ${affugter.model}' : ''}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Type: ${affugter.type}${affugter.serie != null ? ' • Serie: ${affugter.serie}' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Rediger'),
                      ],
                    ),
                    onTap: () => Future.delayed(
                      const Duration(milliseconds: 300),
                      () => _showEditDialog(affugter),
                    ),
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Text('Slet', style: TextStyle(color: Colors.red[700])),
                      ],
                    ),
                    onTap: () => Future.delayed(
                      const Duration(milliseconds: 300),
                      () => _deleteAffugter(affugter),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
