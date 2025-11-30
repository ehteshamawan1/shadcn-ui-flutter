import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/export_service.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../providers/theme_provider.dart';
import '../models/sag.dart';
import '../widgets/filter_widget.dart';

class SagerScreen extends StatefulWidget {
  const SagerScreen({super.key});

  @override
  State<SagerScreen> createState() => _SagerScreenState();
}

class _SagerScreenState extends State<SagerScreen> {
  final _dbService = DatabaseService();
  final _exportService = ExportService();
  final _authService = AuthService();
  final _syncService = SyncService();

  final TextEditingController _searchController = TextEditingController();
  List<Sag> _allSager = [];
  List<Sag> _filteredSager = [];
  bool _showArchived = false;
  bool _isSelectionMode = false;
  final Set<String> _selectedSagerIds = {};
  String _selectedType = 'alle';
  String _selectedRegion = 'alle';
  String _searchQuery = '';
  final List<String> _typeOptions = ['alle', 'udtørring', 'varme', 'begge'];
  final List<String> _regionOptions = ['alle', 'sjælland', 'fyn', 'jylland'];

  @override
  void initState() {
    super.initState();
    _loadSager();
    _checkSyncStatus();
  }

  void _checkSyncStatus() {
    // Check sync status periodically until complete
    if (!_syncService.isInitialSyncComplete) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {});
          _checkSyncStatus();
        }
      });
    }
  }

  void _loadSager() {
    final allSager = _dbService.getAllSager();
    allSager.sort((a, b) => b.opdateretDato.compareTo(a.opdateretDato));

    setState(() {
      _allSager = allSager;
    });

    _applyFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleArchiveFilter() {
    setState(() {
      _showArchived = !_showArchived;
      _isSelectionMode = false;
      _selectedSagerIds.clear();
    });
    _loadSager();
  }

  List<Sag> _getArchiveAndSearchFiltered() {
    final archiveFiltered = _showArchived
        ? _allSager.where((s) => s.arkiveret == true)
        : _allSager.where((s) => s.aktiv);

    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return archiveFiltered.toList();
    }

    return archiveFiltered.where((s) {
      final address = s.adresse.toLowerCase();
      final sagsnr = s.sagsnr.toLowerCase();
      final byggeleder = s.byggeleder.toLowerCase();
      final bygherre = s.bygherre?.toLowerCase() ?? '';

      return address.contains(query) ||
          sagsnr.contains(query) ||
          byggeleder.contains(query) ||
          bygherre.contains(query);
    }).toList();
  }

  String _normalizeType(String? value) => value?.toLowerCase().trim() ?? '';
  String _normalizeRegion(String? value) => value?.toLowerCase().trim() ?? '';

  void _applyFilters() {
    final baseList = _getArchiveAndSearchFiltered();

    final typeFiltered = _selectedType == 'alle'
        ? baseList
        : baseList
            .where((s) => _normalizeType(s.sagType) == _selectedType)
            .toList();

    final regionFiltered = _selectedRegion == 'alle'
        ? typeFiltered
        : typeFiltered
            .where((s) => _normalizeRegion(s.region) == _selectedRegion)
            .toList();

    regionFiltered.sort((a, b) => b.opdateretDato.compareTo(a.opdateretDato));

    setState(() {
      _filteredSager = regionFiltered;
      _selectedSagerIds.removeWhere(
        (id) => !_filteredSager.any((s) => s.id == id),
      );
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedSagerIds.clear();
    });
  }

  void _toggleSagSelection(String sagId) {
    setState(() {
      if (_selectedSagerIds.contains(sagId)) {
        _selectedSagerIds.remove(sagId);
      } else {
        _selectedSagerIds.add(sagId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedSagerIds.length == _filteredSager.length) {
        _selectedSagerIds.clear();
      } else {
        _selectedSagerIds.addAll(_filteredSager.map((s) => s.id));
      }
    });
  }

  Future<void> _exportToCSV({bool activeOnly = true}) async {
    try {
      final csv = activeOnly
          ? _exportService.exportAktiveSagerToCSV()
          : _exportService.exportAfsluttedeSagerToCSV();

      final filename = activeOnly
          ? 'aktive_sager_${DateTime.now().millisecondsSinceEpoch}.csv'
          : 'afsluttede_sager_${DateTime.now().millisecondsSinceEpoch}.csv';

      _exportService.downloadCSVFile(csv, filename);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eksporteret ${activeOnly ? "aktive" : "afsluttede"} sager til CSV'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fejl ved eksport: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportSelectedToEconomic() async {
    if (_selectedSagerIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vælg mindst én sag at eksportere'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Economic API integration is Phase 3 (Task 3.2)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Economic-eksport kommer i næste version'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _showExportMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Eksporter aktive sager til CSV'),
              onTap: () {
                Navigator.pop(context);
                _exportToCSV(activeOnly: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Eksporter afsluttede sager til CSV'),
              onTap: () {
                Navigator.pop(context);
                _exportToCSV(activeOnly: false);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Vælg sager til e-conomic eksport'),
              onTap: () {
                Navigator.pop(context);
                _toggleSelectionMode();
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aktiv':
      case 'igangværende':
        return Colors.green;
      case 'afsluttet':
      case 'completed':
        return Colors.blue;
      case 'paused':
      case 'pauseret':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatOptionLabel(String value) {
    if (value == 'alle') return 'Alle';
    if (value.isEmpty) return 'Ukendt';
    return value[0].toUpperCase() + value.substring(1);
  }

  String _displaySagType(String? value) {
    final normalized = _normalizeType(value);
    switch (normalized) {
      case 'udtørring':
        return 'Udtørring';
      case 'varme':
        return 'Varme';
      case 'begge':
        return 'Begge';
      default:
        return value ?? 'Ukendt';
    }
  }

  String _displayRegion(String? value) {
    final normalized = _normalizeRegion(value);
    switch (normalized) {
      case 'sjælland':
        return 'Sjælland';
      case 'fyn':
        return 'Fyn';
      case 'jylland':
        return 'Jylland';
      default:
        return value ?? 'Ukendt';
    }
  }

  Map<String, int> _buildTypeCounts(List<Sag> baseList) {
    final counts = {for (final type in _typeOptions.where((t) => t != 'alle')) type: 0};
    for (final sag in baseList) {
      final normalized = _normalizeType(sag.sagType);
      if (counts.containsKey(normalized)) {
        counts[normalized] = counts[normalized]! + 1;
      }
    }
    return counts;
  }

  Map<String, int> _buildRegionCounts(List<Sag> baseList) {
    final counts = {for (final region in _regionOptions.where((r) => r != 'alle')) region: 0};
    for (final sag in baseList) {
      final normalized = _normalizeRegion(sag.region);
      if (counts.containsKey(normalized)) {
        counts[normalized] = counts[normalized]! + 1;
      }
    }
    return counts;
  }

  Color _getTypeColor(String type) {
    return AppColors.getSagTypeColor(type);
  }

  Color _getRegionColor(String region) {
    return AppColors.getRegionColor(region);
  }

  List<FilterOption> _getTypeFilterOptions(Map<String, int> typeCounts) {
    return [
      FilterOption(
        value: 'udtørring',
        label: 'Udtørring',
        count: typeCounts['udtørring'] ?? 0,
        color: _getTypeColor('udtørring'),
      ),
      FilterOption(
        value: 'varme',
        label: 'Varme',
        count: typeCounts['varme'] ?? 0,
        color: _getTypeColor('varme'),
      ),
      FilterOption(
        value: 'begge',
        label: 'Begge',
        count: typeCounts['begge'] ?? 0,
        color: _getTypeColor('begge'),
      ),
    ];
  }

  List<FilterOption> _getRegionFilterOptions(Map<String, int> regionCounts) {
    return [
      FilterOption(
        value: 'sjælland',
        label: 'Sjælland',
        count: regionCounts['sjælland'] ?? 0,
        color: _getRegionColor('sjælland'),
      ),
      FilterOption(
        value: 'fyn',
        label: 'Fyn',
        count: regionCounts['fyn'] ?? 0,
        color: _getRegionColor('fyn'),
      ),
      FilterOption(
        value: 'jylland',
        label: 'Jylland',
        count: regionCounts['jylland'] ?? 0,
        color: _getRegionColor('jylland'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _authService.currentUser?.role == 'admin';
    final baseAfterSearch = _getArchiveAndSearchFiltered();
    final typeCountBase = _selectedRegion == 'alle'
        ? baseAfterSearch
        : baseAfterSearch
            .where((s) => _normalizeRegion(s.region) == _selectedRegion)
            .toList();
    final regionCountBase = _selectedType == 'alle'
        ? baseAfterSearch
        : baseAfterSearch
            .where((s) => _normalizeType(s.sagType) == _selectedType)
            .toList();

    final typeCounts = _buildTypeCounts(typeCountBase);
    final regionCounts = _buildRegionCounts(regionCountBase);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSelectionMode
              ? '${_selectedSagerIds.length} valgt'
              : (_showArchived ? 'Arkiverede Sager' : 'Aktive Sager'),
        ),
        elevation: 0,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: Icon(
                _selectedSagerIds.length == _filteredSager.length
                    ? Icons.deselect
                    : Icons.select_all,
              ),
              onPressed: _selectAll,
              tooltip: 'Vælg alle',
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _exportSelectedToEconomic,
              tooltip: 'Eksporter til e-conomic',
            ),
          ] else ...[
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: _showExportMenu,
                tooltip: 'Eksporter',
              ),
            IconButton(
              icon: Icon(_showArchived ? Icons.unarchive : Icons.archive),
              onPressed: _toggleArchiveFilter,
              tooltip: _showArchived ? 'Vis aktive' : 'Vis arkiverede',
            ),
          ],
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Standardized Filter Bar
            FilterBar(
              filters: [
                FilterConfig(
                  id: 'search',
                  label: 'Søg',
                  type: FilterType.search,
                  hint: 'Søg efter sagsnr, adresse, byggeleder...',
                ),
                FilterConfig(
                  id: 'type',
                  label: 'Type',
                  type: FilterType.dropdown,
                  options: _getTypeFilterOptions(typeCounts),
                  allOptionLabel: 'Alle typer',
                ),
                FilterConfig(
                  id: 'region',
                  label: 'Region',
                  type: FilterType.dropdown,
                  options: _getRegionFilterOptions(regionCounts),
                  allOptionLabel: 'Alle regioner',
                ),
              ],
              values: {
                'search': _searchQuery,
                'type': _selectedType,
                'region': _selectedRegion,
              },
              onFilterChanged: (filterId, value) {
                setState(() {
                  switch (filterId) {
                    case 'search':
                      _searchQuery = value?.toString() ?? '';
                      _searchController.text = _searchQuery;
                      break;
                    case 'type':
                      _selectedType = value?.toString() ?? 'alle';
                      break;
                    case 'region':
                      _selectedRegion = value?.toString() ?? 'alle';
                      break;
                  }
                });
                _applyFilters();
              },
              onReset: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                  _selectedType = 'alle';
                  _selectedRegion = 'alle';
                });
                _applyFilters();
              },
            ),
            const SizedBox(height: 12),

            // Summary Cards
            SummaryCardsFilter(
              options: [
                ..._getTypeFilterOptions(typeCounts),
                ..._getRegionFilterOptions(regionCounts),
              ],
              selectedValue: _selectedType != 'alle' ? _selectedType : (_selectedRegion != 'alle' ? _selectedRegion : 'alle'),
              onChanged: (value) {
                setState(() {
                  // Check if it's a type or region value
                  if (['udtørring', 'varme', 'begge'].contains(value)) {
                    _selectedType = _selectedType == value ? 'alle' : value;
                  } else if (['sjælland', 'fyn', 'jylland'].contains(value)) {
                    _selectedRegion = _selectedRegion == value ? 'alle' : value;
                  } else {
                    _selectedType = 'alle';
                    _selectedRegion = 'alle';
                  }
                });
                _applyFilters();
              },
              showAllCard: false,
            ),
            const SizedBox(height: 8),

            // Results count
            FilterResultsHeader(
              resultCount: _filteredSager.length,
              itemLabel: 'sager',
              activeFilters: {
                if (_selectedType != 'alle') 'type': _displaySagType(_selectedType),
                if (_selectedRegion != 'alle') 'region': _displayRegion(_selectedRegion),
              },
              onReset: (_selectedType != 'alle' || _selectedRegion != 'alle' || _searchQuery.isNotEmpty)
                  ? () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                        _selectedType = 'alle';
                        _selectedRegion = 'alle';
                      });
                      _applyFilters();
                    }
                  : null,
            ),

            // Sager List
            Expanded(
              child: _filteredSager.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _showArchived ? 'Ingen arkiverede sager' : 'Ingen aktive sager',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: _filteredSager.length,
                      itemBuilder: (context, index) {
                        final sag = _filteredSager[index];
                        final isSelected = _selectedSagerIds.contains(sag.id);

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          color: isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              if (_isSelectionMode) {
                                _toggleSagSelection(sag.id);
                              } else {
                                Navigator.of(context).pushNamed('/sager/${sag.id}');
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header row: Checkbox (if selection) + Sagsnr + Status + Archive icon
                                  Row(
                                    children: [
                                      if (_isSelectionMode)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: Checkbox(
                                            value: isSelected,
                                            onChanged: (_) => _toggleSagSelection(sag.id),
                                          ),
                                        ),
                                      Expanded(
                                        child: Text(
                                          sag.sagsnr,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(sag.status),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          sag.status,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            sag.arkiveret == true ? Icons.archive : Icons.folder_open,
                                            size: 20,
                                            color: Colors.grey[500],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Address row
                                      Row(
                                        children: [
                                          Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              sag.adresse,
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Type and Region badges
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          if (sag.sagType != null && sag.sagType!.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _getTypeColor(_normalizeType(sag.sagType)),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                _displaySagType(sag.sagType),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          if (sag.region != null && sag.region!.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _getRegionColor(_normalizeRegion(sag.region)),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                _displayRegion(sag.region),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // Byggeleder and Bygherre sections
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Byggeleder section
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Byggeleder',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    color: Colors.grey[400],
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        sag.byggeleder,
                                                        style: const TextStyle(fontSize: 13),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (sag.byggelederEmail != null && sag.byggelederEmail!.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(Icons.mail_outline, size: 14, color: Colors.grey[500]),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          sag.byggelederEmail!,
                                                          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                                if (sag.byggelederTlf != null && sag.byggelederTlf!.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(Icons.phone_outlined, size: 14, color: Colors.grey[500]),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        sag.byggelederTlf!,
                                                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // Bygherre section
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Bygherre',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    color: Colors.grey[400],
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                if (sag.bygherre != null && sag.bygherre!.isNotEmpty) ...[
                                                  Row(
                                                    children: [
                                                      Icon(Icons.business, size: 14, color: Colors.grey[500]),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          sag.bygherre!,
                                                          style: const TextStyle(fontSize: 13),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ] else ...[
                                                  Text(
                                                    'Ikke angivet',
                                                    style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
                                                  ),
                                                ],
                                                if (sag.cvrNr != null && sag.cvrNr!.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      const SizedBox(width: 20),
                                                      Text(
                                                        'CVR: ${sag.cvrNr}',
                                                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                                if (sag.kundensSagsref != null && sag.kundensSagsref!.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      const SizedBox(width: 20),
                                                      Expanded(
                                                        child: Text(
                                                          'Ref: ${sag.kundensSagsref}',
                                                          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _syncService.isInitialSyncComplete
                  ? () async {
                      final result = await Navigator.of(context).pushNamed('/sager/ny');
                      if (result == true) {
                        _loadSager(); // Reload list after creating new sag
                      }
                    }
                  : null,
              tooltip: _syncService.isInitialSyncComplete
                  ? 'Opret ny sag'
                  : 'Venter på synkronisering...',
              icon: const Icon(Icons.note_add),
              label: Text(_syncService.isInitialSyncComplete ? 'Ny Sag' : 'Synkroniserer...'),
              backgroundColor: _syncService.isInitialSyncComplete ? AppColors.primary : Colors.grey,
            ),
    );
  }
}

class _EconomicConfigDialog extends StatefulWidget {
  @override
  State<_EconomicConfigDialog> createState() => _EconomicConfigDialogState();
}

class _EconomicConfigDialogState extends State<_EconomicConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  final _appSecretController = TextEditingController();
  final _agreementGrantController = TextEditingController();

  @override
  void dispose() {
    _appSecretController.dispose();
    _agreementGrantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('e-conomic Konfiguration'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Indtast dine e-conomic API credentials:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _appSecretController,
              decoration: const InputDecoration(
                labelText: 'App Secret Token',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Dette felt er påkrævet';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _agreementGrantController,
              decoration: const InputDecoration(
                labelText: 'Agreement Grant Token',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Dette felt er påkrævet';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuller'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'appSecretToken': _appSecretController.text,
                'agreementGrantToken': _agreementGrantController.text,
              });
            }
          },
          child: const Text('Fortsæt'),
        ),
      ],
    );
  }
}
