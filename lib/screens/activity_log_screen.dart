import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/activity_log.dart';
import '../models/sag.dart';
import '../widgets/filter_widget.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ui/ska_button.dart';
import '../widgets/ui/ska_card.dart';

/// Dedicated screen for viewing all activity logs across the system
class ActivityLogScreen extends StatefulWidget {
  final String? initialSagId;

  const ActivityLogScreen({super.key, this.initialSagId});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  final _dbService = DatabaseService();
  List<ActivityLog> _allLogs = [];
  List<ActivityLog> _filteredLogs = [];
  List<Sag> _sager = [];
  bool _isLoading = true;

  // Filters
  String _searchQuery = '';
  String _selectedEntityType = 'alle';
  String _selectedAction = 'alle';
  String _selectedSagId = 'alle';
  String _selectedPeriod = 'alle';

  // Stats
  int get _totalLogs => _allLogs.length;
  int get _todayLogs => _allLogs.where((log) {
        try {
          final date = DateTime.parse(log.timestamp);
          final today = DateTime.now();
          return date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
        } catch (_) {
          return false;
        }
      }).length;

  @override
  void initState() {
    super.initState();
    if (widget.initialSagId != null) {
      _selectedSagId = widget.initialSagId!;
    }
    _loadData();
    _setupActivityLogListener();
  }

  @override
  void dispose() {
    _dbService.removeActivityLogListener(_onNewActivity);
    super.dispose();
  }

  void _setupActivityLogListener() {
    _dbService.addActivityLogListener(_onNewActivity);
  }

  void _onNewActivity(ActivityLog newLog) {
    if (!mounted) return;
    setState(() {
      // Add at the beginning since logs are sorted newest first
      _allLogs.insert(0, newLog);
      _applyFilters();
    });

    // Show snackbar for new activity
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_getEntityIcon(newLog.entityType), color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                newLog.displayDescription,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Vis',
          textColor: Colors.white,
          onPressed: () {
            // Scroll to the new log entry
          },
        ),
      ),
    );
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final logs = _dbService.getAllActivityLogs();
      final sager = _dbService.getAllSager();

      setState(() {
        _allLogs = logs;
        _sager = sager;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fejl ved indlæsning: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    var filtered = _allLogs;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((log) {
        return log.displayDescription.toLowerCase().contains(query) ||
            (log.userName?.toLowerCase().contains(query) ?? false) ||
            log.entityType.toLowerCase().contains(query) ||
            log.action.toLowerCase().contains(query);
      }).toList();
    }

    // Entity type filter
    if (_selectedEntityType != 'alle') {
      filtered = filtered.where((log) => log.entityType == _selectedEntityType).toList();
    }

    // Action filter
    if (_selectedAction != 'alle') {
      filtered = filtered.where((log) => log.action == _selectedAction).toList();
    }

    // Sag filter
    if (_selectedSagId != 'alle') {
      filtered = filtered.where((log) => log.sagId == _selectedSagId).toList();
    }

    // Period filter
    if (_selectedPeriod != 'alle') {
      final now = DateTime.now();
      DateTime? filterDate;

      switch (_selectedPeriod) {
        case 'today':
          filterDate = DateTime(now.year, now.month, now.day);
          break;
        case 'week':
          filterDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          filterDate = DateTime(now.year, now.month - 1, now.day);
          break;
      }

      if (filterDate != null) {
        filtered = filtered.where((log) {
          try {
            final logDate = DateTime.parse(log.timestamp);
            return logDate.isAfter(filterDate!);
          } catch (_) {
            return false;
          }
        }).toList();
      }
    }

    setState(() {
      _filteredLogs = filtered;
    });
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _selectedEntityType = 'alle';
      _selectedAction = 'alle';
      _selectedSagId = widget.initialSagId ?? 'alle';
      _selectedPeriod = 'alle';
      _applyFilters();
    });
  }

  void _exportToCsv() {
    // CSV export is a Phase 3 enhancement - placeholder for now
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV eksport kommer i næste version')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivitetslog'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Opdater',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Eksporter CSV',
            onPressed: _exportToCsv,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats cards
                _buildStatsRow(theme),
                const SizedBox(height: 12),

                // Filters
                _buildFilters(theme),
                const SizedBox(height: 8),

                // Results header
                FilterResultsHeader(
                  resultCount: _filteredLogs.length,
                  itemLabel: 'aktiviteter',
                ),
                const SizedBox(height: 8),

                // Activity list
                Expanded(
                  child: _filteredLogs.isEmpty
                      ? _buildEmptyState(theme)
                      : _buildActivityList(theme),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    // Count by entity type
    final entityCounts = <String, int>{};
    for (final log in _allLogs) {
      entityCounts[log.entityType] = (entityCounts[log.entityType] ?? 0) + 1;
    }

    return SummaryCardsFilter(
      options: [
        FilterOption(
          value: 'alle',
          label: 'Total',
          count: _totalLogs,
          icon: Icons.history,
          color: AppColors.primary,
        ),
        FilterOption(
          value: 'today',
          label: 'I dag',
          count: _todayLogs,
          icon: Icons.today,
          color: AppColors.success,
        ),
        FilterOption(
          value: 'sag',
          label: 'Sager',
          count: entityCounts['sag'] ?? 0,
          icon: Icons.folder,
          color: AppColors.primary,
        ),
        FilterOption(
          value: 'equipment',
          label: 'Udstyr',
          count: entityCounts['equipment'] ?? 0,
          icon: Icons.inventory_2,
          color: AppColors.warning,
        ),
      ],
      selectedValue: _selectedEntityType == 'alle' ? (_selectedPeriod == 'today' ? 'today' : 'alle') : _selectedEntityType,
      onChanged: (value) {
        setState(() {
          if (value == 'today') {
            _selectedPeriod = 'today';
            _selectedEntityType = 'alle';
          } else if (value == 'alle') {
            _selectedPeriod = 'alle';
            _selectedEntityType = 'alle';
          } else {
            _selectedPeriod = 'alle';
            _selectedEntityType = value;
          }
          _applyFilters();
        });
      },
    );
  }

  Widget _buildFilters(ThemeData theme) {
    // Get unique entity types
    final entityTypes = _allLogs.map((l) => l.entityType).toSet().toList()..sort();
    final actions = _allLogs.map((l) => l.action).toSet().toList()..sort();

    return Padding(
      padding: AppSpacing.symmetric(horizontal: AppSpacing.s4),
      child: FilterBar(
        filters: [
          FilterConfig(
            id: 'search',
            label: 'Søg',
            type: FilterType.search,
            hint: 'Søg i beskrivelse, bruger...',
          ),
          FilterConfig(
            id: 'entityType',
            label: 'Type',
            type: FilterType.dropdown,
            options: [
              const FilterOption(value: 'alle', label: 'Alle typer'),
              ...entityTypes.map((t) => FilterOption(
                    value: t,
                    label: _getEntityLabel(t),
                    icon: _getEntityIcon(t),
                  )),
            ],
          ),
          FilterConfig(
            id: 'action',
            label: 'Handling',
            type: FilterType.dropdown,
            options: [
              const FilterOption(value: 'alle', label: 'Alle handlinger'),
              ...actions.map((a) => FilterOption(
                    value: a,
                    label: _getActionLabel(a),
                  )),
            ],
          ),
          FilterConfig(
            id: 'sag',
            label: 'Sag',
            type: FilterType.dropdown,
            options: [
              const FilterOption(value: 'alle', label: 'Alle sager'),
              ..._sager.map((s) => FilterOption(
                    value: s.id,
                    label: s.sagsnr,
                  )),
            ],
          ),
          FilterConfig(
            id: 'period',
            label: 'Periode',
            type: FilterType.dropdown,
            options: const [
              FilterOption(value: 'alle', label: 'Alle datoer'),
              FilterOption(value: 'today', label: 'I dag'),
              FilterOption(value: 'week', label: 'Sidste uge'),
              FilterOption(value: 'month', label: 'Sidste måned'),
            ],
          ),
        ],
        values: {
          'search': _searchQuery,
          'entityType': _selectedEntityType,
          'action': _selectedAction,
          'sag': _selectedSagId,
          'period': _selectedPeriod,
        },
        onFilterChanged: (id, value) {
          setState(() {
            switch (id) {
              case 'search':
                _searchQuery = value ?? '';
                break;
              case 'entityType':
                _selectedEntityType = value ?? 'alle';
                break;
              case 'action':
                _selectedAction = value ?? 'alle';
                break;
              case 'sag':
                _selectedSagId = value ?? 'alle';
                break;
              case 'period':
                _selectedPeriod = value ?? 'alle';
                break;
            }
            _applyFilters();
          });
        },
        onReset: _resetFilters,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: AppColors.mutedForeground,
          ),
          const SizedBox(height: 16),
          Text(
            _allLogs.isEmpty
                ? 'Ingen aktiviteter registreret endnu'
                : 'Ingen aktiviteter matcher filtrene',
            style: AppTypography.smSemibold.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
          if (_allLogs.isNotEmpty) ...[
            const SizedBox(height: 8),
            SkaButton(
              onPressed: _resetFilters,
              variant: ButtonVariant.ghost,
              icon: const Icon(Icons.clear_all),
              text: 'Nulstil filtre',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityList(ThemeData theme) {
    return ListView.builder(
      padding: AppSpacing.symmetric(horizontal: AppSpacing.s4),
      itemCount: _filteredLogs.length,
      itemBuilder: (context, index) {
        final log = _filteredLogs[index];
        return _buildActivityCard(theme, log);
      },
    );
  }

  Widget _buildActivityCard(ThemeData theme, ActivityLog log) {
    final icon = _getEntityIcon(log.entityType);
    final color = _getEntityColor(log.entityType);
    final actionIcon = _getActionIcon(log.action);

    // Format timestamp
    String formattedTime;
    try {
      final date = DateTime.parse(log.timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) {
        formattedTime = 'Lige nu';
      } else if (diff.inHours < 1) {
        formattedTime = '${diff.inMinutes} min siden';
      } else if (diff.inHours < 24 && date.day == now.day) {
        formattedTime = 'I dag ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (diff.inHours < 48) {
        formattedTime = 'I går ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else {
        formattedTime = '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      formattedTime = log.timestamp;
    }

    return SkaCard(
      padding: AppSpacing.p4,
      onTap: () => _showActivityDetails(log),
      child: Padding(
          padding: EdgeInsets.zero,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Entity icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getEntityLabel(log.entityType),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(actionIcon, size: 12, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                _getActionLabel(log.action),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Description
                    Text(
                      log.displayDescription,
                      style: AppTypography.smSemibold,
                    ),

                    const SizedBox(height: 4),

                    // Meta info
                    Row(
                      children: [
                        if (log.userName != null) ...[
                          Icon(Icons.person_outline, size: 14, color: theme.colorScheme.outline),
                          const SizedBox(width: 4),
                          Text(
                            log.userName!,
                            style: AppTypography.xs.copyWith(color: AppColors.mutedForeground),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(Icons.access_time, size: 14, color: theme.colorScheme.outline),
                        const SizedBox(width: 4),
                        Text(
                          formattedTime,
                          style: AppTypography.xs.copyWith(color: AppColors.mutedForeground),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow indicator
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
    );
  }

  void _showActivityDetails(ActivityLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          final theme = Theme.of(context);
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getEntityColor(log.entityType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getEntityIcon(log.entityType),
                      color: _getEntityColor(log.entityType),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.displayDescription,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Chip(
                              label: Text(_getEntityLabel(log.entityType)),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(_getActionLabel(log.action)),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Details
              _buildDetailRow(theme, 'Tidspunkt', _formatTimestamp(log.timestamp)),
              if (log.userName != null)
                _buildDetailRow(theme, 'Bruger', log.userName!),
              if (log.entityId != null)
                _buildDetailRow(theme, 'Entity ID', log.entityId!),
              if (log.sagId != null)
                _buildDetailRow(theme, 'Sag ID', log.sagId!),

              // Old/New data if available
              if (log.oldData != null || log.newData != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Ændringer',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (log.oldData != null)
                  _buildDataSection(theme, 'Før', log.oldData!, Colors.red),
                if (log.newData != null)
                  _buildDataSection(theme, 'Efter', log.newData!, Colors.green),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection(ThemeData theme, String title, Map<String, dynamic> data, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          ...data.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${e.key}: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${e.value}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
    } catch (_) {
      return timestamp;
    }
  }

  IconData _getEntityIcon(String entityType) {
    return switch (entityType) {
      'sag' => Icons.folder_outlined,
      'user' => Icons.person_outline,
      'affugter' => Icons.water_drop_outlined,
      'timer' => Icons.timer_outlined,
      'equipment' => Icons.inventory_2_outlined,
      'blok' => Icons.view_quilt_outlined,
      'kabel' => Icons.cable,
      'besked' => Icons.chat_bubble_outline,
      'settings' => Icons.settings_outlined,
      _ => Icons.history,
    };
  }

  String _getEntityLabel(String entityType) {
    return switch (entityType) {
      'sag' => 'Sag',
      'user' => 'Bruger',
      'affugter' => 'Affugter',
      'timer' => 'Timer',
      'equipment' => 'Udstyr',
      'blok' => 'Blok',
      'kabel' => 'Kabel',
      'besked' => 'Besked',
      'settings' => 'Indstillinger',
      _ => entityType,
    };
  }

  Color _getEntityColor(String entityType) {
    return switch (entityType) {
      'sag' => Colors.blue,
      'user' => Colors.purple,
      'affugter' => Colors.cyan,
      'timer' => AppColors.primary,
      'equipment' => Colors.green,
      'blok' => Colors.blueGrey,
      'kabel' => Colors.orange,
      'besked' => Colors.pink,
      'settings' => Colors.grey,
      _ => Colors.grey,
    };
  }

  IconData _getActionIcon(String action) {
    return switch (action) {
      'create' => Icons.add_circle_outline,
      'update' => Icons.edit_outlined,
      'delete' => Icons.delete_outline,
      'assign' => Icons.link,
      'unassign' => Icons.link_off,
      'archive' => Icons.archive_outlined,
      _ => Icons.circle_outlined,
    };
  }

  String _getActionLabel(String action) {
    return switch (action) {
      'create' => 'Oprettet',
      'update' => 'Opdateret',
      'delete' => 'Slettet',
      'assign' => 'Tildelt',
      'unassign' => 'Fjernet',
      'archive' => 'Arkiveret',
      _ => action,
    };
  }
}
