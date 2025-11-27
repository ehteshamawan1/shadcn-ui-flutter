import 'package:flutter/material.dart';
import '../models/sag.dart';
import '../models/kabel_slange_log.dart';
import '../services/database_service.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../widgets/filter_widget.dart';

class KablerSlangerScreen extends StatefulWidget {
  final Sag sag;

  const KablerSlangerScreen({super.key, required this.sag});

  @override
  State<KablerSlangerScreen> createState() => _KablerSlangerScreenState();
}

class _KablerSlangerScreenState extends State<KablerSlangerScreen> {
  final DatabaseService _db = DatabaseService();
  bool _loading = true;
  String _categoryFilter = 'alle'; // 'alle', 'slanger', 'kabler'

  final List<String> _slangeTypes = [
    'Varmtvandsslange ø32',
    'Varmtvandsslange ø50',
    'Flexslange ø127',
    'Flexslange ø102',
    'Flexslange ø152',
    'Poseslange ø200',
    'Poseslange ø250',
    'Poseslange ø315',
    'Andet',
  ];

  final List<String> _kabelTypes = [
    '230V kabel',
    '16 A kabel',
    '32 A kabel',
    '63 A kabel',
    '16 A tavle',
    '32 A tavle',
    '63 A tavle',
    '16 A split',
    '16/32 overgang',
    '32/63 overgang',
    '16/230 stikprop',
    'CEE230/230 prop',
    'Forlængerkabel',
    'Netværkskabel',
    'Andet',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _loading = false;
    });
  }

  List<KabelSlangeLog> _getLogs() {
    final allLogs = _db.getKabelSlangeLogsBySag(widget.sag.id);
    if (_categoryFilter == 'alle') return allLogs;
    return allLogs.where((log) => log.category == _categoryFilter).toList();
  }

  List<KabelSlangeLog> _getAllLogs() {
    return _db.getKabelSlangeLogsBySag(widget.sag.id);
  }

  Future<void> _deleteLog(KabelSlangeLog log) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slet registrering'),
        content: const Text('Er du sikker på at du vil slette denne registrering?'),
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
      await _db.deleteKabelSlangeLog(log.id);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrering slettet')),
        );
      }
    }
  }

  Future<void> _showAddDialog() async {
    String category = 'slanger'; // Default
    String? selectedType;
    String? customType;
    final metersController = TextEditingController();
    final pricePerMeterController = TextEditingController(text: '15');
    final quantityController = TextEditingController();
    final noteController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tilføj Kabel eller Slange'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category selector
                const Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Slange'),
                        value: 'slanger',
                        groupValue: category,
                        onChanged: (value) {
                          setDialogState(() {
                            category = value!;
                            selectedType = null;
                            customType = null;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Kabel'),
                        value: 'kabler',
                        groupValue: category,
                        onChanged: (value) {
                          setDialogState(() {
                            category = value!;
                            selectedType = null;
                            customType = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Type dropdown
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type *',
                    border: OutlineInputBorder(),
                  ),
                  items: (category == 'slanger' ? _slangeTypes : _kabelTypes)
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedType = value;
                      if (value != 'Andet') customType = null;
                    });
                  },
                ),
                if (selectedType == 'Andet') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Angiv type *',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => customType = value,
                  ),
                ],
                const SizedBox(height: 16),
                // Category-specific fields
                if (category == 'slanger') ...[
                  TextFormField(
                    controller: metersController,
                    decoration: const InputDecoration(
                      labelText: 'Antal meter *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: pricePerMeterController,
                    decoration: const InputDecoration(
                      labelText: 'Pris pr. meter (DKK)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ] else ...[
                  TextFormField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Antal *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (valgfri)',
                    border: OutlineInputBorder(),
                  ),
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
                if (selectedType == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vælg en type')),
                  );
                  return;
                }

                if (category == 'slanger') {
                  final meters = double.tryParse(metersController.text);
                  if (meters == null || meters <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Indtast antal meter')),
                    );
                    return;
                  }

                  final pricePerMeter = double.tryParse(pricePerMeterController.text) ?? 15.0;
                  final totalPrice = meters * pricePerMeter;

                  final log = KabelSlangeLog(
                    id: _db.generateId(),
                    sagId: widget.sag.id,
                    category: 'slanger',
                    type: selectedType!,
                    customType: selectedType == 'Andet' ? customType : null,
                    meters: meters,
                    pricePerMeter: pricePerMeter,
                    totalPrice: totalPrice,
                    note: noteController.text.isEmpty ? null : noteController.text,
                    user: AuthService().currentUser?.name,
                    timestamp: DateTime.now().toIso8601String(),
                  );

                  await _db.addKabelSlangeLog(log);
                } else {
                  final quantity = int.tryParse(quantityController.text);
                  if (quantity == null || quantity <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Indtast antal')),
                    );
                    return;
                  }

                  final log = KabelSlangeLog(
                    id: _db.generateId(),
                    sagId: widget.sag.id,
                    category: 'kabler',
                    type: selectedType!,
                    customType: selectedType == 'Andet' ? customType : null,
                    quantity: quantity,
                    note: noteController.text.isEmpty ? null : noteController.text,
                    user: AuthService().currentUser?.name,
                    timestamp: DateTime.now().toIso8601String(),
                  );

                  await _db.addKabelSlangeLog(log);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tilføjet')),
                  );
                }
              },
              child: const Text('Tilføj'),
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

    final logs = _getLogs();
    final allLogs = _getAllLogs();
    final slangerCount = allLogs.where((log) => log.category == 'slanger').length;
    final kablerCount = allLogs.where((log) => log.category == 'kabler').length;

    final slangerLogs = allLogs.where((log) => log.category == 'slanger').toList();
    final kablerLogs = allLogs.where((log) => log.category == 'kabler').toList();

    final totalMeters = slangerLogs.fold(0.0, (sum, log) => sum + (log.meters ?? 0));
    final totalKabler = kablerLogs.fold(0, (sum, log) => sum + (log.quantity ?? 0));
    final totalValue = slangerLogs.fold(0.0, (sum, log) => sum + (log.totalPrice ?? 0));

    return Stack(
      children: [
        Column(
          children: [
            // Stats cards
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Slanger (m)',
                      totalMeters.toStringAsFixed(1),
                      Icons.straighten,
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Kabler (stk)',
                      totalKabler.toString(),
                      Icons.cable,
                      AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Værdi (DKK)',
                      totalValue.toStringAsFixed(0),
                      Icons.attach_money,
                      AppColors.success,
                    ),
                  ),
                ],
              ),
            ),

            // Standardized Filter Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilterBar(
                filters: [
                  FilterConfig(
                    id: 'category',
                    label: 'Kategori',
                    type: FilterType.chip,
                    options: [
                      FilterOption(value: 'slanger', label: 'Slanger', count: slangerCount, icon: Icons.straighten, color: AppColors.primary),
                      FilterOption(value: 'kabler', label: 'Kabler', count: kablerCount, icon: Icons.cable, color: AppColors.info),
                    ],
                  ),
                ],
                values: {'category': _categoryFilter},
                onFilterChanged: (filterId, value) {
                  setState(() => _categoryFilter = value?.toString() ?? 'alle');
                },
                onReset: () {
                  setState(() => _categoryFilter = 'alle');
                },
              ),
            ),

            // Results Header
            FilterResultsHeader(
              resultCount: logs.length,
              itemLabel: 'poster',
              activeFilters: {
                if (_categoryFilter != 'alle') 'kategori': _categoryFilter == 'slanger' ? 'Slanger' : 'Kabler',
              },
              onReset: _categoryFilter != 'alle'
                  ? () => setState(() => _categoryFilter = 'alle')
                  : null,
            ),

            // Empty state or List
            if (logs.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cable, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _categoryFilter != 'alle'
                            ? 'Ingen ${_categoryFilter == 'slanger' ? 'slanger' : 'kabler'} fundet'
                            : 'Ingen kabler og slanger oprettet',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      const Text('Klik på + for at oprette'),
                    ],
                  ),
                ),
              )
            else
            // List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final displayType = log.type == 'Andet' && log.customType != null
                      ? log.customType!
                      : log.type;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: Icon(
                            log.category == 'slanger' ? Icons.straighten : Icons.cable,
                            color: log.category == 'slanger' ? AppColors.primary : AppColors.info,
                          ),
                          title: Text(
                            displayType,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            log.category == 'slanger' ? 'Slange' : 'Kabel',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                onPressed: () => _deleteLog(log),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (log.category == 'slanger') ...[
                                Text('Meter: ${log.meters?.toStringAsFixed(1) ?? 'N/A'}'),
                                Text('Pris pr. meter: ${log.pricePerMeter?.toStringAsFixed(0) ?? 'N/A'} DKK'),
                                const SizedBox(height: 4),
                                Text(
                                  'Total: ${log.totalPrice?.toStringAsFixed(0) ?? 'N/A'} DKK',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    fontSize: 16,
                                  ),
                                ),
                              ] else ...[
                                Text('Antal: ${log.quantity ?? 'N/A'}'),
                                const SizedBox(height: 4),
                                const Text(
                                  'Gratis',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                              if (log.note != null && log.note!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Note: ${log.note}',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                'Af ${log.user ?? 'Unknown'} - ${_formatTimestamp(log.timestamp)}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
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
            onPressed: _showAddDialog,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }
}
