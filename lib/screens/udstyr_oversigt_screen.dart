import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/affugter.dart';
import '../providers/theme_provider.dart';

class UdstyrsOversightScreen extends StatefulWidget {
  const UdstyrsOversightScreen({super.key});

  @override
  State<UdstyrsOversightScreen> createState() => _UdstyrsOversightScreenState();
}

class _UdstyrsOversightScreenState extends State<UdstyrsOversightScreen> {
  final _dbService = DatabaseService();
  late List<Affugter> _affugtere;
  String _filterStatus = 'alle';
  bool _loading = true;

  final List<String> _statuses = ['alle', 'hjemme', 'udlejet', 'defekt'];

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
        return AppColors.statusHjemme;
      case 'udlejet':
        return AppColors.statusUdlejet;
      case 'defekt':
        return AppColors.statusDefekt;
      default:
        return Colors.grey;
    }
  }

  Future<void> _deleteAffugter(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slet udstyr'),
        content: const Text('Er du sikker på, at du vil slette dette udstyr?'),
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

    String selectedType = affugter?.type ?? 'adsorption';
    String selectedMaerke = affugter?.maerke ?? 'Master';
    String selectedStatus = affugter?.status ?? 'hjemme';

    final types = ['adsorption', 'kondens'];
    final maerker = ['Master', 'Fral', 'Qube', 'Andet'];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Rediger udstyr' : 'Tilføj udstyr'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nrController,
                    decoration: const InputDecoration(
                      labelText: 'Nummer *',
                      hintText: '2-0001',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v?.isEmpty == true ? 'Påkrævet' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type *',
                      border: OutlineInputBorder(),
                    ),
                    items: types
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedType = v!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedMaerke,
                    decoration: const InputDecoration(
                      labelText: 'Mærke *',
                      border: OutlineInputBorder(),
                    ),
                    items: maerker
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedMaerke = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: modelController,
                    decoration: const InputDecoration(
                      labelText: 'Model',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: serieController,
                    decoration: const InputDecoration(
                      labelText: 'Serienummer',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status *',
                      border: OutlineInputBorder(),
                    ),
                    items: ['hjemme', 'udlejet', 'defekt']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedStatus = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
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
            ElevatedButton(
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
                        content: Text(isEdit ? 'Udstyr opdateret' : 'Udstyr tilføjet'),
                      ),
                    );
                  }
                }
              },
              child: Text(isEdit ? 'Opdater' : 'Tilføj'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Udstyr Oversigt'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: _statuses
                  .map(
                    (status) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(status.toUpperCase()),
                        selected: _filterStatus == status,
                        onSelected: (selected) {
                          setState(() => _filterStatus = status);
                          _loadAffugtere();
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          // List
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
                        const Text('Klik på + for at tilføje udstyr'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _affugtere.length,
                    itemBuilder: (context, index) {
                      final affugter = _affugtere[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.inventory_2, color: AppColors.primary),
                              title: Text(
                                '${affugter.maerke} - ${affugter.nr}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('Type: ${affugter.type}'),
                                  if (affugter.model != null)
                                    Text('Model: ${affugter.model}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Chip(
                                    label: Text(affugter.status),
                                    backgroundColor:
                                        _getStatusColor(affugter.status).withValues(alpha: 0.2),
                                    labelStyle: TextStyle(
                                      color: _getStatusColor(affugter.status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _showAffugterDialog(affugter),
                                    color: AppColors.primary,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                    onPressed: () => _deleteAffugter(affugter.id),
                                  ),
                                ],
                              ),
                            ),
                            if (affugter.serie != null || affugter.note != null)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (affugter.serie != null)
                                      Text(
                                        'Serie: ${affugter.serie}',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    if (affugter.note != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        affugter.note!,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
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
}
