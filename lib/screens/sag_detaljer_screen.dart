import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/sag.dart';
import '../models/timer_log.dart';
import '../models/equipment_log.dart';
import '../models/sag_message.dart';
import '../models/activity_log.dart';
import '../providers/theme_provider.dart';
import 'blok_administration_screen.dart';
import 'kabler_slanger_screen.dart';
import 'sag_udstyr_screen.dart';

class SagDetaljerScreen extends StatefulWidget {
  final String sagId;

  const SagDetaljerScreen({required this.sagId, super.key});

  @override
  State<SagDetaljerScreen> createState() => _SagDetaljerScreenState();
}

class _SagDetaljerScreenState extends State<SagDetaljerScreen> {
  final _dbService = DatabaseService();
  final _authService = AuthService();
  final _uuid = const Uuid();
  Sag? _sag;
  bool _isLoading = true;
  List<TimerLog> _timerLogs = [];
  List<EquipmentLog> _equipmentLogs = [];
  List<SagMessage> _messages = [];
  List<ActivityLog> _activityLogs = [];
  static const List<Map<String, dynamic>> _tabItems = [
    {'key': 'oversigt', 'label': 'Oversigt', 'icon': Icons.dashboard_outlined},
    {'key': 'blokke', 'label': 'Blokke', 'icon': Icons.view_quilt},
    {'key': 'udstyr', 'label': 'Udstyr', 'icon': Icons.inventory_2},
    {'key': 'kabler', 'label': 'Kabler & slanger', 'icon': Icons.cable},
    {'key': 'timer', 'label': 'Timer', 'icon': Icons.timer},
    {'key': 'beskeder', 'label': 'Beskeder', 'icon': Icons.chat_bubble_outline},
    {'key': 'aktivitet', 'label': 'Aktivitetslog', 'icon': Icons.list_alt},
    {'key': 'rentabilitet', 'label': 'Rentabilitet', 'icon': Icons.savings},
    {'key': 'faktura', 'label': 'Fakturaer', 'icon': Icons.receipt_long},
  ];
  String _activeTab = 'oversigt';

  List<Map<String, dynamic>> get _visibleTabs {
    final user = _authService.currentUser;
    if (user == null) return _tabItems;

    final features = user.enabledFeatures ?? [];
    bool canSee(String key) {
      if (user.role == 'admin' || user.role == 'bogholder') return true;
      if (key == 'rentabilitet') {
        return features.contains('rentabilitet');
      }
      if (key == 'faktura') {
        return features.contains('faktura');
      }
      return true;
    }

    return _tabItems.where((t) => canSee(t['key'] as String)).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadSag();
  }

  Future<void> _loadSag() async {
    final sag = await _dbService.getSag(widget.sagId);
    final timerLogs = _dbService.getTimerLogsBySag(widget.sagId);
    final equipmentLogs = _dbService.getEquipmentLogsBySag(widget.sagId);
    final messages = _dbService.getMessagesBySag(widget.sagId);
    final activities = _dbService.getActivityLogsBySag(widget.sagId);
    setState(() {
      _sag = sag;
      _timerLogs = timerLogs;
      _equipmentLogs = equipmentLogs;
      _messages = messages;
      _activityLogs = activities;
      _isLoading = false;
      if (!_visibleTabs.any((t) => t['key'] == _activeTab)) {
        _activeTab = 'oversigt';
      }
    });
  }

  void _showTimerRegistrationDialog() {
    final hoursController = TextEditingController(text: '0.00');
    final rateController = TextEditingController(text: '545');
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedType = 'Opsætning';
    bool billable = true;

    final typeOptions = [
      'Opsætning',
      'Nedtagning',
      'Tilsyn',
      'Målinger',
      'Skimmel',
      'Boring af drænhuller',
      'Andet',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tilføj timer registrering'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Dato', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}',
                        ),
                        const Spacer(),
                        const Icon(Icons.calendar_today, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text('Arbejdstype', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: typeOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => selectedType = value);
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: hoursController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Antal timer',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: rateController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Timesats (DKK)',
                          border: OutlineInputBorder(),
                          helperText: 'Standard: 545 DKK/time',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Checkbox(
                      value: billable,
                      onChanged: (v) => setDialogState(() => billable = v ?? true),
                    ),
                    const Text('Fakturerbar tid'),
                    const SizedBox(width: 8),
                    if (billable)
                      Chip(
                        label: const Text('Fakturerbar'),
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                Text('Noter (valgfri)', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                TextFormField(
                  controller: noteController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Beskrivelse af udført arbejde...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuller'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              onPressed: () async {
                final hours = double.tryParse(hoursController.text) ?? 0;
                final rate = double.tryParse(rateController.text) ?? 0;
                if (hours <= 0) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Indtast gyldigt timetal')));
                  return;
                }
                if (rate <= 0) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Indtast gyldig timesats')));
                  return;
                }

                final timerLog = TimerLog(
                  id: _uuid.v4(),
                  sagId: widget.sagId,
                  date: selectedDate.toIso8601String().split('T').first,
                  type: selectedType,
                  hours: hours,
                  rate: rate,
                  billable: billable,
                  note: noteController.text.isEmpty ? null : noteController.text,
                  user: _authService.currentUser?.name ?? 'Ukendt',
                  timestamp: DateTime.now().toIso8601String(),
                );

                await _dbService.addTimerLog(timerLog);
                if (context.mounted) {
                  Navigator.pop(context);
                }
                await _loadSag();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Timer registreret')),
                  );
                }
              },
              label: const Text('Gem timer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEquipmentLogDialog() {
    String selectedCategory = 'affugter';
    String selectedAction = 'opsæt';
    final noteController = TextEditingController();
    final countController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Log udstyr'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'affugter', child: Text('Affugter')),
                    DropdownMenuItem(value: 'ventilator', child: Text('Ventilator')),
                    DropdownMenuItem(value: 'varmekanon', child: Text('Varmekanon')),
                    DropdownMenuItem(value: 'slange', child: Text('Slange')),
                    DropdownMenuItem(value: 'kabel', child: Text('Kabel')),
                    DropdownMenuItem(value: 'andet', child: Text('Andet')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                // Action dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedAction,
                  decoration: const InputDecoration(
                    labelText: 'Handling',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'opsæt', child: Text('Opsæt')),
                    DropdownMenuItem(value: 'nedtag', child: Text('Nedtag')),
                    DropdownMenuItem(value: 'tilføj', child: Text('Tilføj')),
                    DropdownMenuItem(value: 'defekt', child: Text('Markér defekt')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedAction = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                // Count input
                TextFormField(
                  controller: countController,
                  decoration: const InputDecoration(
                    labelText: 'Antal',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                // Note input
                TextFormField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (valgfri)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
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
                final count = int.tryParse(countController.text) ?? 1;

                final equipmentLog = EquipmentLog(
                  id: _uuid.v4(),
                  sagId: widget.sagId,
                  category: selectedCategory,
                  action: selectedAction,
                  data: {'count': count},
                  timestamp: DateTime.now().toIso8601String(),
                  user: _authService.currentUser?.name ?? 'Ukendt',
                  note: noteController.text.isEmpty ? null : noteController.text,
                );

                await _dbService.addEquipmentLog(equipmentLog);
                if (context.mounted) {
                  Navigator.pop(context);
                }
                await _loadSag();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$count $selectedCategory ${selectedAction == 'opsæt' ? 'opsat' : selectedAction}')),
                  );
                }
              },
              child: const Text('Gem'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditSagDialog() async {
    if (_sag == null) return;

    final sag = _sag!;
    final formKey = GlobalKey<FormState>();

    final sagsnrController = TextEditingController(text: sag.sagsnr);
    final adresseController = TextEditingController(text: sag.adresse);
    final byggelederController = TextEditingController(text: sag.byggeleder);
    final byggelederEmailController = TextEditingController(text: sag.byggelederEmail);
    final byggelederTlfController = TextEditingController(text: sag.byggelederTlf);
    final bygherreController = TextEditingController(text: sag.bygherre);
    final cvrNrController = TextEditingController(text: sag.cvrNr);
    final beskrivelseController = TextEditingController(text: sag.beskrivelse);

    String selectedSagType = sag.sagType ?? 'udtørring';
    String selectedRegion = sag.region ?? 'fyn';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Rediger sagsinformationer'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: sagsnrController,
                    decoration: const InputDecoration(
                      labelText: 'Sagsnummer *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v?.isEmpty == true ? 'Påkrævet' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: adresseController,
                    decoration: const InputDecoration(
                      labelText: 'Adresse *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v?.isEmpty == true ? 'Påkrævet' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedSagType,
                    decoration: const InputDecoration(
                      labelText: 'Sagstype',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'udtørring', child: Text('Udtørring')),
                      DropdownMenuItem(value: 'varme', child: Text('Varme')),
                      DropdownMenuItem(value: 'begge', child: Text('Begge')),
                    ],
                    onChanged: (v) => setDialogState(() => selectedSagType = v!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRegion,
                    decoration: const InputDecoration(
                      labelText: 'Region',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'fyn', child: Text('Fyn')),
                      DropdownMenuItem(value: 'jylland', child: Text('Jylland')),
                      DropdownMenuItem(value: 'sjælland', child: Text('Sjælland')),
                    ],
                    onChanged: (v) => setDialogState(() => selectedRegion = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: beskrivelseController,
                    decoration: const InputDecoration(
                      labelText: 'Beskrivelse',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: bygherreController,
                    decoration: const InputDecoration(
                      labelText: 'Bygherre',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: cvrNrController,
                    decoration: const InputDecoration(
                      labelText: 'CVR-nr',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: byggelederController,
                    decoration: const InputDecoration(
                      labelText: 'Byggeleder *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v?.isEmpty == true ? 'Påkrævet' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: byggelederEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Byggeleder email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: byggelederTlfController,
                    decoration: const InputDecoration(
                      labelText: 'Byggeleder telefon',
                      border: OutlineInputBorder(),
                    ),
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
                  final updatedSag = Sag(
                    id: sag.id,
                    sagsnr: sagsnrController.text,
                    adresse: adresseController.text,
                    byggeleder: byggelederController.text,
                    byggelederEmail: byggelederEmailController.text.isEmpty ? null : byggelederEmailController.text,
                    byggelederTlf: byggelederTlfController.text.isEmpty ? null : byggelederTlfController.text,
                    bygherre: bygherreController.text.isEmpty ? null : bygherreController.text,
                    cvrNr: cvrNrController.text.isEmpty ? null : cvrNrController.text,
                    beskrivelse: beskrivelseController.text.isEmpty ? null : beskrivelseController.text,
                    sagType: selectedSagType,
                    region: selectedRegion,
                    status: sag.status,
                    aktiv: sag.aktiv,
                    arkiveret: sag.arkiveret,
                    arkiveretDato: sag.arkiveretDato,
                    kundensSagsref: sag.kundensSagsref,
                    oprettetAf: sag.oprettetAf,
                    oprettetDato: sag.oprettetDato,
                    opdateretDato: now,
                    createdAt: sag.createdAt,
                    updatedAt: now,
                  );

                  await _dbService.updateSag(updatedSag);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                  await _loadSag();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sagsinformationer opdateret')),
                    );
                  }
                }
              },
              child: const Text('Gem'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aktiv':
      case 'igangværende':
        return Colors.green;
      case 'afsluttet':
      case 'completed':
        return Colors.blue;
      case 'paused':
      case 'pauseret':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Indlæser...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_sag == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sag ikke fundet')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Sagen kunne ikke indlæses',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      );
    }

    final sag = _sag!;
    final canAccessAdmin = _authService.currentUser?.role == 'admin' || _authService.currentUser?.role == 'bogholder';

    return Scaffold(
      appBar: AppBar(
        title: Text('Sag ${sag.sagsnr}'),
        elevation: 0,
        actions: [
          if (canAccessAdmin)
            IconButton(
              tooltip: 'Administration',
              onPressed: () => Navigator.pushNamed(context, '/admin-settings'),
              icon: const Icon(Icons.admin_panel_settings),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(sag),
            const SizedBox(height: 12),
            _buildTabMenu(),
            const SizedBox(height: 16),
            Expanded(child: _buildTabContent(sag)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Sag sag) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sag.sagsnr,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sag.adresse,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(sag.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    sag.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(sag.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabMenu() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _visibleTabs.map((tab) {
          final isActive = _activeTab == tab['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: isActive,
              onSelected: (_) => setState(() => _activeTab = tab['key'] as String),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tab['icon'] as IconData, size: 18),
                  const SizedBox(width: 6),
                  Text(tab['label'] as String),
                ],
              ),
              selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.5),
              labelStyle: TextStyle(
                color: isActive
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent(Sag sag) {
    switch (_activeTab) {
      case 'oversigt':
        return _buildOversigtTab(sag);
      case 'timer':
        return _buildTimerTab();
      case 'udstyr':
        return SagUdstyrsScreen(sagId: widget.sagId);
      case 'beskeder':
        return _buildBeskedTab();
      case 'aktivitet':
        return _buildAktivitetslogTab();
      case 'rentabilitet':
        return _buildPlaceholderTab(
          'Rentabilitet',
          'Se dækningsbidrag, timer og udstyr versus faktureret beløb.',
        );
      case 'faktura':
        return _buildPlaceholderTab(
          'Fakturaer',
          'Generer fakturakladder og eksporter som PDF/CSV.',
        );
      case 'blokke':
        return BlokAdministrationScreen(sagId: widget.sagId);
      case 'kabler':
        return KablerSlangerScreen(sag: sag);
      default:
        return _buildOversigtTab(sag);
    }
  }

  Widget _buildOversigtTab(Sag sag) {
    // Get statistics
    final blokke = _dbService.getBlokkeBySag(sag.id);
    final totalBlokke = blokke.length;
    final activeBlokke = blokke.where((b) => b.slutDato == null).length;

    final equipmentLogs = _equipmentLogs;
    final activeEquipment = equipmentLogs.where((log) => log.action == 'opsæt').length;
    final inactiveEquipment = equipmentLogs.where((log) => log.action == 'nedtag').length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics cards
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Sagsoversigt',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Blokke i alt',
                    totalBlokke.toString(),
                    Icons.business,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Aktive blokke',
                    activeBlokke.toString(),
                    Icons.check_circle,
                    AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Aktivt udstyr',
                    activeEquipment.toString(),
                    Icons.inventory_2,
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Inaktivt udstyr',
                    inactiveEquipment.toString(),
                    Icons.remove_circle,
                    AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sagsoplysninger (collapsible)
          _buildCollapsibleSection(
            title: 'Sagsoplysninger',
            trailing: IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: _showEditSagDialog,
              color: AppColors.primary,
            ),
            children: [
              _buildDetailRow('Sagsnummer', sag.sagsnr),
              _buildDetailRow('Adresse', sag.adresse),
              _buildDetailRow('Sagstype', sag.sagType ?? 'Ikke angivet'),
              _buildDetailRow('Region', sag.region ?? 'Ikke angivet'),
              if (sag.beskrivelse != null) _buildDetailRow('Beskrivelse', sag.beskrivelse!),
              const Divider(height: 24),
              if (sag.bygherre != null) _buildDetailRow('Bygherre', sag.bygherre!),
              if (sag.cvrNr != null) _buildDetailRow('CVR-nr.', sag.cvrNr!),
              const Divider(height: 24),
              _buildDetailRow('Byggeleder', sag.byggeleder),
              if (sag.byggelederEmail != null) _buildDetailRow('Email', sag.byggelederEmail!),
              if (sag.byggelederTlf != null) _buildDetailRow('Telefon', sag.byggelederTlf!),
            ],
          ),
          const SizedBox(height: 16),

          // Blokke Oversigt
          _buildCollapsibleSection(
            title: 'Blokke Oversigt',
            children: [
              if (blokke.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.business, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Ingen blokke oprettet endnu',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...blokke.map((blok) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.business, color: AppColors.primary),
                        title: Text(blok.navn, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(blok.pricingModel),
                        trailing: blok.slutDato != null
                            ? Chip(
                                label: const Text('Afsluttet'),
                                backgroundColor: Colors.green.withValues(alpha: 0.2),
                              )
                            : Chip(
                                label: const Text('Aktiv'),
                                backgroundColor: AppColors.success.withValues(alpha: 0.2),
                              ),
                      ),
                    )),
            ],
          ),
          const SizedBox(height: 16),

          // Aktive Udstyr Oversigt
          _buildCollapsibleSection(
            title: 'Aktive Udstyr Oversigt',
            children: [
              if (activeEquipment == 0)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Der er ikke noget aktivt udstyr til denne sag',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...equipmentLogs
                    .where((log) => log.action == 'opsæt')
                    .map((log) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              _getEquipmentIcon(log.category),
                              color: AppColors.success,
                            ),
                            title: Text(log.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Af ${log.user} - ${_formatDate(log.timestamp)}'),
                            trailing: Text('${log.data['count'] ?? 1}x'),
                          ),
                        )),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: trailing,
        initiallyExpanded: true,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEquipmentIcon(String category) {
    switch (category.toLowerCase()) {
      case 'affugter':
        return Icons.water_drop;
      case 'ventilator':
        return Icons.air;
      case 'varmekanon':
        return Icons.local_fire_department;
      case 'slange':
        return Icons.straighten;
      case 'kabel':
        return Icons.cable;
      default:
        return Icons.inventory_2;
    }
  }

  Widget _buildTimerTab() {
    final theme = Theme.of(context);
    final isEmpty = _timerLogs.isEmpty;
    final totalHours = _timerLogs.fold<double>(0, (sum, log) => sum + log.hours);
    final billableHours =
        _timerLogs.where((log) => log.billable).fold<double>(0, (sum, log) => sum + log.hours);
    final nonBillableHours =
        _timerLogs.where((log) => !log.billable).fold<double>(0, (sum, log) => sum + log.hours);
    final billableAmount = _timerLogs
        .where((log) => log.billable)
        .fold<double>(0, (sum, log) => sum + (log.hours * log.rate));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              final crossAxisCount = isWide ? 4 : 2;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isWide ? 2.6 : 2.1,
                children: [
                  _buildTimerStatCard(
                    theme: theme,
                    icon: Icons.schedule,
                    iconColor: Colors.blue,
                    label: 'Total timer',
                    value: totalHours.toStringAsFixed(2),
                  ),
                  _buildTimerStatCard(
                    theme: theme,
                    icon: Icons.calculate,
                    iconColor: Colors.green,
                    label: 'Fakturerbare timer',
                    value: billableHours.toStringAsFixed(2),
                  ),
                  _buildTimerStatCard(
                    theme: theme,
                    icon: Icons.access_time,
                    iconColor: Colors.orange,
                    label: 'Ikke-fakturerbare timer',
                    value: nonBillableHours.toStringAsFixed(2),
                  ),
                  _buildTimerStatCard(
                    theme: theme,
                    icon: Icons.payments,
                    iconColor: Colors.purple,
                    label: 'Fakturerbart beløb',
                    value: '${billableAmount.toStringAsFixed(0)} DKK',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Timer', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                          'Registrer timer og se historik for denne sag',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showTimerRegistrationDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Registrer timer'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (isEmpty)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.timer, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ingen timer registreret', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            'Tryk på "Registrer timer" for at oprette den første registrering.',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _timerLogs.length,
              itemBuilder: (context, index) {
                final log = _timerLogs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.timer, color: AppColors.primary),
                    ),
                    title: Text('${log.type} • ${log.hours} timer', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (log.user.isNotEmpty)
                          Text('Af ${log.user}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                        Text(
                          log.date,
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        ),
                        if (log.note?.isNotEmpty == true)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              log.note!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Chip(
                          label: Text(log.billable ? 'Fakturerbar' : 'Ikke fakturerbar'),
                          backgroundColor: (log.billable ? Colors.green : Colors.orange).withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: log.billable ? Colors.green[800] : Colors.orange[800],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${log.rate.toStringAsFixed(0)} kr/t',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTimerStatCard({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAktivitetslogTab() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_activityLogs.isEmpty)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.history, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ingen aktiviteter registreret', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          'Nye timer, udstyrsændringer m.m. vises her.',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _activityLogs.length,
              itemBuilder: (context, index) {
                final entry = _activityLogs[index];
                final icon = _activityIcon(entry.entityType);
                final color = _activityColor(entry.entityType);
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color),
                    ),
                    title: Text(entry.displayDescription, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (entry.userName?.isNotEmpty == true)
                          Text('Af ${entry.userName}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                        Text(
                          entry.timestamp.replaceFirst('T', ' ').split('.').first,
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderTab(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          title: title,
          children: [
            Text(subtitle),
            const SizedBox(height: 12),
            Text(
              'Funktionen er på vej. Fortæl gerne, hvilke data og handlinger du ønsker i denne fane.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBeskedTab() {
    final currentUser = _authService.currentUser;
    final messageController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          title: 'Beskeder',
          children: [
            if (_messages.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Ingen beskeder endnu. Skriv den første besked til teamet.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isOwn = currentUser != null && msg.userId == currentUser.id;
                return Align(
                  alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isOwn
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                          : Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.userName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(msg.text),
                        const SizedBox(height: 4),
                        Text(
                          msg.timestamp.replaceFirst('T', ' ').split('.').first,
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: 'Skriv en besked...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text('Send'),
                  onPressed: () {
                    final text = messageController.text.trim();
                    if (text.isEmpty) return;
                    if (currentUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ingen bruger logget ind')),
                      );
                      return;
                    }
                    final msg = SagMessage(
                      id: _uuid.v4(),
                      sagId: widget.sagId,
                      userId: currentUser.id,
                      userName: currentUser.name,
                      text: text,
                      timestamp: DateTime.now().toIso8601String(),
                    );
                    _dbService.addMessage(msg);
                    setState(() {
                      _messages = _dbService.getMessagesBySag(widget.sagId);
                      _activityLogs = _dbService.getActivityLogsBySag(widget.sagId);
                    });
                    messageController.clear();
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildActionButton(
          icon: Icons.timer,
          label: 'Registrer timer',
          onPressed: _showTimerRegistrationDialog,
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          icon: Icons.inventory_2,
          label: 'Log udstyr',
          onPressed: _showEquipmentLogDialog,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }

  Widget _buildRecentLogsSection() {
    return _buildSection(
      title: 'Seneste registreringer',
      children: [
        if (_timerLogs.isNotEmpty) ...[
          Text(
            'Timer (${_timerLogs.length})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildTimerLogsList(maxItems: 3),
        ],
        if (_equipmentLogs.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Udstyr (${_equipmentLogs.length})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildEquipmentLogsList(maxItems: 3),
        ],
      ],
    );
  }

  Widget _buildTimerLogsList({int? maxItems}) {
    if (_timerLogs.isEmpty) {
      return const Text('Ingen timer registreret endnu');
    }
    final items = maxItems != null ? _timerLogs.take(maxItems).toList() : _timerLogs;
    return Column(
      children: items.map((log) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Text('${log.type} - ${log.hours} timer'),
            subtitle: Text('${_formatDate(log.date)} - ${log.user ?? 'Ukendt'}'),
            trailing: Text('${log.rate.toStringAsFixed(0)} kr/t'),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEquipmentLogsList({int? maxItems}) {
    if (_equipmentLogs.isEmpty) {
      return const Text('Ingen udstyrslog registreret endnu');
    }
    final items = maxItems != null ? _equipmentLogs.take(maxItems).toList() : _equipmentLogs;
    return Column(
      children: items.map((log) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: Text('${log.action} - ${log.category}'),
            subtitle: Text('${_formatDate(log.timestamp)} - ${log.user ?? 'Ukendt'}'),
            trailing: log.data['count'] != null
                ? Text('Antal: ${log.data['count']}')
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return isoDate;
    }
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'timer':
        return Icons.timer;
      case 'equipment':
        return Icons.inventory_2;
      case 'kabel':
        return Icons.cable;
      case 'blok':
        return Icons.view_quilt;
      case 'sag':
        return Icons.folder_open;
      case 'besked':
        return Icons.chat_bubble_outline;
      default:
        return Icons.history;
    }
  }

  Color _activityColor(String type) {
    switch (type) {
      case 'timer':
        return AppColors.primary;
      case 'equipment':
        return Colors.green;
      case 'kabel':
        return Colors.orange;
      case 'blok':
        return Colors.blueGrey;
      case 'sag':
        return Colors.blue;
      case 'besked':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}




