import 'package:flutter/material.dart';
import '../models/affugter.dart';
import '../services/database_service.dart';
import '../providers/theme_provider.dart';

class SagUdstyrsScreen extends StatefulWidget {
  final String sagId;

  const SagUdstyrsScreen({super.key, required this.sagId});

  @override
  State<SagUdstyrsScreen> createState() => _SagUdstyrsScreenState();
}

class _SagUdstyrsScreenState extends State<SagUdstyrsScreen> {
  final _dbService = DatabaseService();
  List<Affugter> _udstyrsListe = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUdstyr();
  }

  void _loadUdstyr() {
    setState(() {
      _loading = true;
    });

    // Get all affugtere where currentSagId matches this sag
    final alleAffugtere = _dbService.getAllAffugtere();
    final sagsUdstyr = alleAffugtere.where((a) => a.currentSagId == widget.sagId).toList();
    sagsUdstyr.sort((a, b) => a.nr.compareTo(b.nr));

    setState(() {
      _udstyrsListe = sagsUdstyr;
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

  Future<void> _showTilknytUdstyrsDialog() async {
    // Get all available affugtere (not currently assigned to another sag)
    final alleAffugtere = _dbService.getAllAffugtere();
    final tilgaengelige = alleAffugtere.where((a) => a.currentSagId == null || a.currentSagId == widget.sagId).toList();

    if (tilgaengelige.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingen ledigt udstyr tilgængeligt')),
        );
      }
      return;
    }

    final selected = await showDialog<List<String>>(
      context: context,
      builder: (context) => _TilknytUdstyrsDialog(
        tilgaengelige: tilgaengelige,
        alleredeValgte: _udstyrsListe.map((e) => e.id).toList(),
      ),
    );

    if (selected != null && mounted) {
      // Update selected affugtere to have currentSagId
      for (final id in selected) {
        final affugter = await _dbService.getAffugter(id);
        if (affugter != null) {
          final updated = Affugter(
            id: affugter.id,
            nr: affugter.nr,
            type: affugter.type,
            maerke: affugter.maerke,
            model: affugter.model,
            serie: affugter.serie,
            status: 'udlejet',
            currentSagId: widget.sagId,
            note: affugter.note,
            createdAt: affugter.createdAt,
            updatedAt: DateTime.now().toIso8601String(),
          );
          await _dbService.updateAffugter(updated);
        }
      }

      _loadUdstyr();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selected.length} udstyr tilknyttet')),
        );
      }
    }
  }

  Future<void> _fjernUdstyr(Affugter affugter) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fjern udstyr fra sag'),
        content: Text('Vil du fjerne ${affugter.maerke} - ${affugter.nr} fra denne sag?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuller'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Fjern'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final updated = Affugter(
        id: affugter.id,
        nr: affugter.nr,
        type: affugter.type,
        maerke: affugter.maerke,
        model: affugter.model,
        serie: affugter.serie,
        status: 'hjemme',
        currentSagId: null,
        note: affugter.note,
        createdAt: affugter.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
      );
      await _dbService.updateAffugter(updated);
      _loadUdstyr();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Udstyr fjernet fra sag')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        if (_udstyrsListe.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('Intet udstyr tilknyttet denne sag', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                const Text('Klik på + for at tilknytte udstyr'),
              ],
            ),
          )
        else
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.inventory_2, color: AppColors.primary, size: 32),
                              const SizedBox(height: 8),
                              Text(
                                _udstyrsListe.length.toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text('Udstyr i alt', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.check_circle, color: AppColors.success, size: 32),
                              const SizedBox(height: 8),
                              Text(
                                _udstyrsListe.where((a) => a.status == 'udlejet').length.toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text('Udlejet', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _udstyrsListe.length,
                  itemBuilder: (context, index) {
                    final affugter = _udstyrsListe[index];
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
                                if (affugter.model != null) Text('Model: ${affugter.model}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Chip(
                                  label: Text(affugter.status),
                                  backgroundColor: _getStatusColor(affugter.status).withValues(alpha: 0.2),
                                  labelStyle: TextStyle(
                                    color: _getStatusColor(affugter.status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle, size: 20, color: Colors.red),
                                  onPressed: () => _fjernUdstyr(affugter),
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
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _showTilknytUdstyrsDialog,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _TilknytUdstyrsDialog extends StatefulWidget {
  final List<Affugter> tilgaengelige;
  final List<String> alleredeValgte;

  const _TilknytUdstyrsDialog({
    required this.tilgaengelige,
    required this.alleredeValgte,
  });

  @override
  State<_TilknytUdstyrsDialog> createState() => _TilknytUdstyrsDialogState();
}

class _TilknytUdstyrsDialogState extends State<_TilknytUdstyrsDialog> {
  late Set<String> _valgte;

  @override
  void initState() {
    super.initState();
    _valgte = Set.from(widget.alleredeValgte);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tilknyt udstyr til sag'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.tilgaengelige.length,
          itemBuilder: (context, index) {
            final affugter = widget.tilgaengelige[index];
            final isSelected = _valgte.contains(affugter.id);

            return CheckboxListTile(
              title: Text('${affugter.maerke} - ${affugter.nr}'),
              subtitle: Text('${affugter.type} • ${affugter.status}'),
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _valgte.add(affugter.id);
                  } else {
                    _valgte.remove(affugter.id);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuller'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _valgte.toList()),
          child: Text('Tilknyt (${_valgte.length})'),
        ),
      ],
    );
  }
}
