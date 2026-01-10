import 'package:flutter/material.dart';
import '../models/app_setting.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ui/ska_button.dart';
import '../widgets/ui/ska_card.dart';
import '../widgets/ui/ska_input.dart';

/// Admin screen for managing dropdown/listbox options
class DropdownSettingsScreen extends StatefulWidget {
  const DropdownSettingsScreen({super.key});

  @override
  State<DropdownSettingsScreen> createState() => _DropdownSettingsScreenState();
}

class _DropdownSettingsScreenState extends State<DropdownSettingsScreen> {
  final _settingsService = SettingsService();
  String? _selectedCategory;
  List<AppSetting> _settings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);

    // Make sure settings service is initialized
    await _settingsService.init();

    if (_selectedCategory != null) {
      _settings = _settingsService.getSettingsByCategory(_selectedCategory!);
    } else {
      _settings = [];
    }

    setState(() => _loading = false);
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _settings = _settingsService.getSettingsByCategory(category);
    });
  }

  Future<void> _addNewOption() async {
    if (_selectedCategory == null) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _AddEditOptionDialog(
        category: _selectedCategory!,
      ),
    );

    if (result != null && mounted) {
      await _settingsService.addSetting(
        category: _selectedCategory!,
        value: result['value']!,
        label: result['label'],
      );
      _loadSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valgmulighed tilføjet')),
      );
    }
  }

  Future<void> _editOption(AppSetting setting) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _AddEditOptionDialog(
        category: setting.category,
        existingValue: setting.value,
        existingLabel: setting.label,
      ),
    );

    if (result != null && mounted) {
      final updated = setting.copyWith(
        value: result['value'],
        label: result['label'],
      );
      await _settingsService.updateSetting(updated);
      _loadSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valgmulighed opdateret')),
      );
    }
  }

  Future<void> _deleteOption(AppSetting setting) async {
    if (setting.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Standard valgmuligheder kan ikke slettes'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slet valgmulighed'),
        content: Text('Er du sikker på at du vil slette "${setting.displayLabel}"?'),
        actions: [
          SkaButton(
            text: 'Annuller',
            variant: ButtonVariant.secondary,
            onPressed: () => Navigator.pop(context, false),
          ),
          SkaButton(
            text: 'Slet',
            variant: ButtonVariant.destructive,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _settingsService.deleteSetting(setting.id);
      _loadSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valgmulighed slettet')),
      );
    }
  }

  Future<void> _toggleActive(AppSetting setting) async {
    final updated = setting.copyWith(isActive: !setting.isActive);
    await _settingsService.updateSetting(updated);
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    final categories = SettingCategory.all;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dropdown indstillinger'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s3),
            child: SkaButton(
              text: 'Tilføj',
              size: ButtonSize.sm,
              onPressed: _selectedCategory == null ? null : _addNewOption,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: AppSpacing.p4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkaCard(
              padding: EdgeInsets.zero,
              child: Padding(
                padding: AppSpacing.p4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kategori', style: AppTypography.smSemibold),
                    const SizedBox(height: AppSpacing.s2),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(SettingCategory.getDisplayName(category)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        _selectCategory(value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedCategory == null
                      ? _buildEmptyState('Vaelg en kategori for at se valgmuligheder.')
                      : _settings.isEmpty
                          ? _buildEmptyState('Ingen valgmuligheder i denne kategori.')
                          : ListView.separated(
                              itemCount: _settings.length,
                              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s3),
                              itemBuilder: (context, index) => _buildSettingCard(_settings[index]),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Text(
        message,
        style: AppTypography.sm.copyWith(color: AppColors.mutedForeground),
      ),
    );
  }

  Widget _buildSettingCard(AppSetting setting) {
    return SkaCard(
      padding: AppSpacing.p3,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(setting.displayLabel, style: AppTypography.smSemibold),
                const SizedBox(height: AppSpacing.s1),
                Text(setting.value, style: AppTypography.xs.copyWith(color: AppColors.mutedForeground)),
              ],
            ),
          ),
          Switch(
            value: setting.isActive,
            onChanged: (_) => _toggleActive(setting),
            activeColor: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.s2),
          SkaButton(
            variant: ButtonVariant.outline,
            size: ButtonSize.sm,
            icon: const Icon(Icons.edit, size: 14),
            text: 'Rediger',
            onPressed: () => _editOption(setting),
          ),
          const SizedBox(width: AppSpacing.s2),
          SkaButton(
            variant: ButtonVariant.destructive,
            size: ButtonSize.sm,
            icon: const Icon(Icons.delete_outline, size: 14),
            text: 'Slet',
            onPressed: () => _deleteOption(setting),
          ),
        ],
      ),
    );
  }
}

/// Dialog for adding/editing dropdown options
class _AddEditOptionDialog extends StatefulWidget {
  final String category;
  final String? existingValue;
  final String? existingLabel;

  const _AddEditOptionDialog({
    required this.category,
    this.existingValue,
    this.existingLabel,
  });

  @override
  State<_AddEditOptionDialog> createState() => _AddEditOptionDialogState();
}

class _AddEditOptionDialogState extends State<_AddEditOptionDialog> {
  late TextEditingController _valueController;
  late TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(text: widget.existingValue);
    _labelController = TextEditingController(text: widget.existingLabel);
  }

  @override
  void dispose() {
    _valueController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingValue != null;

    return AlertDialog(
      title: Text(isEditing ? 'Rediger valgmulighed' : 'Tilføj ny valgmulighed'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kategori: ${SettingCategory.getDisplayName(widget.category)}',
              style: AppTypography.xs.copyWith(color: AppColors.mutedForeground),
            ),
            const SizedBox(height: AppSpacing.s4),
            SkaInput(
              label: 'Værdi *',
              placeholder: 'Intern vaerdi (bruges i koden)',
              controller: _valueController,
              enabled: !isEditing,
            ),
            const SizedBox(height: AppSpacing.s4),
            SkaInput(
              label: 'Visningsnavn',
              placeholder: 'Tekst vist i dropdown (valgfri)',
              controller: _labelController,
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              'Hvis visningsnavn er tomt, bruges vaerdien som visningsnavn.',
              style: AppTypography.xs.copyWith(color: AppColors.mutedForeground),
            ),
          ],
        ),
      ),
      actions: [
        SkaButton(
          onPressed: () => Navigator.pop(context),
          variant: ButtonVariant.ghost,
          text: 'Annuller',
        ),
        SkaButton(
          onPressed: () {
            if (_valueController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Værdi er påkrævet')),
              );
              return;
            }
            Navigator.pop(context, {
              'value': _valueController.text.trim(),
              'label': _labelController.text.trim().isEmpty
                  ? null
                  : _labelController.text.trim(),
            });
          },
          variant: ButtonVariant.primary,
          text: isEditing ? 'Gem' : 'Tilføj',
        ),
      ],
    );
  }
}
