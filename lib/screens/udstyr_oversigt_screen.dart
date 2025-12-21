import 'package:flutter/material.dart';
import '../models/affugter.dart';
import '../services/database_service.dart';
import '../providers/theme_provider.dart' as legacy_colors;
import '../theme/app_colors.dart' as theme_colors;
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/filter_widget.dart';
import '../widgets/ui/ska_badge.dart';
import '../widgets/ui/ska_button.dart';
import '../widgets/ui/ska_card.dart';
import '../widgets/ui/ska_input.dart';
import '../widgets/theme_toggle.dart';

class UdstyrsOversigtScreen extends StatefulWidget {
  const UdstyrsOversigtScreen({super.key});

  @override
  State<UdstyrsOversigtScreen> createState() => _UdstyrsOversigtScreenState();
}

class _UdstyrsOversigtScreenState extends State<UdstyrsOversigtScreen> {
  final _dbService = DatabaseService();
  late List<Affugter> _affugtere;
  String _filterStatus = 'alle';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAffugtere();
  }

  void _loadAffugtere() {
    setState(() {
      _loading = true;
    });

    var all = _dbService.getAllAffugtere();
    if (_filterStatus != 'alle') {
      all = all.where((a) => a.status == _filterStatus).toList();
    }
    all.sort((a, b) => a.nr.compareTo(b.nr));

    setState(() {
      _affugtere = all;
      _loading = false;
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'hjemme':
        return legacy_colors.AppColors.statusHjemme;
      case 'udlejet':
        return legacy_colors.AppColors.statusUdlejet;
      case 'defekt':
        return legacy_colors.AppColors.statusDefekt;
      default:
        return Colors.grey;
    }
  }

  Future<void> _deleteAffugter(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slet udstyr'),
        content: const Text('Er du sikker paa, at du vil slette dette udstyr?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuller'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Slet'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _dbService.deleteAffugter(id);
      _loadAffugtere();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Udstyr slettet')),
        );
      }
    }
  }

  Future<void> _showAffugterDialog([Affugter? affugter]) async {
    final isEdit = affugter != null;
    final formKey = GlobalKey<FormState>();

    final nrController = TextEditingController(text: affugter?.nr);
    final modelController = TextEditingController(text: affugter?.model);
    final serieController = TextEditingController(text: affugter?.serie);
    final noteController = TextEditingController(text: affugter?.note);

    final types = ['adsorption', 'kondens'];
    final maerker = ['Master', 'Fral', 'Qube', 'Andet'];
    final statuses = ['hjemme', 'udlejet', 'defekt'];

    // Validate and sanitize values to prevent dropdown assertion errors
    String selectedType = affugter?.type ?? 'adsorption';
    if (!types.contains(selectedType)) {
      selectedType = types.first;
    }

    String selectedMaerke = affugter?.maerke ?? 'Master';
    if (!maerker.contains(selectedMaerke)) {
      selectedMaerke = maerker.first;
    }

    String selectedStatus = affugter?.status ?? 'hjemme';
    if (!statuses.contains(selectedStatus)) {
      selectedStatus = statuses.first;
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Rediger udstyr' : 'Tilfoej udstyr'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SkaInput(
                    label: 'Nummer *',
                    placeholder: '2-0001',
                    controller: nrController,
                    validator: (v) => v?.isEmpty == true ? 'Paakraevet' : null,
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Type *'),
                    items: types
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedType = v!),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  DropdownButtonFormField<String>(
                    value: selectedMaerke,
                    decoration: const InputDecoration(labelText: 'Maerke *'),
                    items: maerker
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedMaerke = v!),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  SkaInput(
                    label: 'Model',
                    controller: modelController,
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  SkaInput(
                    label: 'Serienummer',
                    controller: serieController,
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status *'),
                    items: statuses
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedStatus = v!),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  SkaInput(
                    label: 'Note',
                    controller: noteController,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            SkaButton(
              onPressed: () => Navigator.pop(context),
              variant: ButtonVariant.ghost,
              text: 'Annuller',
            ),
            SkaButton(
              onPressed: () async {
                if (formKey.currentState?.validate() == true) {
                  final now = DateTime.now().toIso8601String();
                  final newAffugter = Affugter(
                    id: affugter?.id ?? _dbService.generateId(),
                    nr: nrController.text,
                    type: selectedType,
                    maerke: selectedMaerke,
                    model: modelController.text.isEmpty ? null : modelController.text,
                    serie: serieController.text.isEmpty ? null : serieController.text,
                    status: selectedStatus,
                    note: noteController.text.isEmpty ? null : noteController.text,
                    createdAt: affugter?.createdAt ?? now,
                    updatedAt: now,
                  );

                  if (isEdit) {
                    await _dbService.updateAffugter(newAffugter);
                  } else {
                    await _dbService.addAffugter(newAffugter);
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadAffugtere();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit ? 'Udstyr opdateret' : 'Udstyr tilfoejet'),
                      ),
                    );
                  }
                }
              },
              variant: ButtonVariant.primary,
              text: isEdit ? 'Opdater' : 'Tilfoej',
            ),
          ],
        ),
      ),
    );
  }

  List<_RangeGroup> get _rangeGroups {
    final Map<String, _RangeGroup> groups = {};
    for (final affugter in _affugtere) {
      final range = _parseRange(affugter.nr);
      if (range == null) continue;
      final label = '${range.start}-${range.end}';
      groups.update(
        label,
        (existing) => existing.copyWith(count: existing.count + 1),
        ifAbsent: () => _RangeGroup(label: label, count: 1),
      );
    }

    final result = groups.values.toList();
    result.sort((a, b) => b.count.compareTo(a.count));
    return result;
  }

  _NumberRange? _parseRange(String input) {
    final match = RegExp(r'^(\d+)\s*-\s*(\d+)$').firstMatch(input.trim());
    if (match == null) return null;
    final startText = match.group(1)!;
    final endText = match.group(2)!;
    if (startText.length != endText.length || startText.length < 2) {
      return null;
    }
    final start = int.tryParse(startText);
    final end = int.tryParse(endText);
    if (start == null || end == null || end <= start) return null;
    return _NumberRange(start: start, end: end);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final ranges = _rangeGroups;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Udstyr oversigt'),
        elevation: 0,
        actions: const [
          ThemeToggle(),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.p4,
            child: FilterBar(
              filters: [
                FilterConfig(
                  id: 'status',
                  label: 'Status',
                  type: FilterType.chip,
                  options: [
                    FilterOption(value: 'hjemme', label: 'Hjemme', color: _getStatusColor('hjemme')),
                    FilterOption(value: 'udlejet', label: 'Udlejet', color: _getStatusColor('udlejet')),
                    FilterOption(value: 'defekt', label: 'Defekt', color: _getStatusColor('defekt')),
                  ],
                  showCount: false,
                ),
              ],
              values: {'status': _filterStatus},
              onFilterChanged: (filterId, value) {
                setState(() => _filterStatus = value?.toString() ?? 'alle');
                _loadAffugtere();
              },
              onReset: () {
                setState(() => _filterStatus = 'alle');
                _loadAffugtere();
              },
            ),
          ),
          FilterResultsHeader(
            resultCount: _affugtere.length,
            itemLabel: 'udstyr',
            activeFilters: {
              if (_filterStatus != 'alle') 'status': _filterStatus,
            },
            onReset: _filterStatus != 'alle'
                ? () {
                    setState(() => _filterStatus = 'alle');
                    _loadAffugtere();
                  }
                : null,
          ),
          if (ranges.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SkaCard(
                padding: AppSpacing.p4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Range analyse', style: AppTypography.smSemibold),
                    const SizedBox(height: AppSpacing.s2),
                    Wrap(
                      spacing: AppSpacing.s2,
                      runSpacing: AppSpacing.s2,
                      children: ranges
                          .map(
                            (range) => SkaBadge(
                              text: '${range.label} (${range.count})',
                              variant: BadgeVariant.secondary,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _affugtere.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text('Ingen udstyr fundet', style: TextStyle(fontSize: 18)),
                        const SizedBox(height: 8),
                        const Text('Klik paa + for at tilfoeje udstyr'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _affugtere.length,
                    itemBuilder: (context, index) {
                      final affugter = _affugtere[index];
                      return _buildAffugterCard(affugter);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAffugterDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAffugterCard(Affugter affugter) {
    final statusColor = _getStatusColor(affugter.status);

    return SkaCard(
      padding: AppSpacing.p4,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.inventory_2_outlined, color: statusColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${affugter.maerke} - ${affugter.nr}',
                  style: AppTypography.smSemibold,
                ),
                const SizedBox(height: AppSpacing.s1),
                Text('Type: ${affugter.type}', style: AppTypography.xs.copyWith(color: theme_colors.AppColors.mutedForeground)),
                if (affugter.model != null)
                  Text('Model: ${affugter.model}', style: AppTypography.xs.copyWith(color: theme_colors.AppColors.mutedForeground)),
                if (affugter.serie != null)
                  Text('Serie: ${affugter.serie}', style: AppTypography.xs.copyWith(color: theme_colors.AppColors.mutedForeground)),
                if (affugter.note != null)
                  Text(affugter.note!, style: AppTypography.xs.copyWith(color: theme_colors.AppColors.mutedForeground)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SkaBadge.status(text: affugter.status, status: affugter.status, small: true),
              const SizedBox(height: AppSpacing.s2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _showAffugterDialog(affugter),
                    color: theme_colors.AppColors.primary,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    onPressed: () => _deleteAffugter(affugter.id),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NumberRange {
  final int start;
  final int end;

  const _NumberRange({required this.start, required this.end});
}

class _RangeGroup {
  final String label;
  final int count;

  const _RangeGroup({required this.label, required this.count});

  _RangeGroup copyWith({int? count}) => _RangeGroup(label: label, count: count ?? this.count);
}
