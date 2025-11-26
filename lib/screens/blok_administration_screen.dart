import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/blok.dart';
import '../models/blok_completion.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';

class BlokAdministrationScreen extends StatefulWidget {
  final String sagId;

  const BlokAdministrationScreen({super.key, required this.sagId});

  @override
  State<BlokAdministrationScreen> createState() => _BlokAdministrationScreenState();
}

class _BlokAdministrationScreenState extends State<BlokAdministrationScreen> {
  final _dbService = DatabaseService();
  final _authService = AuthService();
  final _uuid = const Uuid();

  List<Blok> _blokke = [];
  Map<String, List<BlokCompletion>> _completions = {};
  bool _loading = true;

  final _formKey = GlobalKey<FormState>();
  final _navnController = TextEditingController();
  final _beskrivelseController = TextEditingController();
  final _antalLejlighedeController = TextEditingController();
  final _antalM2Controller = TextEditingController();
  final _prisPrLejlighedController = TextEditingController();
  final _prisPrM2Controller = TextEditingController();
  final _slutDatoController = TextEditingController();

  String _selectedPricingModel = 'dagsleje';
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _navnController.dispose();
    _beskrivelseController.dispose();
    _antalLejlighedeController.dispose();
    _antalM2Controller.dispose();
    _prisPrLejlighedController.dispose();
    _prisPrM2Controller.dispose();
    _slutDatoController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _loading = true;
      _blokke = _dbService.getBlokkeBySag(widget.sagId);

      // Load completions
      _completions = {};
      for (var blok in _blokke) {
        _completions[blok.id] = _dbService.getBlokCompletionsByBlok(blok.id);
      }

      _loading = false;
    });
  }

  Future<void> _saveBlok() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now().toIso8601String();

    final blok = Blok(
      id: _editingId ?? _uuid.v4(),
      sagId: widget.sagId,
      navn: _navnController.text,
      beskrivelse: _beskrivelseController.text.isEmpty ? null : _beskrivelseController.text,
      pricingModel: _selectedPricingModel,
      antalLejligheder: _antalLejlighedeController.text.isEmpty ? 0 : int.parse(_antalLejlighedeController.text),
      antalM2: _antalM2Controller.text.isEmpty ? 0 : double.parse(_antalM2Controller.text),
      fastPrisPrLejlighed: _prisPrLejlighedController.text.isEmpty ? 0 : double.parse(_prisPrLejlighedController.text),
      fastPrisPrM2: _prisPrM2Controller.text.isEmpty ? 0 : double.parse(_prisPrM2Controller.text),
      faerdigmeldteLejligheder: _editingId != null ? _blokke.firstWhere((b) => b.id == _editingId).faerdigmeldteLejligheder : 0,
      faerdigmeldteM2: _editingId != null ? _blokke.firstWhere((b) => b.id == _editingId).faerdigmeldteM2 : 0,
      slutDato: _slutDatoController.text.isEmpty ? null : _slutDatoController.text,
      createdAt: _editingId != null ? _blokke.firstWhere((b) => b.id == _editingId).createdAt : now,
      updatedAt: now,
    );

    if (_editingId != null) {
      await _dbService.updateBlok(blok);
    } else {
      await _dbService.addBlok(blok);
    }

    if (mounted) {
      Navigator.pop(context);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_editingId != null ? 'Blok opdateret' : 'Blok oprettet')),
      );
    }
  }

  void _showBlokDialog([Blok? blok]) {
    _editingId = blok?.id;
    _navnController.text = blok?.navn ?? '';
    _beskrivelseController.text = blok?.beskrivelse ?? '';
    _selectedPricingModel = blok?.pricingModel ?? 'dagsleje';
    _antalLejlighedeController.text = blok != null && blok.antalLejligheder > 0 ? blok.antalLejligheder.toString() : '';
    _antalM2Controller.text = blok != null && blok.antalM2 > 0 ? blok.antalM2.toString() : '';
    _prisPrLejlighedController.text = blok != null && blok.fastPrisPrLejlighed > 0 ? blok.fastPrisPrLejlighed.toString() : '';
    _prisPrM2Controller.text = blok != null && blok.fastPrisPrM2 > 0 ? blok.fastPrisPrM2.toString() : '';
    _slutDatoController.text = blok?.slutDato ?? '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_editingId != null ? 'Rediger Blok' : 'Opret Blok'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _navnController,
                    decoration: const InputDecoration(
                      labelText: 'Blok Navn *',
                      hintText: 'f.eks. Blok A - Kælder',
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Påkrævet' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _beskrivelseController,
                    decoration: const InputDecoration(
                      labelText: 'Beskrivelse',
                      hintText: 'Valgfri beskrivelse',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedPricingModel,
                    decoration: const InputDecoration(labelText: 'Prismodel *'),
                    items: const [
                      DropdownMenuItem(value: 'dagsleje', child: Text('Dagsleje (individuelle priser)')),
                      DropdownMenuItem(value: 'fast_pris_per_lejlighed', child: Text('Fast pris pr. lejlighed')),
                      DropdownMenuItem(value: 'fast_pris_per_m2', child: Text('Fast pris pr. m²')),
                    ],
                    onChanged: (value) {
                      setDialogState(() => _selectedPricingModel = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedPricingModel == 'fast_pris_per_lejlighed') ...[
                    TextFormField(
                      controller: _antalLejlighedeController,
                      decoration: const InputDecoration(labelText: 'Antal Lejligheder'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _prisPrLejlighedController,
                      decoration: const InputDecoration(labelText: 'Fast Pris pr. Lejlighed (DKK)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_selectedPricingModel == 'fast_pris_per_m2') ...[
                    TextFormField(
                      controller: _antalM2Controller,
                      decoration: const InputDecoration(labelText: 'Antal m²'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _prisPrM2Controller,
                      decoration: const InputDecoration(labelText: 'Fast Pris pr. m² (DKK)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _slutDatoController,
                    decoration: const InputDecoration(
                      labelText: 'Slutdato (valgfri)',
                      hintText: 'dd-mm-åååå',
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setDialogState(() {
                          _slutDatoController.text = date.toIso8601String().split('T')[0];
                        });
                      }
                    },
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
              onPressed: _saveBlok,
              child: const Text('Gem'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteBlok(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slet blok'),
        content: const Text('Er du sikker på at du vil slette denne blok?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuller'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Slet'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbService.deleteBlok(id);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Blok slettet')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_blokke.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('Ingen blokke oprettet', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      const Text('Opret blokke for at organisere udstyr og administrere priser'),
                    ],
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    onPressed: () => _showBlokDialog(),
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _blokke.length,
                  itemBuilder: (context, index) {
            final blok = _blokke[index];
            final completions = _completions[blok.id] ?? [];
            final progress = blok.calculateProgress();

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: const Icon(Icons.business, color: AppColors.primary),
                    title: Text(blok.navn, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: blok.beskrivelse != null ? Text(blok.beskrivelse!) : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showBlokDialog(blok),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () => _deleteBlok(blok.id),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (blok.slutDato != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Colors.green),
                                const SizedBox(width: 4),
                                Text('Slutdato: ${blok.slutDato}', style: const TextStyle(color: Colors.green)),
                              ],
                            ),
                          ),
                        _buildBlokContent(blok, completions, progress),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  onPressed: () => _showBlokDialog(),
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBlokContent(Blok blok, List<BlokCompletion> completions, double progress) {
    if (blok.pricingModel == 'dagsleje') {
      return const Text('Dagsleje - individuelle priser på udstyr');
    }

    final isLejligheder = blok.pricingModel == 'fast_pris_per_lejlighed';
    final total = isLejligheder ? blok.antalLejligheder : blok.antalM2;
    final completed = isLejligheder ? blok.faerdigmeldteLejligheder : blok.faerdigmeldteM2;
    final pris = isLejligheder ? blok.fastPrisPrLejlighed : blok.fastPrisPrM2;
    final enhed = isLejligheder ? 'lejligheder' : 'm²';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${isLejligheder ? "Fast pris pr. lejlighed" : "Fast pris pr. m²"}'),
        const SizedBox(height: 8),
        Text('Total: $total $enhed'),
        Text('Pris pr. $enhed: ${pris.toStringAsFixed(2)} DKK'),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('Færdigmeldte: '),
            Text('$completed / $total', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: total > 0 ? completed / total : 0,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
        ),
        const SizedBox(height: 4),
        Text('${progress.toStringAsFixed(1)}% færdig', style: const TextStyle(fontSize: 12)),
        if (completions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Seneste: ${completions.first.completionDate}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => _showCompletionDialog(blok),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Færdigmeld'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 36),
          ),
        ),
        if (completions.isNotEmpty)
          TextButton.icon(
            onPressed: () => _showHistoryDialog(blok, completions),
            icon: const Icon(Icons.history, size: 16),
            label: const Text('Se historik'),
          ),
      ],
    );
  }

  void _showCompletionDialog(Blok blok) {
    final amountController = TextEditingController();
    final dateController = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
    final noteController = TextEditingController();
    final slutDatoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Færdigmeld ${blok.pricingModel == "fast_pris_per_lejlighed" ? "Lejligheder" : "M²"}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Antal ${blok.pricingModel == "fast_pris_per_lejlighed" ? "lejligheder" : "m²"} *',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: dateController,
                decoration: const InputDecoration(labelText: 'Færdigmeldt dato *'),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    dateController.text = date.toIso8601String().split('T')[0];
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: slutDatoController,
                decoration: const InputDecoration(
                  labelText: 'Blok slutdato (valgfri)',
                  hintText: 'Sæt hvis blokken er helt færdig',
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    slutDatoController.text = date.toIso8601String().split('T')[0];
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note (valgfri)'),
                maxLines: 3,
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
            onPressed: () async {
              if (amountController.text.isEmpty || dateController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Udfyld venligst alle påkrævede felter')),
                );
                return;
              }

              final amount = double.parse(amountController.text);
              final isLejligheder = blok.pricingModel == 'fast_pris_per_lejlighed';
              final currentTotal = isLejligheder ? blok.faerdigmeldteLejligheder.toDouble() : blok.faerdigmeldteM2;
              final maxAmount = isLejligheder ? blok.antalLejligheder.toDouble() : blok.antalM2;

              if (currentTotal + amount > maxAmount) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Du kan maksimalt færdigmelde ${maxAmount - currentTotal} mere')),
                );
                return;
              }

              // Create completion
              final completion = BlokCompletion(
                id: _uuid.v4(),
                blokId: blok.id,
                sagId: widget.sagId,
                completionDate: dateController.text,
                completionType: isLejligheder ? 'lejligheder' : 'm2',
                previousAmount: currentTotal,
                newAmount: currentTotal + amount,
                amountCompleted: amount,
                user: _authService.currentUser?.name ?? 'Ukendt',
                note: noteController.text.isEmpty ? null : noteController.text,
                createdAt: DateTime.now().toIso8601String(),
              );

              await _dbService.addBlokCompletion(completion);

              // Update blok
              final updatedBlok = Blok(
                id: blok.id,
                sagId: blok.sagId,
                navn: blok.navn,
                beskrivelse: blok.beskrivelse,
                pricingModel: blok.pricingModel,
                antalLejligheder: blok.antalLejligheder,
                antalM2: blok.antalM2,
                fastPrisPrLejlighed: blok.fastPrisPrLejlighed,
                fastPrisPrM2: blok.fastPrisPrM2,
                faerdigmeldteLejligheder: isLejligheder ? (currentTotal + amount).toInt() : blok.faerdigmeldteLejligheder,
                faerdigmeldteM2: !isLejligheder ? currentTotal + amount : blok.faerdigmeldteM2,
                slutDato: slutDatoController.text.isEmpty ? blok.slutDato : slutDatoController.text,
                createdAt: blok.createdAt,
                updatedAt: DateTime.now().toIso8601String(),
              );

              await _dbService.updateBlok(updatedBlok);

              if (mounted) {
                Navigator.pop(context);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Færdigmelding registreret')),
                );
              }
            },
            child: const Text('Færdigmeld'),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog(Blok blok, List<BlokCompletion> completions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Færdigmeldings Historik - ${blok.navn}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: completions.length,
            itemBuilder: (context, index) {
              final completion = completions[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text('${completion.amountCompleted} ${completion.completionType} færdigmeldt'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dato: ${completion.completionDate}'),
                      Text('Bruger: ${completion.user}'),
                      if (completion.note != null) Text('Note: ${completion.note}'),
                      Text('Fra ${completion.previousAmount} til ${completion.newAmount} ${completion.completionType}'),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Luk'),
          ),
        ],
      ),
    );
  }
}
