import 'package:flutter/material.dart';
import '../models/app_setting.dart';
import '../services/settings_service.dart';
import '../providers/theme_provider.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dropdown Indstillinger'),
        actions: [
          if (_selectedCategory != null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addNewOption,
              tooltip: 'Tilføj ny valgmulighed',
            ),
        ],
      ),
      body: Row(
        children: [
          // Category sidebar
          Container(
            width: 250,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade100,
                  child: const Row(
                    children: [
                      Icon(Icons.category, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Kategorier',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: SettingCategory.all.length,
                    itemBuilder: (context, index) {
                      final category = SettingCategory.all[index];
                      final isSelected = _selectedCategory == category;
                      final count = _settingsService.getSettingsByCategory(category).length;

                      return ListTile(
                        title: Text(
                          SettingCategory.getDisplayName(category),
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            count.toString(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        selected: isSelected,
                        selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
                        onTap: () => _selectCategory(category),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Content area
          Expanded(
            child: _selectedCategory == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Vælg en kategori fra listen',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : _loading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        SettingCategory.getDisplayName(_selectedCategory!),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${_settings.length} valgmuligheder',
                                        style: TextStyle(color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _addNewOption,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Tilføj ny'),
                                ),
                              ],
                            ),
                          ),

                          // Options list
                          Expanded(
                            child: _settings.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Ingen valgmuligheder i denne kategori',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : ReorderableListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _settings.length,
                                    onReorder: (oldIndex, newIndex) async {
                                      if (newIndex > oldIndex) newIndex--;
                                      final item = _settings.removeAt(oldIndex);
                                      _settings.insert(newIndex, item);

                                      // Update order in database
                                      final orderedIds = _settings.map((s) => s.id).toList();
                                      await _settingsService.reorderSettings(
                                        _selectedCategory!,
                                        orderedIds,
                                      );
                                      setState(() {});
                                    },
                                    itemBuilder: (context, index) {
                                      final setting = _settings[index];
                                      return Card(
                                        key: ValueKey(setting.id),
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          leading: ReorderableDragStartListener(
                                            index: index,
                                            child: const Icon(Icons.drag_handle),
                                          ),
                                          title: Text(
                                            setting.displayLabel,
                                            style: TextStyle(
                                              decoration: setting.isActive
                                                  ? null
                                                  : TextDecoration.lineThrough,
                                              color: setting.isActive
                                                  ? null
                                                  : Colors.grey,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (setting.value != setting.displayLabel)
                                                Text(
                                                  'Værdi: ${setting.value}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              Row(
                                                children: [
                                                  if (setting.isDefault)
                                                    Container(
                                                      margin: const EdgeInsets.only(right: 8),
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue.shade100,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: const Text(
                                                        'Standard',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.blue,
                                                        ),
                                                      ),
                                                    ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: setting.isActive
                                                          ? Colors.green.shade100
                                                          : Colors.red.shade100,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      setting.isActive ? 'Aktiv' : 'Inaktiv',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: setting.isActive
                                                            ? Colors.green
                                                            : Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  setting.isActive
                                                      ? Icons.visibility
                                                      : Icons.visibility_off,
                                                  color: setting.isActive
                                                      ? Colors.green
                                                      : Colors.grey,
                                                ),
                                                onPressed: () => _toggleActive(setting),
                                                tooltip: setting.isActive
                                                    ? 'Deaktiver'
                                                    : 'Aktiver',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.edit),
                                                onPressed: () => _editOption(setting),
                                                tooltip: 'Rediger',
                                              ),
                                              if (!setting.isDefault)
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () => _deleteOption(setting),
                                                  tooltip: 'Slet',
                                                ),
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
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _valueController,
              decoration: const InputDecoration(
                labelText: 'Værdi *',
                hintText: 'Intern værdi (bruges i koden)',
                border: OutlineInputBorder(),
              ),
              enabled: !isEditing, // Don't allow editing value after creation
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Visningsnavn',
                hintText: 'Tekst vist i dropdown (valgfri)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hvis visningsnavn er tomt, bruges værdien som visningsnavn.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuller'),
        ),
        ElevatedButton(
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
          child: Text(isEditing ? 'Gem' : 'Tilføj'),
        ),
      ],
    );
  }
}
