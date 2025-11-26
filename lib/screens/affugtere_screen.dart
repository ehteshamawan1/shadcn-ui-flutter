import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/affugter.dart';
import '../providers/theme_provider.dart';
import 'package:uuid/uuid.dart';

class AffugtereScreen extends StatefulWidget {
  const AffugtereScreen({super.key});

  @override
  State<AffugtereScreen> createState() => _AffugtereScreenState();
}

class _AffugtereScreenState extends State<AffugtereScreen> {
  final _dbService = DatabaseService();
  List<Affugter> _affugtere = [];
  String _searchQuery = '';
  String _filterStatus = 'alle';
  String _filterType = 'alle';
  String _filterNfc = 'alle'; // 'alle', 'har_nfc', 'mangler_nfc'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAffugtere();
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
                          initialValue: selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'adsorption', child: Text('Udtørring - Adsorption')),
                            DropdownMenuItem(value: 'kondens', child: Text('Udtørring - Kondens')),
                            DropdownMenuItem(value: 'varme', child: Text('Varme')),
                          ],
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
                          initialValue: selectedMaerke,
                          decoration: const InputDecoration(
                            labelText: 'Mærke',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Master', child: Text('Master')),
                            DropdownMenuItem(value: 'Fral', child: Text('Fral')),
                            DropdownMenuItem(value: 'Qube', child: Text('Qube')),
                            DropdownMenuItem(value: 'Dantherm', child: Text('Dantherm')),
                            DropdownMenuItem(value: 'Andet', child: Text('Andet')),
                          ],
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
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'hjemme', child: Text('Hjemme')),
                      DropdownMenuItem(value: 'udlejet', child: Text('Udlejet')),
                      DropdownMenuItem(value: 'defekt', child: Text('Defekt')),
                    ],
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
                          value: selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'adsorption', child: Text('Udtørring - Adsorption')),
                            DropdownMenuItem(value: 'kondens', child: Text('Udtørring - Kondens')),
                            DropdownMenuItem(value: 'varme', child: Text('Varme')),
                          ],
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
                          value: _getMaerkeValue(selectedMaerke),
                          decoration: const InputDecoration(
                            labelText: 'Mærke',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Master', child: Text('Master')),
                            DropdownMenuItem(value: 'Fral', child: Text('Fral')),
                            DropdownMenuItem(value: 'Qube', child: Text('Qube')),
                            DropdownMenuItem(value: 'Dantherm', child: Text('Dantherm')),
                            DropdownMenuItem(value: 'Andet', child: Text('Andet')),
                          ],
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
                    items: const [
                      DropdownMenuItem(value: 'hjemme', child: Text('Hjemme')),
                      DropdownMenuItem(value: 'udlejet', child: Text('Udlejet')),
                      DropdownMenuItem(value: 'defekt', child: Text('Defekt')),
                    ],
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

  String _getMaerkeValue(String maerke) {
    const validMaerker = ['Master', 'Fral', 'Qube', 'Dantherm', 'Andet'];
    return validMaerker.contains(maerke) ? maerke : 'Andet';
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
          // Stats cards - Status
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildStatCard(
                      'Hjemme',
                      counts['hjemme'] ?? 0,
                      _getStatusColor('hjemme'),
                      Icons.home,
                      _filterStatus == 'hjemme',
                      () => setState(() => _filterStatus = _filterStatus == 'hjemme' ? 'alle' : 'hjemme'),
                      constraints.maxWidth,
                    ),
                    _buildStatCard(
                      'Udlejet',
                      counts['udlejet'] ?? 0,
                      _getStatusColor('udlejet'),
                      Icons.local_shipping,
                      _filterStatus == 'udlejet',
                      () => setState(() => _filterStatus = _filterStatus == 'udlejet' ? 'alle' : 'udlejet'),
                      constraints.maxWidth,
                    ),
                    _buildStatCard(
                      'Defekt',
                      counts['defekt'] ?? 0,
                      _getStatusColor('defekt'),
                      Icons.warning,
                      _filterStatus == 'defekt',
                      () => setState(() => _filterStatus = _filterStatus == 'defekt' ? 'alle' : 'defekt'),
                      constraints.maxWidth,
                    ),
                    _buildStatCard(
                      'Total',
                      _affugtere.length,
                      Theme.of(context).colorScheme.primary,
                      Icons.air,
                      _filterStatus == 'alle',
                      () => setState(() => _filterStatus = 'alle'),
                      constraints.maxWidth,
                    ),
                  ],
                );
              },
            ),
          ),

          // Filter row - Type dropdown and NFC checkbox
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Type dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(value: 'alle', child: Text('Alle typer (${_affugtere.length})')),
                      DropdownMenuItem(value: 'udtørring', child: Text('Udtørring (${typeCounts['udtørring']})')),
                      DropdownMenuItem(value: 'adsorption', child: Text('Udtørring • Adsorption (${typeCounts['adsorption']})')),
                      DropdownMenuItem(value: 'kondens', child: Text('Udtørring • Kondens (${typeCounts['kondens']})')),
                      DropdownMenuItem(value: 'varme', child: Text('Varme (${typeCounts['varme']})')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _filterType = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // NFC checkbox
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _filterNfc == 'har_nfc',
                      tristate: true,
                      onChanged: (value) {
                        setState(() {
                          if (value == null) {
                            _filterNfc = 'alle';
                          } else if (value) {
                            _filterNfc = 'har_nfc';
                          } else {
                            _filterNfc = 'mangler_nfc';
                          }
                        });
                      },
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_filterNfc == 'alle') {
                            _filterNfc = 'har_nfc';
                          } else if (_filterNfc == 'har_nfc') {
                            _filterNfc = 'mangler_nfc';
                          } else {
                            _filterNfc = 'alle';
                          }
                        });
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.nfc, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            _filterNfc == 'alle'
                                ? 'NFC (${nfcCounts['har_nfc']}/${_affugtere.length})'
                                : _filterNfc == 'har_nfc'
                                    ? 'Har NFC (${nfcCounts['har_nfc']})'
                                    : 'Mangler NFC (${nfcCounts['mangler_nfc']})',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: _filterNfc == 'har_nfc'
                                  ? Colors.green
                                  : _filterNfc == 'mangler_nfc'
                                      ? Colors.orange
                                      : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Søg efter tag, mærke, model...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${filtered.length} udstyr${_filterStatus != 'alle' ? ' ($_filterStatus)' : ''}${_filterType != 'alle' ? ' • $_filterType' : ''}${_filterNfc != 'alle' ? ' • ${_filterNfc == 'har_nfc' ? 'med NFC' : 'uden NFC'}' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (_filterStatus != 'alle' || _filterType != 'alle' || _filterNfc != 'alle') ...[
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Nulstil'),
                    onPressed: () => setState(() {
                      _filterStatus = 'alle';
                      _filterType = 'alle';
                      _filterNfc = 'alle';
                    }),
                  ),
                ],
              ],
            ),
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
