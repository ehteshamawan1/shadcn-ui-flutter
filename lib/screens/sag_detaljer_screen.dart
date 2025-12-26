import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/sag.dart';
import '../models/timer_log.dart';
import '../models/equipment_log.dart';
import '../models/sag_message.dart';
import '../models/activity_log.dart';
import '../models/user.dart';
import '../providers/theme_provider.dart' show ThemeProvider;
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import '../theme/app_theme.dart';
import '../constants/roles_and_features.dart';
import '../widgets/responsive_builder.dart';
import '../widgets/samlet_overblik_widget.dart';
import '../widgets/theme_toggle.dart';
import '../widgets/ui/ska_badge.dart';
import '../widgets/ui/ska_button.dart';
import '../widgets/ui/ska_card.dart';
import '../widgets/ui/ska_input.dart';
import 'blok_administration_screen.dart';
import 'kabler_slanger_screen.dart';
import 'sag_udstyr_screen.dart';
import 'rentabilitet_screen.dart';
import 'faktura_screen.dart';
import '../models/kostpris.dart';

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
  final _sagsnrController = TextEditingController();
  final _sagTypeController = TextEditingController();
  final _adresseController = TextEditingController();
  final _byggelederController = TextEditingController();
  final _byggelederEmailController = TextEditingController();
  final _byggelederTlfController = TextEditingController();
  final _bygherreController = TextEditingController();
  final _cvrNrController = TextEditingController();
  final _postnummerController = TextEditingController();
  final _byController = TextEditingController();
  final _kundensSagsrefController = TextEditingController();
  final _beskrivelseController = TextEditingController();
  Timer? _autoSaveTimer;
  String? _formSagId;
  static const List<Map<String, dynamic>> _tabItems = [
    {'key': 'oversigt', 'label': 'Oversigt', 'icon': Icons.dashboard_outlined},
    {'key': 'samlet', 'label': 'Samlet overblik', 'icon': Icons.remove_red_eye},
    {'key': 'blokke', 'label': 'Blokke', 'icon': Icons.view_quilt},
    {'key': 'udstyr', 'label': 'Udstyr', 'icon': Icons.inventory_2},
    {'key': 'kabler', 'label': 'Kabler & slanger', 'icon': Icons.cable},
    {'key': 'timer', 'label': 'Timer', 'icon': Icons.timer},
    {'key': 'beskeder', 'label': 'Beskeder', 'icon': Icons.chat_bubble_outline},
    {'key': 'aktivitet', 'label': 'Aktivitetslog', 'icon': Icons.list_alt},
    {'key': 'priser', 'label': 'Priser', 'icon': Icons.payments},
    {'key': 'rentabilitet', 'label': 'Rentabilitet', 'icon': Icons.savings},
    {'key': 'faktura', 'label': 'Fakturaer', 'icon': Icons.receipt_long},
    {'key': 'backup', 'label': 'Backup', 'icon': Icons.backup},
    {'key': 'admin', 'label': 'Administration', 'icon': Icons.admin_panel_settings},
  ];
  String _activeTab = 'oversigt';

  List<Map<String, dynamic>> get _visibleTabs {
    // Map tab keys to feature keys
    bool canSee(String key) {
      switch (key) {
        case 'oversigt':
          return true; // Always visible
        case 'samlet':
          return true;
        case 'blokke':
          return _authService.hasFeature(AppFeatures.blockManagement);
        case 'udstyr':
          return _authService.hasFeature(AppFeatures.equipmentManagement);
        case 'kabler':
          return _authService.hasFeature(AppFeatures.cableLogging);
        case 'timer':
          return _authService.hasFeature(AppFeatures.timeTracking);
        case 'beskeder':
          return _authService.hasFeature(AppFeatures.messages);
        case 'aktivitet':
          return _authService.hasFeature(AppFeatures.activityLog);
        case 'priser':
          return _authService.isAdmin; // Admin only
        case 'rentabilitet':
          return _authService.hasFeature(AppFeatures.profitability);
        case 'faktura':
          return _authService.hasFeature(AppFeatures.invoicing);
        case 'backup':
          return _authService.hasFeature(AppFeatures.backup);
        case 'admin':
          return _authService.isAdmin || _authService.isBogholder;
        default:
          return true;
      }
    }

    return _tabItems.where((t) => canSee(t['key'] as String)).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadSag();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _sagsnrController.dispose();
    _sagTypeController.dispose();
    _adresseController.dispose();
    _byggelederController.dispose();
    _byggelederEmailController.dispose();
    _byggelederTlfController.dispose();
    _bygherreController.dispose();
    _cvrNrController.dispose();
    _postnummerController.dispose();
    _byController.dispose();
    _kundensSagsrefController.dispose();
    _beskrivelseController.dispose();
    super.dispose();
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
      if (sag != null) {
        _syncFormWithSag(sag);
      }
      if (!_visibleTabs.any((t) => t['key'] == _activeTab)) {
        _activeTab = 'oversigt';
      }
    });
  }

  void _syncFormWithSag(Sag sag) {
    if (_formSagId != sag.id) {
      _sagsnrController.text = sag.sagsnr;
      _sagTypeController.text = sag.sagType ?? '';
      _adresseController.text = sag.adresse;
      _byggelederController.text = sag.byggeleder;
      _byggelederEmailController.text = sag.byggelederEmail ?? '';
      _byggelederTlfController.text = sag.byggelederTlf ?? '';
      _bygherreController.text = sag.bygherre ?? '';
      _cvrNrController.text = sag.cvrNr ?? '';
      _postnummerController.text = sag.postnummer ?? '';
      _byController.text = sag.by ?? '';
      _kundensSagsrefController.text = sag.kundensSagsref ?? '';
      _beskrivelseController.text = sag.beskrivelse ?? '';
      _formSagId = sag.id;
    }
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 600), () {
      _saveSagChanges();
    });
  }

  Future<void> _saveSagChanges() async {
    final sag = _sag;
    if (sag == null) return;

    final updated = Sag(
      id: sag.id,
      sagsnr: _sagsnrController.text.trim(),
      adresse: _adresseController.text.trim(),
      byggeleder: _byggelederController.text.trim(),
      byggelederEmail: _byggelederEmailController.text.trim().isEmpty
          ? null
          : _byggelederEmailController.text.trim(),
      byggelederTlf: _byggelederTlfController.text.trim().isEmpty
          ? null
          : _byggelederTlfController.text.trim(),
      bygherre: _bygherreController.text.trim().isEmpty
          ? null
          : _bygherreController.text.trim(),
      cvrNr: _cvrNrController.text.trim().isEmpty
          ? null
          : _cvrNrController.text.trim(),
      postnummer: _postnummerController.text.trim().isEmpty
          ? null
          : _postnummerController.text.trim(),
      by: _byController.text.trim().isEmpty ? null : _byController.text.trim(),
      kundensSagsref: _kundensSagsrefController.text.trim().isEmpty
          ? null
          : _kundensSagsrefController.text.trim(),
      beskrivelse: _beskrivelseController.text.trim().isEmpty
          ? null
          : _beskrivelseController.text.trim(),
      status: sag.status,
      aktiv: sag.aktiv,
      arkiveret: sag.arkiveret,
      arkiveretDato: sag.arkiveretDato,
      sagType: _sagTypeController.text.trim().isEmpty
          ? sag.sagType
          : _sagTypeController.text.trim(),
      region: sag.region,
      oprettetAf: sag.oprettetAf,
      oprettetDato: sag.oprettetDato,
      opdateretDato: DateTime.now().toIso8601String(),
      createdAt: sag.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      needsAttention: sag.needsAttention,
      attentionNote: sag.attentionNote,
      attentionAcknowledgedAt: sag.attentionAcknowledgedAt,
      attentionAcknowledgedBy: sag.attentionAcknowledgedBy,
    );

    await _dbService.updateSagQuietly(updated);
    if (mounted) {
      setState(() {
        _sag = updated;
      });
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      await context.read<ThemeProvider>().reloadForCurrentUser();
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed('/sager');
    }
  }

  Future<void> _launchUri(String uriString) async {
    final uri = Uri.parse(uriString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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


  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
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
    final isAdmin = _authService.currentUser?.role == 'admin' || _authService.currentUser?.role == 'bogholder';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(sag, isAdmin: isAdmin),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: AppSpacing.p4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTabMenu(),
                    const SizedBox(height: AppSpacing.s6),
                    _buildTabContent(sag),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Sag sag, {required bool isAdmin}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: AppShadows.shadowSm,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: AppSpacing.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
          child: ResponsiveBuilder(
            mobile: _buildHeaderMobile(sag, isAdmin: isAdmin),
            tablet: _buildHeaderDesktop(sag, isAdmin: isAdmin),
            desktop: _buildHeaderDesktop(sag, isAdmin: isAdmin),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderMobile(Sag sag, {required bool isAdmin}) {
    final roleLabel = isAdmin ? 'Bogholder' : 'Tekniker';
    final regionLabel = _resolveRegionLabel(sag);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SkaButton(
              variant: ButtonVariant.ghost,
              size: ButtonSize.sm,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 16),
                  SizedBox(width: 6),
                  Text('Tilbage'),
                ],
              ),
              onPressed: _handleBack,
            ),
            const Spacer(),
            const ThemeToggle(size: ButtonSize.icon),
            const SizedBox(width: AppSpacing.s2),
            SkaButton(
              variant: ButtonVariant.outline,
              size: ButtonSize.sm,
              icon: const Icon(Icons.logout, size: 16),
              text: 'Log ud ($roleLabel)',
              onPressed: _handleLogout,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s3),
        Text(
          sag.sagsnr,
          style: AppTypography.baseSemibold.copyWith(color: AppColors.foreground),
        ),
        const SizedBox(height: 4),
        Text(
          sag.adresse,
          style: AppTypography.sm.copyWith(color: AppColors.mutedForeground),
        ),
        const SizedBox(height: AppSpacing.s2),
        Wrap(
          spacing: AppSpacing.s2,
          runSpacing: AppSpacing.s1,
          children: [
            _buildRoleBadge(isAdmin),
            SkaBadge.status(text: sag.status, status: sag.status, small: true),
            if (regionLabel != null) SkaBadge.region(regionLabel, small: true),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderDesktop(Sag sag, {required bool isAdmin}) {
    final roleLabel = isAdmin ? 'Bogholder' : 'Tekniker';
    final regionLabel = _resolveRegionLabel(sag);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkaButton(
              variant: ButtonVariant.ghost,
              size: ButtonSize.lg,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 18),
                  SizedBox(width: 8),
                  Text('Tilbage til oversigt'),
                ],
              ),
              onPressed: _handleBack,
            ),
            const SizedBox(width: AppSpacing.s4),
            Expanded(
              child: Align(
                alignment: Alignment.topRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildContactLine(
                      icon: Icons.business,
                      label: 'Projektleder',
                      value: sag.byggeleder,
                    ),
                    if (sag.bygherre != null)
                      _buildContactLine(
                        icon: Icons.person,
                        label: 'Bygherre',
                        value: sag.bygherre!,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${sag.sagsnr}${regionLabel != null ? ' - $regionLabel' : ''}',
                      style: AppTypography.xs.copyWith(color: AppColors.mutedForeground),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: AppSpacing.s3,
                      runSpacing: AppSpacing.s1,
                      alignment: WrapAlignment.end,
                      children: [
                        _buildContactLink(
                          icon: Icons.phone,
                          value: sag.byggelederTlf ?? '',
                          uri: sag.byggelederTlf != null
                              ? 'tel:${sag.byggelederTlf!.replaceAll(' ', '')}'
                              : '',
                        ),
                        _buildContactLink(
                          icon: Icons.mail_outline,
                          value: sag.byggelederEmail ?? '',
                          uri: sag.byggelederEmail != null
                              ? 'mailto:${sag.byggelederEmail}'
                              : '',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s4),
            Wrap(
              spacing: AppSpacing.s2,
              children: [
                const ThemeToggle(size: ButtonSize.icon),
                SkaButton(
                  variant: ButtonVariant.outline,
                  size: ButtonSize.lg,
                  icon: const Icon(Icons.logout, size: 18),
                  text: 'Log ud ($roleLabel)',
                  onPressed: _handleLogout,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s3),
        Text(
          sag.sagsnr,
          style: AppTypography.lgSemibold.copyWith(color: AppColors.foreground),
        ),
        const SizedBox(height: 4),
        Text(
          sag.adresse,
          style: AppTypography.sm.copyWith(color: AppColors.mutedForeground),
        ),
        const SizedBox(height: AppSpacing.s2),
        Wrap(
          spacing: AppSpacing.s2,
          runSpacing: AppSpacing.s1,
          children: [
            _buildRoleBadge(isAdmin),
            if (regionLabel != null) SkaBadge.region(regionLabel, small: true),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleBadge(bool isAdmin) {
    final role = _authService.currentUser?.role ?? '';
    final label = role == 'admin'
        ? 'Bogholder (Admin)'
        : (role == 'bogholder' ? 'Bogholder' : 'Tekniker');
    return SkaBadge(
      text: label,
      variant: isAdmin ? BadgeVariant.primary : BadgeVariant.secondary,
      small: true,
    );
  }

  Widget _buildContactLine({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: AppTypography.smMedium.copyWith(color: AppColors.foreground),
        ),
        Flexible(
          child: Text(
            value,
            style: AppTypography.sm.copyWith(color: AppColors.foreground),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildContactLink({
    required IconData icon,
    required String value,
    required String uri,
  }) {
    final displayValue = value.isNotEmpty ? value : 'Ikke tilgaengelig';
    final isEnabled = uri.isNotEmpty;
    final color = isEnabled ? AppColors.primary : AppColors.mutedForeground;

    return InkWell(
      onTap: isEnabled ? () => _launchUri(uri) : null,
      borderRadius: AppRadius.radiusMd,
      child: Padding(
        padding: AppSpacing.symmetric(horizontal: AppSpacing.s2, vertical: AppSpacing.s1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              displayValue,
              style: AppTypography.xs.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabMenu() {
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate columns based on screen size - desktop has more columns for 2 rows
    int crossAxisCount;
    if (screenWidth >= Breakpoints.lg) {
      crossAxisCount = 7; // Desktop: 7 columns (13 tabs = 2 rows: 7 + 6)
    } else if (screenWidth >= Breakpoints.md) {
      crossAxisCount = 4; // Tablet: 4 columns
    } else {
      crossAxisCount = 2; // Mobile: 2 columns (matching React)
    }

    return Container(
      padding: const EdgeInsets.all(4.0), // Minimal padding
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: AppColors.border),
      ),
      child: GridView.count(
        crossAxisCount: crossAxisCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(), // Tabs don't scroll separately
        crossAxisSpacing: 4.0,
        mainAxisSpacing: 4.0,
        childAspectRatio: screenWidth >= Breakpoints.lg ? 7.5 : 4.5, // Adjusted for larger text
        children: _visibleTabs.map(_buildTabChip).toList(),
      ),
    );
  }

  Color? _tabAccentColor(String key) {
    switch (key) {
      case 'rentabilitet':
        return AppColors.success;
      case 'faktura':
        return AppColors.blue700;
      case 'backup':
        return AppColors.primary;
      case 'admin':
        return AppColors.error;
      default:
        return null;
    }
  }

  Widget _buildTabChip(Map<String, dynamic> tab) {
    final isActive = _activeTab == tab['key'];
    final accent = _tabAccentColor(tab['key'] as String);
    final accentBg = accent != null
        ? accent.withOpacity(AppColors.isDark ? 0.22 : 0.12)
        : Colors.transparent;
    final accentBorder = accent != null
        ? accent.withOpacity(AppColors.isDark ? 0.6 : 0.3)
        : Colors.transparent;
    final bgColor = isActive ? (accent ?? AppColors.background) : accentBg;
    final borderColor = isActive ? (accent ?? AppColors.border) : accentBorder;
    // ALWAYS use white text on colored tabs (active or inactive)
    final textColor = accent != null
        ? Colors.white  // White text on colored backgrounds
        : (isActive ? AppColors.foreground : AppColors.mutedForeground);

    return InkWell(
      onTap: () => setState(() => _activeTab = tab['key'] as String),
      borderRadius: BorderRadius.circular(4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(tab['icon'] as IconData, size: 16, color: textColor),
              const SizedBox(width: 4),
              Text(
                tab['label'] as String,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ).copyWith(color: textColor),
              ),
            ],
          ),
        ),
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
      case 'priser':
        return _buildPriserTab();
      case 'rentabilitet':
        return RentabilitetScreen(
          sagId: widget.sagId,
          sagsnr: _sag?.sagsnr,
          titel: _sag?.adresse,
        );
      case 'faktura':
        return FakturaScreen(sagId: widget.sagId);
      case 'blokke':
        return BlokAdministrationScreen(sagId: widget.sagId);
      case 'kabler':
        return KablerSlangerScreen(sag: sag);
      case 'samlet':
        return Padding(
          padding: AppSpacing.symmetric(horizontal: AppSpacing.s6),
          child: SamletOverblikWidget(sagId: widget.sagId),
        );
      case 'backup':
        return _buildBackupTab();
      case 'admin':
        return _buildAdminTab();
      default:
        return _buildOversigtTab(sag);
    }
  }

  Widget _buildOversigtTab(Sag sag) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSagInfoCard(sag),
          const SizedBox(height: AppSpacing.s6),
          _buildQuickNavCard(),
          const SizedBox(height: AppSpacing.s6),
          Padding(
            padding: AppSpacing.symmetric(horizontal: AppSpacing.s6),
            child: SamletOverblikWidget(sagId: widget.sagId),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupTab() {
    return Padding(
      padding: AppSpacing.symmetric(horizontal: AppSpacing.s6),
      child: SkaCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkaCardHeader(
              title: 'Backup & gendannelse',
              description: 'Administrer eksport og gendannelse af data.',
            ),
            SkaCardContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Backup er tilgaengelig i indstillinger.',
                    style: AppTypography.sm.copyWith(color: AppColors.mutedForeground),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  SkaButton(
                    icon: const Icon(Icons.settings, size: 16),
                    text: 'Aabn indstillinger',
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminTab() {
    return Padding(
      padding: AppSpacing.symmetric(horizontal: AppSpacing.s6),
      child: SkaCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkaCardHeader(
              title: 'Administration',
              description: 'Admin vaerktoejer til brugere og systemindstillinger.',
            ),
            SkaCardContent(
              child: Wrap(
                spacing: AppSpacing.s3,
                runSpacing: AppSpacing.s3,
                children: [
                  SkaButton(
                    variant: ButtonVariant.outline,
                    icon: const Icon(Icons.admin_panel_settings, size: 16),
                    text: 'Admin indstillinger',
                    onPressed: () => Navigator.pushNamed(context, '/admin-settings'),
                  ),
                  SkaButton(
                    variant: ButtonVariant.outline,
                    icon: const Icon(Icons.group, size: 16),
                    text: 'Bruger administration',
                    onPressed: () => Navigator.pushNamed(context, '/users'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _regionFromPostnummer(String postnummer) {
    final normalized = postnummer.trim();
    if (normalized.isEmpty) return null;
    final value = int.tryParse(normalized);
    if (value == null) return null;
    if (value >= 0 && value <= 4999) {
      return 'Sjaelland';
    }
    if (value >= 5000 && value <= 5999) {
      return 'Fyn';
    }
    if (value >= 6000 && value <= 9999) {
      return 'Jylland';
    }
    return null;
  }

  String? _resolveRegionLabel(Sag sag) {
    final derived = _regionFromPostnummer(_postnummerController.text);
    if (derived != null) {
      return derived;
    }
    return sag.region;
  }

  Widget _buildSagInfoCard(Sag sag) {
    final regionLabel = _resolveRegionLabel(sag);
    return SkaCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkaCardHeader(title: 'Sag Information'),
          SkaCardContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveGrid(
                  mobileColumns: 1,
                  tabletColumns: 2,
                  desktopColumns: 2,
                  spacing: AppSpacing.s4,
                  runSpacing: AppSpacing.s4,
                  children: [
                    SkaInput(
                      label: 'Sagsnummer *',
                      placeholder: '2025-001',
                      controller: _sagsnrController,
                      onChanged: (_) => _scheduleAutoSave(),
                    ),
                    SkaInput(
                      label: 'Sag Type *',
                      placeholder: 'Udtorring',
                      controller: _sagTypeController,
                      onChanged: (_) => _scheduleAutoSave(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s6),
                _buildSectionHeader(
                  icon: Icons.location_on_outlined,
                  title: 'Adresse',
                ),
                const SizedBox(height: AppSpacing.s3),
                SkaInput(
                  label: 'Adresse *',
                  placeholder: 'Vejnavn og husnummer',
                  controller: _adresseController,
                  onChanged: (_) => _scheduleAutoSave(),
                ),
                const SizedBox(height: AppSpacing.s4),
                ResponsiveGrid(
                  mobileColumns: 1,
                  tabletColumns: 2,
                  desktopColumns: 2,
                  spacing: AppSpacing.s4,
                  runSpacing: AppSpacing.s4,
                  children: [
                    SkaInput(
                      label: 'Postnummer',
                      placeholder: '0000',
                      controller: _postnummerController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) {
                        _scheduleAutoSave();
                        setState(() {});
                      },
                    ),
                    SkaInput(
                      label: 'By',
                      placeholder: 'Bynavn',
                      controller: _byController,
                      onChanged: (_) => _scheduleAutoSave(),
                    ),
                  ],
                ),
                if (regionLabel != null && regionLabel.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    'Region: $regionLabel',
                    style: AppTypography.xs.copyWith(color: AppColors.mutedForeground),
                  ),
                ],
                const SizedBox(height: AppSpacing.s6),
                _buildSectionHeader(
                  icon: Icons.phone_outlined,
                  title: 'Kontaktoplysninger',
                ),
                const SizedBox(height: AppSpacing.s3),
                SkaInput(
                  label: 'Byggeleder *',
                  placeholder: 'Navn paa byggeleder',
                  controller: _byggelederController,
                  onChanged: (_) => _scheduleAutoSave(),
                ),
                const SizedBox(height: AppSpacing.s4),
                ResponsiveGrid(
                  mobileColumns: 1,
                  tabletColumns: 2,
                  desktopColumns: 2,
                  spacing: AppSpacing.s4,
                  runSpacing: AppSpacing.s4,
                  children: [
                    SkaInput(
                      label: 'Telefon',
                      placeholder: '12345678',
                      controller: _byggelederTlfController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone),
                      onChanged: (_) => _scheduleAutoSave(),
                    ),
                    SkaInput(
                      label: 'Email',
                      placeholder: 'email@example.com',
                      controller: _byggelederEmailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.mail_outline),
                      onChanged: (_) => _scheduleAutoSave(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s6),
                _buildSectionHeader(
                  icon: Icons.business_outlined,
                  title: 'Bygherre Information',
                ),
                const SizedBox(height: AppSpacing.s3),
                ResponsiveGrid(
                  mobileColumns: 1,
                  tabletColumns: 2,
                  desktopColumns: 2,
                  spacing: AppSpacing.s4,
                  runSpacing: AppSpacing.s4,
                  children: [
                    SkaInput(
                      label: 'Bygherre',
                      placeholder: 'Navn paa bygherre/selskab',
                      controller: _bygherreController,
                      onChanged: (_) => _scheduleAutoSave(),
                    ),
                    SkaInput(
                      label: 'CVR Nummer',
                      placeholder: '12345678',
                      controller: _cvrNrController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _scheduleAutoSave(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s4),
                SkaInput(
                  label: 'Kundens Sagsreference',
                  placeholder: 'Kundens interne reference',
                  controller: _kundensSagsrefController,
                  onChanged: (_) => _scheduleAutoSave(),
                ),
                const SizedBox(height: AppSpacing.s6),
                _buildSectionHeader(
                  icon: Icons.description_outlined,
                  title: 'Beskrivelse',
                ),
                const SizedBox(height: AppSpacing.s3),
                SkaInput(
                  label: 'Beskrivelse',
                  placeholder: 'Beskriv sagen og eventuelle forhold...',
                  controller: _beskrivelseController,
                  maxLines: 4,
                  minLines: 3,
                  onChanged: (_) => _scheduleAutoSave(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.foreground),
        const SizedBox(width: AppSpacing.s2),
        Text(
          title,
          style: AppTypography.baseSemibold.copyWith(color: AppColors.foreground),
        ),
      ],
    );
  }

  Widget _buildQuickNavCard() {
    final items = <Map<String, dynamic>>[
      {'key': 'samlet', 'label': 'Samlet overblik over alt', 'icon': Icons.remove_red_eye},
      {'key': 'blokke', 'label': 'Blok administration', 'icon': Icons.view_quilt},
      {'key': 'udstyr', 'label': 'Udstyr og maskiner', 'icon': Icons.inventory_2},
      {'key': 'kabler', 'label': 'Kabler & slanger', 'icon': Icons.cable},
      {'key': 'timer', 'label': 'Timer registrering', 'icon': Icons.timer},
      {'key': 'beskeder', 'label': 'Beskeder', 'icon': Icons.chat_bubble_outline},
      {'key': 'aktivitet', 'label': 'Se aktivitetslog', 'icon': Icons.list_alt},
      {'key': 'rentabilitet', 'label': 'Sag rentabilitet', 'icon': Icons.savings},
      {'key': 'faktura', 'label': 'Fakturaer', 'icon': Icons.receipt_long},
      {'key': 'backup', 'label': 'Data Backup & Restore', 'icon': Icons.backup},
      {'key': 'admin', 'label': 'Administration', 'icon': Icons.admin_panel_settings},
      {'key': 'priser', 'label': 'Priser', 'icon': Icons.payments},
    ];

    final visibleItems = items.where((item) => _canShowTab(item['key'] as String)).toList();

    return SkaCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkaCardHeader(title: 'Hurtig navigation'),
          SkaCardContent(
            child: ResponsiveGrid(
              mobileColumns: 1,
              tabletColumns: 2,
              desktopColumns: 2,
              spacing: AppSpacing.s3,
              runSpacing: AppSpacing.s3,
              children: visibleItems
                  .map(
                    (item) => _buildNavButton(
                      label: item['label'] as String,
                      icon: item['icon'] as IconData,
                      tabKey: item['key'] as String,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  bool _canShowTab(String key) {
    return _visibleTabs.any((tab) => tab['key'] == key);
  }

  Widget _buildNavButton({
    required String label,
    required IconData icon,
    required String tabKey,
  }) {
    Color background = AppColors.background;
    Color border = AppColors.border;
    Color textColor = AppColors.foreground;

    if (tabKey == 'rentabilitet') {
      background = AppColors.successLight;
      border = AppColors.success.withOpacity(0.3);
      textColor = AppColors.success;
    } else if (tabKey == 'faktura') {
      background = AppColors.blue50;
      border = AppColors.blue200;
      textColor = AppColors.blue700;
    } else if (tabKey == 'backup') {
      background = AppColors.blue50;
      border = AppColors.blue200;
      textColor = AppColors.blue700;
    } else if (tabKey == 'admin') {
      background = AppColors.errorLight;
      border = AppColors.error.withOpacity(0.3);
      textColor = AppColors.error;
    }

    return InkWell(
      onTap: () => setState(() => _activeTab = tabKey),
      borderRadius: AppRadius.radiusMd,
      child: Container(
        padding: AppSpacing.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.radiusMd,
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Text(
                label,
                style: AppTypography.smMedium.copyWith(color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildOversigtLegacyTab(Sag sag) {
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
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

  // ignore: unused_element
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
    final allUsers = _dbService.getAllUsers();
    final visibleMessages = currentUser != null
        ? _messages.where((msg) => msg.isVisibleTo(currentUser.id)).toList()
        : _messages.toList();

    visibleMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final unreadCount = currentUser == null
        ? 0
        : visibleMessages.where((msg) => msg.userId != currentUser.id && msg.isRead != true).length;

    final messageById = {
      for (final message in _messages) message.id: message,
    };

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentUserCard(currentUser),
          const SizedBox(height: AppSpacing.s4),
          SkaCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkaCardHeader(
                  title: 'Kommunikation',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (unreadCount > 0) ...[
                        SkaBadgeCount(count: unreadCount),
                        const SizedBox(width: AppSpacing.s2),
                      ],
                      SkaButton(
                        variant: ButtonVariant.primary,
                        size: ButtonSize.sm,
                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                        text: 'Ny besked',
                        onPressed: () => _showNewMessageDialog(
                          allUsers: allUsers,
                          currentUser: currentUser,
                        ),
                      ),
                    ],
                  ),
                ),
                SkaCardContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (visibleMessages.isEmpty)
                        Center(
                          child: Padding(
                            padding: AppSpacing.symmetric(vertical: AppSpacing.s6),
                            child: Column(
                              children: [
                                Icon(Icons.chat_bubble_outline, size: 40, color: AppColors.border),
                                const SizedBox(height: AppSpacing.s3),
                                Text(
                                  'Ingen beskeder endnu',
                                  style: AppTypography.baseSemibold.copyWith(
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.s2),
                                Text(
                                  'Start en samtale ved at sende en besked',
                                  style: AppTypography.sm.copyWith(
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Column(
                          children: visibleMessages
                              .map(
                                (message) => _buildMessageCard(
                                  message: message,
                                  currentUser: currentUser,
                                  messageById: messageById,
                                  allUsers: allUsers,
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentUserCard(User? currentUser) {
    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    final isAdmin = currentUser.role == 'admin' || currentUser.role == 'bogholder';

    return SkaCard(
      padding: AppSpacing.p4,
      child: Row(
        children: [
          SkaBadge(
            text: isAdmin ? 'Bogholder' : 'Tekniker',
            variant: isAdmin ? BadgeVariant.primary : BadgeVariant.secondary,
            small: true,
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Text(
              'Du er logget ind som ${currentUser.name}',
              style: AppTypography.sm.copyWith(color: AppColors.foreground),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard({
    required SagMessage message,
    required User? currentUser,
    required Map<String, SagMessage> messageById,
    required List<User> allUsers,
  }) {
    final isOwn = currentUser != null && message.userId == currentUser.id;
    final isUnread = !isOwn && message.isRead != true;
    final priorityColors = _getPriorityColors(message.priority);
    final parent = message.parentMessageId != null ? messageById[message.parentMessageId] : null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s3),
      padding: AppSpacing.p4,
      decoration: BoxDecoration(
        color: isUnread ? AppColors.warningLight : AppColors.background,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: isUnread ? AppColors.warning.withOpacity(0.3) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.s2,
            runSpacing: AppSpacing.s1,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                _messageTypeIcon(message.messageType),
                size: 16,
                color: _messageTypeColor(message.messageType),
              ),
              Container(
                padding: AppSpacing.symmetric(horizontal: AppSpacing.s2, vertical: AppSpacing.s1),
                decoration: BoxDecoration(
                  color: priorityColors.background,
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(color: priorityColors.border),
                ),
                child: Text(
                  _priorityLabel(message.priority),
                  style: AppTypography.xs.copyWith(color: priorityColors.foreground),
                ),
              ),
              SkaBadge(
                text: message.userName,
                variant: BadgeVariant.secondary,
                small: true,
              ),
              if (message.isTargeted)
                SkaBadge(
                  text: 'Til: ${message.targetDisplayName}',
                  variant: BadgeVariant.outline,
                  small: true,
                ),
              if (isUnread)
                SkaBadge(
                  text: 'Ny',
                  variant: BadgeVariant.error,
                  small: true,
                ),
            ],
          ),
          if (parent != null) ...[
            const SizedBox(height: AppSpacing.s2),
            Container(
              padding: AppSpacing.p3,
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: AppRadius.radiusMd,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Text(
                'Svar paa: ${parent.userName} - ${_truncateText(parent.text, 80)}',
                style: AppTypography.xs.copyWith(color: AppColors.mutedForeground),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.s3),
          Text(
            message.text,
            style: AppTypography.base.copyWith(color: AppColors.foreground),
          ),
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: AppColors.mutedForeground),
              const SizedBox(width: 4),
              Text(
                _formatMessageTimestamp(message.timestamp),
                style: AppTypography.xs.copyWith(color: AppColors.mutedForeground),
              ),
              const Spacer(),
              if (isUnread)
                SkaButton(
                  variant: ButtonVariant.outline,
                  size: ButtonSize.sm,
                  icon: const Icon(Icons.check_circle_outline, size: 14),
                  text: 'Laest',
                  onPressed: () => _markMessageRead(message),
                ),
              const SizedBox(width: AppSpacing.s2),
              SkaButton(
                variant: ButtonVariant.ghost,
                size: ButtonSize.sm,
                icon: const Icon(Icons.reply, size: 14),
                text: 'Svar',
                onPressed: () => _showNewMessageDialog(
                  allUsers: allUsers,
                  currentUser: currentUser,
                  replyTo: message,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showNewMessageDialog({
    required List<User> allUsers,
    required User? currentUser,
    SagMessage? replyTo,
  }) async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingen bruger logget ind')),
      );
      return;
    }

    final messageController = TextEditingController();
    String? targetUserId = replyTo?.userId;
    String messageType = 'message';
    String priority = 'normal';
    final speech = stt.SpeechToText();
    bool speechAvailable = false;
    bool isRecording = false;
    void Function(void Function())? updateDialogState;

    void setDialogStateSafely(void Function() fn) {
      if (updateDialogState != null) {
        updateDialogState!(fn);
      }
    }

    Future<void> stopListening() async {
      if (!isRecording) return;
      await speech.stop();
      setDialogStateSafely(() => isRecording = false);
      if (updateDialogState == null) {
        isRecording = false;
      }
    }

    Future<void> startListening() async {
      if (isRecording) return;

      if (!speechAvailable) {
        speechAvailable = await speech.initialize(
          onStatus: (status) {
            if (status == 'done' || status == 'notListening') {
              setDialogStateSafely(() => isRecording = false);
            }
          },
          onError: (error) {
            setDialogStateSafely(() => isRecording = false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tale-til-tekst fejlede: ${error.errorMsg}'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
        );
      }

      if (!speechAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tale-til-tekst er ikke understottet paa denne enhed.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      setDialogStateSafely(() => isRecording = true);
      await speech.listen(
        localeId: 'da_DK',
        onResult: (result) {
          if (!result.finalResult) return;
          final recognized = result.recognizedWords.trim();
          if (recognized.isEmpty) return;

          setDialogStateSafely(() {
            final existing = messageController.text.trim();
            final next = existing.isEmpty ? recognized : '$existing $recognized';
            messageController.text = next;
            messageController.selection = TextSelection.fromPosition(
              TextPosition(offset: next.length),
            );
          });
        },
      );
    }

    if (targetUserId == currentUser.id) {
      targetUserId = null;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          updateDialogState = setDialogState;
          return AlertDialog(
          title: Text(replyTo == null ? 'Ny besked' : 'Svar til ${replyTo.userName}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (replyTo != null) ...[
                  Container(
                    padding: AppSpacing.p3,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: AppRadius.radiusMd,
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Text(
                      'Svarer paa: ${_truncateText(replyTo.text, 120)}',
                      style: AppTypography.xs.copyWith(color: AppColors.mutedForeground),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                ],
                Text('Send til', style: AppTypography.smMedium),
                const SizedBox(height: AppSpacing.s2),
                DropdownButtonFormField<String?>(
                  value: targetUserId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Alle medarbejdere'),
                    ),
                    ...allUsers.map((user) => DropdownMenuItem<String?>(
                          value: user.id,
                          child: Text(user.name),
                        )),
                  ],
                  onChanged: (value) => setDialogState(() => targetUserId = value),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text('Type', style: AppTypography.smMedium),
                const SizedBox(height: AppSpacing.s2),
                DropdownButtonFormField<String>(
                  value: messageType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'message', child: Text('Besked')),
                    DropdownMenuItem(value: 'question', child: Text('Spoergsmaal')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                  ],
                  onChanged: (value) => setDialogState(() => messageType = value ?? 'message'),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text('Prioritet', style: AppTypography.smMedium),
                const SizedBox(height: AppSpacing.s2),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Lav')),
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'high', child: Text('Hoj')),
                  ],
                  onChanged: (value) => setDialogState(() => priority = value ?? 'normal'),
                ),
                const SizedBox(height: AppSpacing.s4),
                SkaInput(
                  label: 'Besked',
                  placeholder: 'Skriv din besked...',
                  controller: messageController,
                  maxLines: 4,
                  minLines: 2,
                ),
                const SizedBox(height: AppSpacing.s3),
                Row(
                  children: [
                    SkaButton(
                      variant: isRecording ? ButtonVariant.destructive : ButtonVariant.outline,
                      size: ButtonSize.sm,
                      icon: Icon(isRecording ? Icons.mic_off : Icons.mic, size: 16),
                      text: isRecording ? 'Stop optagelse' : 'Tale-til-tekst',
                      onPressed: isRecording ? stopListening : startListening,
                    ),
                    if (isRecording) ...[
                      const SizedBox(width: AppSpacing.s3),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s2),
                      Text(
                        'Lytter...',
                        style: AppTypography.xs.copyWith(color: AppColors.error),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          actions: [
            SkaButton(
              variant: ButtonVariant.ghost,
              size: ButtonSize.sm,
              text: 'Annuller',
              onPressed: () async {
                await stopListening();
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
            ),
            SkaButton(
              variant: ButtonVariant.primary,
              size: ButtonSize.sm,
              icon: const Icon(Icons.send, size: 16),
              text: 'Send besked',
              onPressed: () async {
                await stopListening();
                final text = messageController.text.trim();
                if (text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Indtast en besked')),
                  );
                  return;
                }
                if (text.length > 1000) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Besked er for lang (max 1000 tegn)')),
                  );
                  return;
                }

                String? targetUserName;
                if (targetUserId != null) {
                  final targetUser = allUsers.firstWhere(
                    (u) => u.id == targetUserId,
                    orElse: () => currentUser,
                  );
                  targetUserName = targetUser.name;
                }

                final msg = SagMessage(
                  id: _uuid.v4(),
                  sagId: widget.sagId,
                  userId: currentUser.id,
                  userName: currentUser.name,
                  text: text,
                  timestamp: DateTime.now().toIso8601String(),
                  targetUserId: targetUserId,
                  targetUserName: targetUserName,
                  priority: priority,
                  messageType: messageType,
                  parentMessageId: replyTo?.id,
                  isRead: false,
                  readAt: null,
                );

                try {
                  await _dbService.addMessage(msg);

                  if (mounted) {
                    setState(() {
                      _messages = _dbService.getMessagesBySag(widget.sagId);
                      _activityLogs = _dbService.getActivityLogsBySag(widget.sagId);
                    });
                  }

                  if (context.mounted) {
                    Navigator.pop(dialogContext);
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          targetUserId == null
                              ? 'Besked sendt til alle medarbejdere'
                              : 'Besked sendt til ${targetUserName ?? "valgt medarbejder"}',
                        ),
                        backgroundColor: AppColors.success,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('Error sending message: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Fejl ved afsendelse af besked: ${e.toString()}'),
                        backgroundColor: AppColors.error,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
            ),
          ],
          );
        },
      ),
    );

    updateDialogState = null;
    await stopListening();
    messageController.dispose();
  }

  Future<void> _markMessageRead(SagMessage message) async {
    if (message.isRead == true) return;

    final updated = _copyMessage(
      message,
      isRead: true,
      readAt: DateTime.now().toIso8601String(),
    );
    await _dbService.updateMessage(updated);
    if (mounted) {
      setState(() {
        _messages = _dbService.getMessagesBySag(widget.sagId);
      });
    }
  }

  SagMessage _copyMessage(
    SagMessage message, {
    bool? isRead,
    String? readAt,
  }) {
    return SagMessage(
      id: message.id,
      sagId: message.sagId,
      userId: message.userId,
      userName: message.userName,
      text: message.text,
      timestamp: message.timestamp,
      targetUserId: message.targetUserId,
      targetUserName: message.targetUserName,
      priority: message.priority,
      messageType: message.messageType,
      parentMessageId: message.parentMessageId,
      isRead: isRead ?? message.isRead,
      readAt: readAt ?? message.readAt,
    );
  }

  String _priorityLabel(String? priority) {
    switch (priority) {
      case 'high':
        return 'Hoj';
      case 'low':
        return 'Lav';
      default:
        return 'Normal';
    }
  }

  _PriorityColors _getPriorityColors(String? priority) {
    switch (priority) {
      case 'high':
        return _PriorityColors(
          background: AppColors.errorLight,
          foreground: AppColors.error,
          border: AppColors.error.withOpacity(0.3),
        );
      case 'low':
        return _PriorityColors(
          background: AppColors.backgroundSecondary,
          foreground: AppColors.mutedForeground,
          border: AppColors.borderLight,
        );
      default:
        return _PriorityColors(
          background: AppColors.blue50,
          foreground: AppColors.blue700,
          border: AppColors.blue200,
        );
    }
  }

  IconData _messageTypeIcon(String? type) {
    switch (type) {
      case 'urgent':
        return Icons.error_outline;
      case 'question':
        return Icons.help_outline;
      default:
        return Icons.chat_bubble_outline;
    }
  }

  Color _messageTypeColor(String? type) {
    switch (type) {
      case 'urgent':
        return AppColors.error;
      case 'question':
        return AppColors.primary;
      default:
        return AppColors.mutedForeground;
    }
  }

  String _formatMessageTimestamp(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inHours < 24) {
        final hour = date.hour.toString().padLeft(2, '0');
        final minute = date.minute.toString().padLeft(2, '0');
        return '$hour:$minute';
      }

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      return '$day-$month';
    } catch (_) {
      return isoDate;
    }
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
  // ignore: unused_element
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

  // ignore: unused_element
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
            subtitle: Text('${_formatDate(log.date)} - ${log.user}'),
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
            subtitle: Text('${_formatDate(log.timestamp)} - ${log.user}'),
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

  // ============================================
  // PRISER TAB - Case-specific sales price overrides
  // ============================================

  Widget _buildPriserTab() {
    final sagPriser = _dbService.getSagPriser(widget.sagId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.payments, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Salgspriser for denne sag',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Tilpas priser specifikt for denne sag. Tomme felter bruger standardpriser.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (sagPriser.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _clearAllSagPriser(),
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Nulstil alle'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Labor prices
          _buildPriceSection(
            'Timer',
            Icons.timer,
            PriceCategory.laborCategories,
            sagPriser,
          ),
          const SizedBox(height: 16),

          // Equipment prices
          _buildPriceSection(
            'Udstyr (pr. dag)',
            Icons.inventory_2,
            PriceCategory.equipmentCategories,
            sagPriser,
          ),
          const SizedBox(height: 16),

          // Blok prices
          _buildPriceSection(
            'Blokke',
            Icons.view_quilt,
            PriceCategory.blokCategories,
            sagPriser,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(
    String title,
    IconData icon,
    List<String> categories,
    List<SagPris> sagPriser,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            ...categories.map((category) {
              final defaultPrice = _dbService.getDefaultSalesPrice(category);
              final sagPris = sagPriser.where((p) => p.category == category).firstOrNull;
              final hasOverride = sagPris != null;
              final currentPrice = sagPris?.salgspris ?? defaultPrice;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        PriceCategory.getDisplayName(category),
                        style: TextStyle(
                          color: hasOverride ? AppColors.primary : null,
                          fontWeight: hasOverride ? FontWeight.w600 : null,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${defaultPrice.toStringAsFixed(0)} DKK',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                          decoration: hasOverride ? TextDecoration.lineThrough : null,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 100,
                      child: hasOverride
                          ? Text(
                              '${currentPrice.toStringAsFixed(0)} DKK',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                              textAlign: TextAlign.right,
                            )
                          : Text(
                              'Standard',
                              style: TextStyle(color: Colors.grey[400], fontSize: 13),
                              textAlign: TextAlign.right,
                            ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        hasOverride ? Icons.edit : Icons.add,
                        size: 20,
                        color: hasOverride ? AppColors.primary : Colors.grey,
                      ),
                      onPressed: () => _editSagPris(category, sagPris, defaultPrice),
                      tooltip: hasOverride ? 'Rediger' : 'Tilpas pris',
                    ),
                    if (hasOverride)
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: Colors.red),
                        onPressed: () => _deleteSagPris(sagPris),
                        tooltip: 'Fjern tilpasning',
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _editSagPris(String category, SagPris? existing, double defaultPrice) async {
    final controller = TextEditingController(
      text: existing?.salgspris.toStringAsFixed(0) ?? defaultPrice.toStringAsFixed(0),
    );

    final result = await showDialog<double?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tilpas ${PriceCategory.getDisplayName(category)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Standardpris: ${defaultPrice.toStringAsFixed(0)} DKK',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Salgspris (DKK)',
                border: OutlineInputBorder(),
                suffixText: 'DKK',
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuller'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              Navigator.pop(context, value);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Gem'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result != null) {
      final now = DateTime.now().toIso8601String();
      final sagPris = existing?.copyWith(
        salgspris: result,
        updatedAt: now,
      ) ?? SagPris(
        id: _uuid.v4(),
        sagId: widget.sagId,
        category: category,
        salgspris: result,
        createdAt: now,
        updatedAt: now,
      );

      await _dbService.upsertSagPris(sagPris, byUserName: _authService.currentUser?.name);
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${PriceCategory.getDisplayName(category)} opdateret'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteSagPris(SagPris sagPris) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fjern pristilpasning?'),
        content: Text(
          'Vil du fjerne den tilpassede pris for ${sagPris.displayName}? '
          'Standardprisen vil blive brugt i stedet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuller'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Fjern'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbService.deleteSagPris(sagPris.id, byUserName: _authService.currentUser?.name);
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${sagPris.displayName} nulstillet til standard'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _clearAllSagPriser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nulstil alle priser?'),
        content: const Text(
          'Vil du fjerne alle tilpassede priser for denne sag? '
          'Alle standardpriser vil blive brugt i stedet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuller'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Nulstil alle'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbService.deleteSagPriserBySag(widget.sagId, byUserName: _authService.currentUser?.name);
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alle priser nulstillet til standard'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}

class _PriorityColors {
  final Color background;
  final Color foreground;
  final Color border;

  const _PriorityColors({
    required this.background,
    required this.foreground,
    required this.border,
  });
}

