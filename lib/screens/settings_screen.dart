import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../providers/theme_provider.dart';
import '../constants/roles_and_features.dart';
import 'dropdown_settings_screen.dart';
import 'admin_settings_screen.dart';
import 'activity_log_screen.dart';
import 'user_management_screen.dart';

/// Main Settings screen - Hub for all settings and administration
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _dbService = DatabaseService();
  final _authService = AuthService();
  final _syncService = SyncService();
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isSyncing = false;
  BackupStats? _backupStats;

  @override
  void initState() {
    super.initState();
    _loadBackupStats();
  }

  void _loadBackupStats() {
    final stats = BackupStats(
      sager: _dbService.getAllSager().length,
      users: _dbService.getAllUsers().length,
      affugtere: _dbService.getAllAffugtere().length,
      equipmentLogs: _dbService.getAllEquipmentLogs().length,
      timerLogs: _dbService.getAllTimerLogs().length,
      kabelSlangeLogs: _dbService.getAllKabelSlangeLogs().length,
      blokke: _dbService.getAllBlokke().length,
      messages: _dbService.getAllMessages().length,
      activityLogs: _dbService.getAllActivityLogs().length,
    );
    setState(() => _backupStats = stats);
  }

  Future<void> _exportBackup() async {
    setState(() => _isExporting = true);
    try {
      final currentUser = _authService.currentUser;

      // Collect all data
      final backupData = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'exportedBy': currentUser?.name ?? 'Unknown',
        'data': {
          'users': _dbService.getAllUsers().map((u) => u.toJson()).toList(),
          'sager': _dbService.getAllSager().map((s) => s.toJson()).toList(),
          'affugtere': _dbService.getAllAffugtere().map((a) => a.toJson()).toList(),
          'blokke': _dbService.getAllBlokke().map((b) => b.toJson()).toList(),
          'equipmentLogs': _dbService.getAllEquipmentLogs().map((e) => e.toJson()).toList(),
          'timerLogs': _dbService.getAllTimerLogs().map((t) => t.toJson()).toList(),
          'kabelSlangeLogs': _dbService.getAllKabelSlangeLogs().map((k) => k.toJson()).toList(),
          'messages': _dbService.getAllMessages().map((m) => m.toJson()).toList(),
          'activityLogs': _dbService.getAllActivityLogs().map((a) => a.toJson()).toList(),
        },
        'stats': _backupStats?.toJson(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final fileName = 'ska-dan-backup-${DateTime.now().toIso8601String().split('T')[0]}-${DateTime.now().millisecondsSinceEpoch}.json';

      // Get temp directory and write file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonString);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'SKA-DAN Backup',
        text: 'Backup eksporteret ${DateTime.now().toString().split('.')[0]}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup eksporteret med ${_backupStats?.totalItems ?? 0} elementer'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fejl ved eksport: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _isImporting = true);

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final backup = jsonDecode(content) as Map<String, dynamic>;

      // Validate backup structure
      if (!backup.containsKey('version') || !backup.containsKey('data')) {
        throw Exception('Ugyldig backup fil format');
      }

      // Show confirmation dialog
      final stats = backup['stats'] as Map<String, dynamic>?;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange),
              SizedBox(width: 8),
              Text('Gendan Backup?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Backup fra: ${_formatTimestamp(backup['timestamp'] as String)}'),
              Text('Eksporteret af: ${backup['exportedBy']}'),
              const SizedBox(height: 12),
              const Text('Indeholder:', style: TextStyle(fontWeight: FontWeight.bold)),
              if (stats != null) ...[
                Text('  - ${stats['sager']} sager'),
                Text('  - ${stats['users']} brugere'),
                Text('  - ${stats['affugtere']} affugtere'),
                Text('  - ${stats['equipmentLogs']} udstyrslogs'),
                Text('  - ${stats['timerLogs']} timerlogs'),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ADVARSEL: Dette vil overskrive eksisterende data!',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuller'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Gendan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        setState(() => _isImporting = false);
        return;
      }

      // Import all data from backup
      await _dbService.importFromBackup(backup);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup gendannet med ${stats?['totalItems'] ?? 0} elementer. Appen genindlæses...'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Refresh stats after import
        _loadBackupStats();

        // Trigger a sync to push imported data to Supabase
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _manualSync();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fejl ved import: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Future<void> _manualSync() async {
    setState(() => _isSyncing = true);
    try {
      await _syncService.syncPending();
      await _syncService.pullFromRemote();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Synkronisering gennemført'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBackupStats();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Synkronisering fejlede: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pendingChanges = _syncService.pendingChangesCount;

    // Access control checks
    final canBackup = _authService.hasFeature(AppFeatures.backup);
    final canManageUsers = _authService.hasFeature(AppFeatures.userManagement);
    final canManageDropdowns = _authService.hasFeature(AppFeatures.dropdownSettings);
    final canViewActivityLog = _authService.hasFeature(AppFeatures.activityLog);
    final hasAnyAdminAccess = canManageUsers || canManageDropdowns || _authService.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Indstillinger'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sync Status Section (always visible)
            _buildSyncStatusSection(theme, pendingChanges),
            const SizedBox(height: 16),

            // Data Overview section (always visible)
            _buildDataOverviewSection(theme),
            const SizedBox(height: 16),

            // Backup & Restore section (permission-based)
            if (canBackup) ...[
              _buildBackupSection(theme),
              const SizedBox(height: 16),
            ],

            // Administration section (permission-based)
            if (hasAnyAdminAccess) ...[
              _buildAdministrationSection(theme, canManageUsers, canManageDropdowns),
              const SizedBox(height: 16),
            ],

            // Activity Log section (permission-based)
            if (canViewActivityLog) _buildActivityLogSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusSection(ThemeData theme, int pendingChanges) {
    final isOnline = _syncService.isInitialSyncComplete;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sync, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Synkronisering', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),

            // Status indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isSyncing
                    ? Colors.blue.shade50
                    : pendingChanges > 0
                        ? Colors.orange.shade50
                        : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _isSyncing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.blue.shade700,
                          ),
                        )
                      : Icon(
                          pendingChanges > 0 ? Icons.pending : Icons.check_circle,
                          color: pendingChanges > 0 ? Colors.orange.shade700 : Colors.green.shade700,
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isSyncing
                          ? 'Synkroniserer...'
                          : pendingChanges > 0
                              ? '$pendingChanges ændring${pendingChanges > 1 ? 'er' : ''} venter'
                              : 'Alt synkroniseret',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _isSyncing
                            ? Colors.blue.shade700
                            : pendingChanges > 0
                                ? Colors.orange.shade700
                                : Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Connection status
            Row(
              children: [
                Icon(
                  isOnline ? Icons.wifi : Icons.wifi_off,
                  size: 18,
                  color: isOnline ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  isOnline ? 'Online - Supabase tilsluttet' : 'Synkroniserer...',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sync button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSyncing ? null : _manualSync,
                icon: _isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.sync),
                label: Text(_isSyncing ? 'Synkroniserer...' : 'Synkroniser nu'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataOverviewSection(ThemeData theme) {
    if (_backupStats == null) {
      return const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Data Oversigt', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),

            // Stats grid
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.5,
              children: [
                _buildStatTile('Sager', _backupStats!.sager, Colors.blue),
                _buildStatTile('Brugere', _backupStats!.users, Colors.purple),
                _buildStatTile('Affugtere', _backupStats!.affugtere, Colors.cyan),
                _buildStatTile('Udstyr', _backupStats!.equipmentLogs, Colors.green),
                _buildStatTile('Timer', _backupStats!.timerLogs, Colors.orange),
                _buildStatTile('Blokke', _backupStats!.blokke, Colors.indigo),
              ],
            ),
            const SizedBox(height: 12),

            // Total
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.data_usage, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Total: ${_backupStats!.totalItems} elementer',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$count',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBackupSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.backup, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Backup & Gendannelse', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),

            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Download en komplet backup af alle dine data. Filen gemmes i JSON format.',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Export button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _exportBackup,
                icon: _isExporting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download),
                label: Text(_isExporting ? 'Eksporterer...' : 'Download Backup'),
              ),
            ),
            const SizedBox(height: 16),

            // Import section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Gendan fra Backup',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gendannelse vil overskrive eksisterende data! Download altid en backup først.',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isImporting ? null : _importBackup,
                      icon: _isImporting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.upload),
                      label: Text(_isImporting ? 'Importerer...' : 'Vælg Backup Fil'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdministrationSection(ThemeData theme, bool canManageUsers, bool canManageDropdowns) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.admin_panel_settings, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Administration', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),

            if (canManageUsers) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.people, color: Colors.purple),
                ),
                title: const Text('Brugeradministration'),
                subtitle: Text('${_backupStats?.users ?? 0} brugere'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UserManagementScreen()),
                  ).then((_) => _loadBackupStats());
                },
              ),
              const Divider(height: 1),
            ],
            if (_authService.isAdmin) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.key, color: Colors.blue),
                ),
                title: const Text('e-conomic API'),
                subtitle: const Text('Konfigurer e-conomic integration'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminSettingsScreen()),
                  );
                },
              ),
              const Divider(height: 1),
            ],
            if (canManageDropdowns)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.list_alt, color: Colors.green),
                ),
                title: const Text('Dropdown Indstillinger'),
                subtitle: const Text('Administrer valgmuligheder i dropdown menuer'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DropdownSettingsScreen()),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLogSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Aktivitetslog', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.timeline, color: Colors.orange),
              ),
              title: const Text('Se Aktivitetslog'),
              subtitle: Text('${_backupStats?.activityLogs ?? 0} aktiviteter registreret'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ActivityLogScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Statistics for backup data
class BackupStats {
  final int sager;
  final int users;
  final int affugtere;
  final int equipmentLogs;
  final int timerLogs;
  final int kabelSlangeLogs;
  final int blokke;
  final int messages;
  final int activityLogs;

  BackupStats({
    required this.sager,
    required this.users,
    required this.affugtere,
    required this.equipmentLogs,
    required this.timerLogs,
    required this.kabelSlangeLogs,
    required this.blokke,
    required this.messages,
    required this.activityLogs,
  });

  int get totalItems =>
      sager + users + affugtere + equipmentLogs + timerLogs + kabelSlangeLogs + blokke + messages + activityLogs;

  Map<String, dynamic> toJson() => {
        'sager': sager,
        'users': users,
        'affugtere': affugtere,
        'equipmentLogs': equipmentLogs,
        'timerLogs': timerLogs,
        'kabelSlangeLogs': kabelSlangeLogs,
        'blokke': blokke,
        'messages': messages,
        'activityLogs': activityLogs,
        'totalItems': totalItems,
      };
}
