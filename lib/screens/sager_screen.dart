import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/roles_and_features.dart';
import '../models/sag.dart';
import '../providers/theme_provider.dart' as legacy_theme;
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/export_service.dart';
import '../services/notification_manager.dart';
import '../services/sync_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/settings_dropdown.dart';
import '../widgets/theme_toggle.dart';
import '../widgets/ui/ska_badge.dart';
import '../widgets/ui/ska_button.dart';
import '../widgets/ui/ska_card.dart';
import '../widgets/ui/ska_input.dart';

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
  final _notificationManager = NotificationManager();

  final TextEditingController _searchController = TextEditingController();

  List<Sag> _allSager = [];
  List<Sag> _filteredSager = [];
  bool _showArchived = false;
  bool _showOnlyNeedsAttention = false;
  bool _isSelectionMode = false;
  final Set<String> _selectedSagerIds = {};
  String _selectedType = 'alle';
  String _selectedRegion = 'alle';
  String _searchQuery = '';
  bool _isLoading = true;

  int _attentionCount = 0;
  bool _isOnline = true;
  bool _isSyncing = false;
  int _pendingChanges = 0;
  String? _syncError;

  StreamSubscription? _syncSubscription;
  VoidCallback? _notificationUnsubscribe;

  final List<String> _typeOptions = ['alle', 'udtA,rring', 'varme', 'begge'];
  final List<String> _regionOptions = ['alle', 'sjAÝlland', 'fyn', 'jylland'];

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _loadSager();
    _initNotifications();
    _loadSyncStatus();
    _listenSyncStatus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _syncSubscription?.cancel();
    _notificationUnsubscribe?.call();
    super.dispose();
  }

  void _checkAuth() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
    }
  }

  Future<void> _initNotifications() async {
    await _notificationManager.init();
    await _notificationManager.cleanupOldNotifications();

    if (!mounted) return;
    setState(() {
      _attentionCount = _notificationManager.getAttentionCount();
    });

    _notificationUnsubscribe = _notificationManager.subscribe(() {
      if (!mounted) return;
      setState(() {
        _attentionCount = _notificationManager.getAttentionCount();
      });
      _applyFilters();
    });
  }

  Future<void> _loadSyncStatus() async {
    final isOnline = await _syncService.isOnline();
    final pendingChanges = await _syncService.getPendingChangesCount();
    final isSyncing = _syncService.isSyncing;

    if (!mounted) return;
    setState(() {
      _isOnline = isOnline;
      _pendingChanges = pendingChanges;
      _isSyncing = isSyncing;
    });
  }

  void _listenSyncStatus() {
    _syncSubscription = _syncService.syncStatusStream.listen((_) {
      _loadSyncStatus();
    });
  }

  Future<void> _forceSync() async {
    if (!_isOnline || _isSyncing) return;

    setState(() {
      _isSyncing = true;
      _syncError = null;
    });

    try {
      await _syncService.syncNow();
      await _loadSyncStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Synkronisering gennemfA,rt'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _syncError = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Synkronisering fejlede: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  void _loadSager() {
    final allSager = _dbService.getAllSager();
    allSager.sort((a, b) => b.opdateretDato.compareTo(a.opdateretDato));

    setState(() {
      _allSager = allSager;
      _isLoading = false;
    });

    _applyFilters();
  }

  void _applyFilters() {
    final baseList = _showArchived
        ? _allSager.where((s) => s.arkiveret == true).toList()
        : _allSager.where((s) => s.arkiveret != true).toList();

    final attentionIds = _notificationManager.getSagerNeedingAttention().toSet();
    var filtered = baseList;

    if (_showOnlyNeedsAttention) {
      filtered = filtered.where((s) => attentionIds.contains(s.id)).toList();
    }

    if (_selectedType != 'alle') {
      filtered = filtered.where((s) => _normalizeType(s.sagType) == _selectedType).toList();
    }

    if (_selectedRegion != 'alle') {
      filtered = filtered.where((s) => _normalizeRegion(s.region) == _selectedRegion).toList();
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((s) {
        final address = s.adresse.toLowerCase();
        final sagsnr = s.sagsnr.toLowerCase();
        final byggeleder = s.byggeleder.toLowerCase();
        final bygherre = s.bygherre?.toLowerCase() ?? '';
        final ref = s.kundensSagsref?.toLowerCase() ?? '';

        return address.contains(query) ||
            sagsnr.contains(query) ||
            byggeleder.contains(query) ||
            bygherre.contains(query) ||
            ref.contains(query);
      }).toList();
    }

    filtered.sort((a, b) => b.opdateretDato.compareTo(a.opdateretDato));

    setState(() {
      _filteredSager = filtered;
      _selectedSagerIds.removeWhere((id) => !_filteredSager.any((s) => s.id == id));
    });
  }

  String _normalizeType(String? value) => value?.toLowerCase().trim() ?? '';
  String _normalizeRegion(String? value) => value?.toLowerCase().trim() ?? '';

  void _toggleArchiveFilter() {
    setState(() {
      _showArchived = !_showArchived;
      _isSelectionMode = false;
      _selectedSagerIds.clear();
    });
    _applyFilters();
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

      await _exportService.downloadCSVFile(csv, filename);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eksporteret ${activeOnly ? "aktive" : "afsluttede"} sager til CSV'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fejl ved eksport: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _exportSelectedToEconomic() async {
    if (_selectedSagerIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('VAÝlg mindst Acn sag at eksportere'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Economic-eksport kommer i nAÝste version'),
          backgroundColor: AppColors.primary,
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
              title: const Text('VAÝlg sager til e-conomic eksport'),
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

  Future<void> _handleArchiveToggle(Sag sag) async {
    final now = DateTime.now().toIso8601String();
    sag.arkiveret = !(sag.arkiveret ?? false);
    sag.arkiveretDato = sag.arkiveret == true ? now : null;
    sag.aktiv = sag.arkiveret != true;
    sag.opdateretDato = now;
    sag.updatedAt = now;

    await _dbService.updateSag(sag);
    _loadSager();
  }

  Future<void> _handleAcknowledgeSag(Sag sag) async {
    final userName = _authService.currentUser?.name ?? '';

    await _notificationManager.acknowledgeSag(sag.id);
    await _dbService.updateSagAttention(
      sagId: sag.id,
      needsAttention: false,
      acknowledgedBy: userName.isNotEmpty ? userName : null,
      acknowledgedAt: DateTime.now().toIso8601String(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sag markeret som opdateret'),
          backgroundColor: AppColors.success,
        ),
      );
    }

    _applyFilters();
  }

  String _formatDate(String dateString) {
    final parsed = DateTime.tryParse(dateString);
    if (parsed == null) return 'Ukendt dato';
    return DateFormat('dd-MM-yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _authService.isAdmin || _authService.isBogholder;
    final canCreateSager = _authService.hasFeature(AppFeatures.createCases);
    final activeCount = _allSager.where((s) => s.arkiveret != true).length;
    final archivedCount = _allSager.where((s) => s.arkiveret == true).length;
    final attentionIds = _notificationManager.getSagerNeedingAttention().toSet();
    final stats = _buildStats(_filteredSager, attentionIds);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(
            isAdmin: isAdmin,
            canCreateSager: canCreateSager,
            activeCount: activeCount,
            archivedCount: archivedCount,
          ),
          Expanded(
            child: ListView(
              padding: AppSpacing.p4,
              children: [
                if (_syncError != null) _buildSyncErrorBanner(_syncError!),
                if (_isSyncing) _buildSyncingBanner(),
                _buildFilters(),
                if (!_showArchived && stats['total']! > 0) ...[
                  const SizedBox(height: AppSpacing.s4),
                  _buildStatsGrid(stats: stats, showAttention: isAdmin),
                ],
                const SizedBox(height: AppSpacing.s4),
                _buildSagerContent(attentionIds: attentionIds, isAdmin: isAdmin),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _syncService.isInitialSyncComplete
                  ? () async {
                      final result = await Navigator.of(context).pushNamed('/sager/ny');
                      if (result == true) {
                        _loadSager();
                      }
                    }
                  : null,
              tooltip: _syncService.isInitialSyncComplete
                  ? 'Opret ny sag'
                  : 'Venter pA synkronisering...',
              icon: const Icon(Icons.note_add),
              label: Text(_syncService.isInitialSyncComplete ? 'Ny Sag' : 'Synkroniserer...'),
              backgroundColor: _syncService.isInitialSyncComplete ? AppColors.primary : AppColors.gray400,
            ),
    );
  }

  Widget _buildHeader({
    required bool isAdmin,
    required bool canCreateSager,
    required int activeCount,
    required int archivedCount,
  }) {
    final titleText = _isSelectionMode
        ? '${_selectedSagerIds.length} valgt'
        : 'Sager';
    final subtitleText = _showArchived
        ? '${_filteredSager.length} arkiverede sager'
        : '${_filteredSager.length} aktive sager';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: AppShadows.shadowSm,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: AppSpacing.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
          child: Column(
            children: [
              Row(
                children: [
                  SkaButton(
                    variant: ButtonVariant.ghost,
                    size: ButtonSize.icon,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushReplacementNamed('/dashboard');
                      }
                    },
                  ),
                  const SizedBox(width: AppSpacing.s2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          titleText,
                          style: AppTypography.xlBold.copyWith(
                            color: AppColors.foreground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitleText,
                          style: AppTypography.sm.copyWith(
                            color: AppColors.mutedForeground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_attentionCount > 0 && !_showArchived)
                          Text(
                            '$_attentionCount kræver opmærksomhed',
                            style: AppTypography.smMedium.copyWith(
                              color: AppColors.warning,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s2),
              Align(
                alignment: Alignment.centerRight,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (_isSelectionMode) ...[
                        SkaButton(
                          variant: ButtonVariant.ghost,
                          size: ButtonSize.icon,
                          icon: Icon(
                            _selectedSagerIds.length == _filteredSager.length ? Icons.deselect : Icons.select_all,
                            size: 18,
                          ),
                          onPressed: _selectAll,
                        ),
                        const SizedBox(width: AppSpacing.s2),
                        SkaButton(
                          variant: ButtonVariant.outline,
                          size: ButtonSize.sm,
                          icon: const Icon(Icons.send, size: 16),
                          text: 'Eksporter',
                          onPressed: _exportSelectedToEconomic,
                        ),
                      ] else ...[
                        _buildSyncStatus(),
                        const SizedBox(width: AppSpacing.s2),
                        if (isAdmin && _attentionCount > 0) ...[
                          _buildAttentionFilterButton(),
                          const SizedBox(width: AppSpacing.s2),
                        ],
                        const SettingsDropdown(),
                        const SizedBox(width: AppSpacing.s2),
                        const ThemeToggle(),
                        if (isAdmin) ...[
                          const SizedBox(width: AppSpacing.s2),
                          SkaButton(
                            variant: ButtonVariant.ghost,
                            size: ButtonSize.icon,
                            icon: const Icon(Icons.download, size: 18),
                            onPressed: _showExportMenu,
                          ),
                        ],
                        const SizedBox(width: AppSpacing.s2),
                        SkaButton(
                          variant: _showArchived ? ButtonVariant.primary : ButtonVariant.outline,
                          size: ButtonSize.sm,
                          icon: Icon(_showArchived ? Icons.unarchive : Icons.archive, size: 16),
                          text: _showArchived
                              ? 'Vis Aktive ($activeCount)'
                              : 'Vis Arkiverede ($archivedCount)',
                          onPressed: _toggleArchiveFilter,
                        ),
                        if (canCreateSager && !_showArchived) ...[
                          const SizedBox(width: AppSpacing.s2),
                          SkaButton(
                            icon: const Icon(Icons.add, size: 16),
                            text: 'Ny Sag',
                            onPressed: () => Navigator.pushNamed(context, '/sager/ny'),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncStatus() {
    final iconColor = _isOnline ? AppColors.success : AppColors.error;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _isOnline ? Icons.wifi : Icons.wifi_off,
          size: 16,
          color: iconColor,
        ),
        const SizedBox(width: 4),
        Text(
          _isOnline ? 'Online' : 'Offline',
          style: AppTypography.xs.copyWith(
            color: iconColor,
          ),
        ),
        if (_pendingChanges > 0) ...[
          const SizedBox(width: 8),
          SkaBadge(
            text: '$_pendingChanges AÝndringer',
            variant: BadgeVariant.outline,
            small: true,
          ),
        ],
        const SizedBox(width: 4),
        SkaButton(
          variant: ButtonVariant.ghost,
          size: ButtonSize.icon,
          onPressed: _isOnline && !_isSyncing ? _forceSync : null,
          icon: _isSyncing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              : const Icon(Icons.refresh, size: 16),
        ),
      ],
    );
  }

  Widget _buildAttentionFilterButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SkaButton(
          variant: _showOnlyNeedsAttention ? ButtonVariant.primary : ButtonVariant.outline,
          size: ButtonSize.sm,
          icon: const Icon(Icons.notifications, size: 16),
          text: 'Kræver opmærksomhed ($_attentionCount)',
          onPressed: () {
            setState(() {
              _showOnlyNeedsAttention = !_showOnlyNeedsAttention;
            });
            _applyFilters();
          },
        ),
        if (_attentionCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSyncErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s3),
      padding: AppSpacing.p3,
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: AppColors.error.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Synkroniseringsfejl: $message',
              style: AppTypography.sm.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncingBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s3),
      padding: AppSpacing.p3,
      decoration: BoxDecoration(
        color: AppColors.blue50,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: AppColors.blue200),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Synkroniserer med cloud...',
            style: AppTypography.sm.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final hasActiveFilters = _selectedType != 'alle' || _selectedRegion != 'alle' || _showOnlyNeedsAttention || _searchQuery.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkaSearchInput(
          placeholder: 'SA,g efter sagsnr, adresse, byggeleder...',
          controller: _searchController,
          onChanged: (value) {
            _searchQuery = value;
            _applyFilters();
          },
          onClear: () {
            _searchQuery = '';
            _applyFilters();
          },
        ),
        const SizedBox(height: AppSpacing.s4),
        Wrap(
          spacing: AppSpacing.s4,
          runSpacing: AppSpacing.s2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.filter_list, size: 16, color: AppColors.mutedForeground),
                const SizedBox(width: 6),
                Text(
                  'Filtre:',
                  style: AppTypography.smSemibold.copyWith(color: AppColors.foreground),
                ),
              ],
            ),
            _buildFilterSelect(
              label: 'Type',
              value: _selectedType,
              options: _typeOptions,
              onChanged: (value) {
                _selectedType = value;
                _applyFilters();
              },
            ),
            _buildFilterSelect(
              label: 'Region',
              value: _selectedRegion,
              options: _regionOptions,
              onChanged: (value) {
                _selectedRegion = value;
                _applyFilters();
              },
            ),
            if (hasActiveFilters)
              SkaButton(
                variant: ButtonVariant.ghost,
                size: ButtonSize.sm,
                text: 'Ryd filtre',
                onPressed: () {
                  setState(() {
                    _selectedType = 'alle';
                    _selectedRegion = 'alle';
                    _showOnlyNeedsAttention = false;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                  _applyFilters();
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterSelect({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label:',
          style: AppTypography.sm.copyWith(color: AppColors.mutedForeground),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 140,
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              contentPadding: AppSpacing.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s2),
              border: OutlineInputBorder(
                borderRadius: AppRadius.radiusMd,
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusMd,
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
            items: options
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(_formatOptionLabel(option)),
                  ),
                )
                .toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
          ),
        ),
      ],
    );
  }

  String _formatOptionLabel(String value) {
    if (value == 'alle') return 'Alle';
    if (value.isEmpty) return 'Ukendt';
    return value[0].toUpperCase() + value.substring(1);
  }

  Map<String, int> _buildStats(List<Sag> sager, Set<String> attentionIds) {
    return {
      'total': sager.length,
      'udtA,rring': sager.where((s) => _normalizeType(s.sagType) == 'udtA,rring').length,
      'varme': sager.where((s) => _normalizeType(s.sagType) == 'varme').length,
      'begge': sager.where((s) => _normalizeType(s.sagType) == 'begge').length,
      'sjAÝlland': sager.where((s) => _normalizeRegion(s.region) == 'sjAÝlland').length,
      'fyn': sager.where((s) => _normalizeRegion(s.region) == 'fyn').length,
      'jylland': sager.where((s) => _normalizeRegion(s.region) == 'jylland').length,
      'needsAttention': sager.where((s) => attentionIds.contains(s.id)).length,
    };
  }

  Widget _buildStatsGrid({required Map<String, int> stats, required bool showAttention}) {
    final items = <Widget>[];
    if (showAttention && stats['needsAttention']! > 0) {
      items.add(_buildStatCard(
        label: 'Opmærksomhed',
        value: stats['needsAttention']!,
        background: AppColors.warningLight,
        foreground: AppColors.warning,
        border: AppColors.warning.withOpacity(0.3),
      ));
    }

    items.addAll([
      _buildStatCard(
        label: 'UdtA,rring',
        value: stats['udtA,rring']!,
        background: AppColors.blue50,
        foreground: AppColors.blue700,
        border: AppColors.blue200,
      ),
      _buildStatCard(
        label: 'Varme',
        value: stats['varme']!,
        background: AppColors.orange50,
        foreground: AppColors.orange600,
        border: AppColors.orange600.withOpacity(0.3),
      ),
      _buildStatCard(
        label: 'Begge',
        value: stats['begge']!,
        background: const Color(0xFFF3E8FF),
        foreground: const Color(0xFF7E22CE),
        border: const Color(0xFFD8B4FE),
      ),
      _buildStatCard(
        label: 'SjAÝlland',
        value: stats['sjAÝlland']!,
        background: AppColors.successLight,
        foreground: AppColors.success,
        border: AppColors.success.withOpacity(0.3),
      ),
      _buildStatCard(
        label: 'Fyn',
        value: stats['fyn']!,
        background: const Color(0xFFFFFBEB),
        foreground: const Color(0xFFD97706),
        border: const Color(0xFFFDE68A),
      ),
      _buildStatCard(
        label: 'Jylland',
        value: stats['jylland']!,
        background: AppColors.red50,
        foreground: AppColors.red600,
        border: AppColors.red600.withOpacity(0.3),
      ),
    ]);

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 2;
        if (constraints.maxWidth >= Breakpoints.md) {
          columns = 7;
        }
        final spacing = AppSpacing.s2;
        final totalSpacing = spacing * (columns - 1);
        final itemWidth = (constraints.maxWidth - totalSpacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map(
                (item) => SizedBox(
                  width: itemWidth,
                  child: item,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String label,
    required int value,
    required Color background,
    required Color foreground,
    required Color border,
  }) {
    return Container(
      padding: AppSpacing.p2,
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: AppTypography.smSemibold.copyWith(color: foreground),
          ),
          Text(
            label,
            style: AppTypography.xs.copyWith(color: foreground),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSagerContent({required Set<String> attentionIds, required bool isAdmin}) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: AppSpacing.p6,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_filteredSager.isEmpty) {
      return SkaCard(
        child: Column(
          children: [
            Icon(Icons.description, size: 48, color: AppColors.mutedForeground),
            const SizedBox(height: AppSpacing.s3),
            Text(
              _showArchived
                  ? 'Ingen arkiverede sager'
                  : 'Ingen aktive sager endnu',
              style: AppTypography.lgSemibold.copyWith(color: AppColors.foreground),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              _showArchived
                  ? 'Arkiverede sager vises her nAr du arkiverer dem'
                  : 'Opret din fA,rste sag for at komme i gang',
              style: AppTypography.sm.copyWith(color: AppColors.mutedForeground),
              textAlign: TextAlign.center,
            ),
            if (_authService.hasFeature(AppFeatures.createCases) && !_showArchived) ...[
              const SizedBox(height: AppSpacing.s4),
              SkaButton(
                icon: const Icon(Icons.add, size: 16),
                text: 'Opret fA,rste sag',
                onPressed: () => Navigator.pushNamed(context, '/sager/ny'),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: _filteredSager
          .map((sag) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                child: _buildSagCard(sag, attentionIds: attentionIds, isAdmin: isAdmin),
              ))
          .toList(),
    );
  }

  Widget _buildSagCard(Sag sag, {required Set<String> attentionIds, required bool isAdmin}) {
    final needsAttention = attentionIds.contains(sag.id);
    final notifications = _notificationManager.getNotificationsForSag(sag.id);
    final recentNotifications = notifications.take(3).toList();
    final isSelected = _selectedSagerIds.contains(sag.id);

    final borderColor = needsAttention ? AppColors.warning.withOpacity(0.4) : AppColors.border;
    final backgroundColor = needsAttention ? AppColors.warningLight.withOpacity(0.35) : AppColors.card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.radiusLg,
        hoverColor: AppColors.backgroundSecondary,
        onTap: () {
          if (_isSelectionMode) {
            _toggleSagSelection(sag.id);
          } else {
            Navigator.of(context).pushNamed('/sager/${sag.id}');
          }
        },
        child: Ink(
          padding: AppSpacing.p4,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.blue50.withOpacity(0.4) : backgroundColor,
            borderRadius: AppRadius.radiusLg,
            border: Border.all(color: borderColor, width: needsAttention ? 2 : 1),
            boxShadow: AppShadows.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.s2),
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (_) => _toggleSagSelection(sag.id),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                sag.sagsnr.isNotEmpty ? sag.sagsnr : 'Intet sagsnr',
                                style: AppTypography.baseSemibold.copyWith(color: AppColors.foreground),
                              ),
                            ),
                            if (needsAttention)
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.warning,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.warningLight,
                                      borderRadius: AppRadius.radiusMd,
                                      border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.notifications, size: 12, color: AppColors.warning),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Kræver opmærksomhed',
                                          style: AppTypography.xsMedium.copyWith(color: AppColors.warning),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: AppColors.mutedForeground),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                sag.adresse,
                                style: AppTypography.sm.copyWith(color: AppColors.mutedForeground),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: AppSpacing.s2,
                          runSpacing: AppSpacing.s1,
                          children: [
                            if (sag.sagType != null && sag.sagType!.isNotEmpty)
                              _buildTypeBadge(sag.sagType!),
                            if (sag.region != null && sag.region!.isNotEmpty)
                              _buildRegionBadge(sag.region!),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Wrap(
                    spacing: AppSpacing.s2,
                    runSpacing: AppSpacing.s2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SkaBadge(
                        text: sag.aktiv ? 'Aktiv' : 'Inaktiv',
                        variant: sag.aktiv ? BadgeVariant.primary : BadgeVariant.secondary,
                        small: true,
                      ),
                      if (sag.arkiveret == true)
                        SkaBadge(
                          text: 'Arkiveret',
                          variant: BadgeVariant.outline,
                          small: true,
                          icon: const Icon(Icons.archive, size: 12),
                        ),
                      if (isAdmin && needsAttention)
                        SkaButton(
                          variant: ButtonVariant.outline,
                          size: ButtonSize.icon,
                          icon: const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                          onPressed: () => _handleAcknowledgeSag(sag),
                        ),
                      SkaButton(
                        variant: ButtonVariant.ghost,
                        size: ButtonSize.icon,
                        icon: Icon(
                          sag.arkiveret == true ? Icons.unarchive : Icons.archive,
                          size: 18,
                          color: AppColors.mutedForeground,
                        ),
                        onPressed: () => _handleArchiveToggle(sag),
                      ),
                    ],
                  ),
                ],
              ),
              if (needsAttention && recentNotifications.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s4),
                Container(
                  padding: AppSpacing.p3,
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: AppRadius.radiusLg,
                    border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seneste aktivitet:',
                        style: AppTypography.smSemibold.copyWith(color: AppColors.warning),
                      ),
                      const SizedBox(height: AppSpacing.s2),
                      ...recentNotifications.map(
                        (notification) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: AppColors.warning,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${notification.message} (${_formatDate(notification.timestamp)})',
                                  style: AppTypography.xs.copyWith(color: AppColors.warning),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (notifications.length > 3)
                        Text(
                          '+${notifications.length - 3} flere aktiviteter...',
                          style: AppTypography.xs.copyWith(color: AppColors.warning),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.s4),
              _buildInfoGrid(sag),
              if (sag.beskrivelse != null && sag.beskrivelse!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s4),
                Divider(color: AppColors.borderLight, height: 1),
                const SizedBox(height: AppSpacing.s3),
                Text(
                  'Beskrivelse',
                  style: AppTypography.smSemibold.copyWith(color: AppColors.foreground),
                ),
                const SizedBox(height: 4),
                Text(
                  sag.beskrivelse!,
                  style: AppTypography.sm.copyWith(color: AppColors.mutedForeground),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: AppSpacing.s4),
              Divider(color: AppColors.borderLight, height: 1),
              const SizedBox(height: AppSpacing.s3),
              _buildFooter(sag),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    final color = legacy_theme.AppColors.getSagTypeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        _formatOptionLabel(type),
        style: AppTypography.xsMedium.copyWith(color: color),
      ),
    );
  }

  Widget _buildRegionBadge(String region) {
    final color = legacy_theme.AppColors.getRegionColor(region);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        _formatOptionLabel(region),
        style: AppTypography.xsMedium.copyWith(color: color),
      ),
    );
  }

  Widget _buildInfoGrid(Sag sag) {
    final isWide = MediaQuery.of(context).size.width >= Breakpoints.md;

    final byggeleder = _buildInfoColumn(
      title: 'Byggeleder',
      items: [
        _InfoRow(icon: Icons.person_outline, text: sag.byggeleder),
        if (sag.byggelederEmail != null && sag.byggelederEmail!.isNotEmpty)
          _InfoRow(icon: Icons.mail_outline, text: sag.byggelederEmail!),
        if (sag.byggelederTlf != null && sag.byggelederTlf!.isNotEmpty)
          _InfoRow(icon: Icons.phone_outlined, text: sag.byggelederTlf!),
      ],
    );

    final bygherre = _buildInfoColumn(
      title: 'Bygherre',
      items: [
        if (sag.bygherre != null && sag.bygherre!.isNotEmpty)
          _InfoRow(icon: Icons.business, text: sag.bygherre!),
        if (sag.bygherre == null || sag.bygherre!.isEmpty)
          const _InfoRow(icon: Icons.business, text: 'Ikke angivet', muted: true),
        if (sag.cvrNr != null && sag.cvrNr!.isNotEmpty)
          _InfoRow(icon: Icons.badge_outlined, text: 'CVR: ${sag.cvrNr}'),
        if (sag.kundensSagsref != null && sag.kundensSagsref!.isNotEmpty)
          _InfoRow(icon: Icons.tag, text: 'Ref: ${sag.kundensSagsref}'),
      ],
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: byggeleder),
          const SizedBox(width: AppSpacing.s4),
          Expanded(child: bygherre),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        byggeleder,
        const SizedBox(height: AppSpacing.s3),
        bygherre,
      ],
    );
  }

  Widget _buildInfoColumn({required String title, required List<_InfoRow> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.smSemibold.copyWith(color: AppColors.foreground),
        ),
        const SizedBox(height: AppSpacing.s2),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(item.icon, size: 14, color: item.muted ? AppColors.mutedForeground : AppColors.lightForeground),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.text,
                      style: AppTypography.xs.copyWith(
                        color: item.muted ? AppColors.mutedForeground : AppColors.foreground,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildFooter(Sag sag) {
    final createdAt = sag.oprettetDato.isNotEmpty
        ? sag.oprettetDato
        : (sag.createdAt ?? '');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today, size: 14, color: AppColors.mutedForeground),
            const SizedBox(width: 6),
            Text(
              'Oprettet: ${_formatDate(createdAt)}',
              style: AppTypography.xs.copyWith(color: AppColors.mutedForeground),
            ),
          ],
        ),
        Wrap(
          spacing: AppSpacing.s2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (sag.arkiveret == true && sag.arkiveretDato != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.archive, size: 14, color: AppColors.mutedForeground),
                  const SizedBox(width: 4),
                  Text(
                    'Arkiveret: ${_formatDate(sag.arkiveretDato!)}',
                    style: AppTypography.xs.copyWith(color: AppColors.mutedForeground),
                  ),
                ],
              ),
            if (sag.status.isNotEmpty)
              SkaBadge(
                text: sag.status,
                variant: BadgeVariant.outline,
                small: true,
              ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String text;
  final bool muted;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.muted = false,
  });
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
                  return 'Dette felt er pAkrAÝvet';
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
                  return 'Dette felt er pAkrAÝvet';
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
          child: const Text('FortsAÝt'),
        ),
      ],
    );
  }
}
