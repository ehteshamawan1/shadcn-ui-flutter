import 'package:flutter/material.dart';
import '../models/blok.dart';
import '../models/equipment_log.dart';
import '../models/kabel_slange_log.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'responsive_builder.dart';
import 'ui/ska_badge.dart';
import 'ui/ska_card.dart';
import 'ui/ska_input.dart';

class SamletOverblikWidget extends StatefulWidget {
  final String sagId;

  const SamletOverblikWidget({
    super.key,
    required this.sagId,
  });

  @override
  State<SamletOverblikWidget> createState() => _SamletOverblikWidgetState();
}

class _SamletOverblikWidgetState extends State<SamletOverblikWidget> {
  final _dbService = DatabaseService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<Blok> _blokke = [];
  List<EquipmentLog> _equipmentLogs = [];
  List<KabelSlangeLog> _kabelSlangeLogs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant SamletOverblikWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sagId != widget.sagId) {
      _loadData();
    }
  }

  void _loadData() {
    setState(() {
      _blokke = _dbService.getBlokkeBySag(widget.sagId);
      _equipmentLogs = _dbService.getEquipmentLogsBySag(widget.sagId);
      _equipmentLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _kabelSlangeLogs = _dbService.getKabelSlangeLogsBySag(widget.sagId);
      _kabelSlangeLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  int get _activeBlokke => _blokke.where((blok) => blok.slutDato == null).length;

  int get _activeEquipment =>
      _equipmentLogs.where((log) => log.action.toLowerCase() == 'opsat').length;

  int get _inactiveEquipment =>
      _equipmentLogs.where((log) => log.action.toLowerCase() == 'nedtag').length;

  List<Blok> get _filteredBlokke {
    if (_searchQuery.isEmpty) return _blokke;
    final query = _searchQuery.toLowerCase();
    return _blokke.where((blok) => blok.navn.toLowerCase().contains(query)).toList();
  }

  List<EquipmentLog> get _filteredEquipment {
    if (_searchQuery.isEmpty) return _equipmentLogs;
    final query = _searchQuery.toLowerCase();
    return _equipmentLogs.where((log) {
      final category = log.category.toLowerCase();
      final action = log.action.toLowerCase();
      return category.contains(query) || action.contains(query);
    }).toList();
  }

  List<KabelSlangeLog> get _filteredKabelSlange {
    if (_searchQuery.isEmpty) return _kabelSlangeLogs;
    final query = _searchQuery.toLowerCase();
    return _kabelSlangeLogs.where((log) {
      final category = log.category.toLowerCase();
      final type = log.type.toLowerCase();
      final customType = log.customType?.toLowerCase() ?? '';
      return category.contains(query) || type.contains(query) || customType.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        SkaCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkaCardHeader(
                title: 'Samlet overblik',
                description: 'Status for blokke og udstyr på denne sag.',
              ),
              SkaCardContent(
                child: ResponsiveGrid(
                  mobileColumns: 2,
                  tabletColumns: 4,
                  desktopColumns: 4,
                  spacing: AppSpacing.s3,
                  runSpacing: AppSpacing.s3,
                  children: [
                    _buildStatCard('Blokke', _blokke.length, AppColors.primary),
                    _buildStatCard('Aktive', _activeBlokke, AppColors.success),
                    _buildStatCard('Udstyr opsat', _activeEquipment, AppColors.primary),
                    _buildStatCard('Udstyr nedtaget', _inactiveEquipment, AppColors.error),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        SkaInput(
          placeholder: 'Søg i blokke og udstyr...',
          controller: _searchController,
          prefixIcon: const Icon(Icons.search),
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
        ),
        const SizedBox(height: AppSpacing.s4),
        SkaCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkaCardHeader(
                title: 'Blokke',
                description: '${_filteredBlokke.length} blokke',
              ),
              SkaCardContent(
                child: _filteredBlokke.isEmpty
                    ? Text('Ingen blokke registreret', style: AppTypography.sm)
                    : Column(
                        children: _filteredBlokke
                            .map(
                              (blok) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.s2),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        blok.navn,
                                        style: AppTypography.smSemibold,
                                      ),
                                    ),
                                    SkaBadge(
                                      text: blok.slutDato == null ? 'Aktiv' : 'Afsluttet',
                                      variant: blok.slutDato == null
                                          ? BadgeVariant.success
                                          : BadgeVariant.secondary,
                                      small: true,
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        SkaCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkaCardHeader(
                title: 'Udstyr',
                description: '${_filteredEquipment.length} registreringer',
              ),
              SkaCardContent(
                child: _filteredEquipment.isEmpty
                    ? Text('Ingen udstyr registreret', style: AppTypography.sm)
                    : Column(
                        children: _filteredEquipment
                            .map(
                              (log) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.s2),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${log.category} • ${log.action}',
                                        style: AppTypography.smSemibold,
                                      ),
                                    ),
                                    Text(
                                      _formatDate(log.timestamp),
                                      style: AppTypography.xs.copyWith(
                                        color: AppColors.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        SkaCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkaCardHeader(
                title: 'Kabler og slanger',
                description: '${_filteredKabelSlange.length} registreringer',
              ),
              SkaCardContent(
                child: _filteredKabelSlange.isEmpty
                    ? Text('Ingen kabler eller slanger registreret', style: AppTypography.sm)
                    : Column(
                        children: _filteredKabelSlange
                            .map(
                              (log) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.s2),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _displayKabelSlangeType(log),
                                        style: AppTypography.smSemibold,
                                      ),
                                    ),
                                    Text(
                                      _formatKabelSlangeValue(log),
                                      style: AppTypography.xs.copyWith(
                                        color: AppColors.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s4), // Bottom padding
      ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Container(
      padding: AppSpacing.p3,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value.toString(), style: AppTypography.lgSemibold.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.xs.copyWith(color: color)),
        ],
      ),
    );
  }

  String _formatDate(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return timestamp;
    }
  }

  String _displayKabelSlangeType(KabelSlangeLog log) {
    if (log.type == 'Andet' && log.customType != null && log.customType!.isNotEmpty) {
      return log.customType!;
    }
    return log.type;
  }

  String _formatKabelSlangeValue(KabelSlangeLog log) {
    if (log.category == 'slanger') {
      final meters = log.meters?.toStringAsFixed(1) ?? '0';
      return '$meters m';
    }
    final quantity = log.quantity?.toString() ?? '0';
    return '$quantity stk';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
