import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/economic_service.dart';
import '../services/auth_service.dart';
import '../models/sag.dart';
import '../models/timer_log.dart';
import '../models/equipment_log.dart';
import '../models/blok.dart';
import '../models/blok_completion.dart';
import '../providers/theme_provider.dart';
import '../models/kostpris.dart';

/// Invoice line item for display and calculation
class FakturaLinje {
  final String id;
  final String beskrivelse;
  final String kategori;
  final String type;
  final String periode;
  final double enhedspris;
  final double antal;
  final double total;
  final String? maskinNr;
  final String? note;
  final String? opsaetningsdato;
  final String? nedtagningsdato;

  FakturaLinje({
    required this.id,
    required this.beskrivelse,
    required this.kategori,
    required this.type,
    required this.periode,
    required this.enhedspris,
    required this.antal,
    required this.total,
    this.maskinNr,
    this.note,
    this.opsaetningsdato,
    this.nedtagningsdato,
  });
}

/// Faktura screen for invoice generation and e-conomic integration
class FakturaScreen extends StatefulWidget {
  final String sagId;

  const FakturaScreen({required this.sagId, super.key});

  @override
  State<FakturaScreen> createState() => _FakturaScreenState();
}

class _FakturaScreenState extends State<FakturaScreen> with SingleTickerProviderStateMixin {
  final _dbService = DatabaseService();
  final _economicService = EconomicService();
  final _authService = AuthService();
  late TabController _tabController;

  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  // Data
  Sag? _sag;
  List<EquipmentLog> _equipmentLogs = [];
  List<TimerLog> _timerLogs = [];
  List<Blok> _blokke = [];
  List<BlokCompletion> _blokCompletions = [];

  // Faktura settings
  String _fakturaNummerPrefix = 'F';
  int _fakturaNummerCounter = 1001;
  DateTime _fakturaDate = DateTime.now();
  DateTime _forfaldsDato = DateTime.now().add(const Duration(days: 30));
  DateTime? _periodeFra;
  DateTime? _periodeTil;
  double _momsRate = 25.0;
  double _rabat = 0.0;
  String _betalingsBetingelser = '30 dage netto';
  String _note = '';

  // Company info (configurable)
  Map<String, String> _firmaInfo = {
    'navn': 'SKA-DAN ApS',
    'adresse': 'Virksomhedsvej 123',
    'postnummer': '2000',
    'by': 'Frederiksberg',
    'cvr': '12345678',
    'telefon': '+45 12 34 56 78',
    'email': 'faktura@ska-dan.dk',
    'bankReg': '1234',
    'bankKonto': '567890123',
  };

  // e-conomic connection status
  bool _economicConnected = false;
  String? _economicAgreementName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _loadFakturaSettings();
    _testEconomicConnection();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final sag = await _dbService.getSag(widget.sagId);
      final equipmentLogs = _dbService.getEquipmentLogsBySag(widget.sagId);
      final timerLogs = _dbService.getTimerLogsBySag(widget.sagId);
      final blokke = _dbService.getBlokkeBySag(widget.sagId);
      final blokCompletions = _dbService.getBlokCompletionsBySag(widget.sagId);

      // Auto-detect period from data
      DateTime? earliestDate;
      DateTime? latestDate;

      for (var log in equipmentLogs) {
        final setupDate = DateTime.tryParse(log.timestamp);
        if (setupDate != null) {
          if (earliestDate == null || setupDate.isBefore(earliestDate)) {
            earliestDate = setupDate;
          }
          if (latestDate == null || setupDate.isAfter(latestDate)) {
            latestDate = setupDate;
          }
        }
      }

      for (var log in timerLogs) {
        final date = DateTime.tryParse(log.date);
        if (date != null) {
          if (earliestDate == null || date.isBefore(earliestDate)) {
            earliestDate = date;
          }
          if (latestDate == null || date.isAfter(latestDate)) {
            latestDate = date;
          }
        }
      }

      setState(() {
        _sag = sag;
        _equipmentLogs = equipmentLogs;
        _timerLogs = timerLogs;
        _blokke = blokke;
        _blokCompletions = blokCompletions;
        _periodeFra = earliestDate ?? DateTime.now().subtract(const Duration(days: 30));
        _periodeTil = latestDate ?? DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _loadFakturaSettings() {
    // TODO: Load from local storage/settings service
  }

  Future<void> _testEconomicConnection() async {
    try {
      final result = await _economicService.testConnection();
      setState(() {
        _economicConnected = true;
        _economicAgreementName = result['agreement']?['name'] ?? 'Connected';
      });
    } catch (e) {
      setState(() {
        _economicConnected = false;
        _economicAgreementName = null;
      });
    }
  }

  // Filter equipment logs for billing period
  List<EquipmentLog> get _filteredEquipmentLogs {
    if (_periodeFra == null || _periodeTil == null) return _equipmentLogs;

    return _equipmentLogs.where((log) {
      final timestamp = DateTime.tryParse(log.timestamp);
      if (timestamp == null) return false;
      return timestamp.isAfter(_periodeFra!.subtract(const Duration(days: 1))) &&
          timestamp.isBefore(_periodeTil!.add(const Duration(days: 1)));
    }).toList();
  }

  // Filter timer logs for billing period (only billable)
  List<TimerLog> get _filteredTimerLogs {
    var logs = _timerLogs.where((log) => log.billable).toList();

    if (_periodeFra == null || _periodeTil == null) return logs;

    return logs.where((log) {
      final date = DateTime.tryParse(log.date);
      if (date == null) return false;
      return date.isAfter(_periodeFra!.subtract(const Duration(days: 1))) &&
          date.isBefore(_periodeTil!.add(const Duration(days: 1)));
    }).toList();
  }

  // Filter blok completions for billing period
  List<BlokCompletion> get _filteredBlokCompletions {
    if (_periodeFra == null || _periodeTil == null) return _blokCompletions;

    return _blokCompletions.where((c) {
      final date = DateTime.tryParse(c.completionDate);
      if (date == null) return false;
      return date.isAfter(_periodeFra!.subtract(const Duration(days: 1))) &&
          date.isBefore(_periodeTil!.add(const Duration(days: 1)));
    }).toList();
  }

  // Calculate days in period for equipment
  int _calculateDaysInPeriod(EquipmentLog log) {
    if (_periodeFra == null || _periodeTil == null) return 1;

    final setupDate = DateTime.tryParse(log.timestamp) ?? _periodeFra!;
    final data = log.data;
    final takedownDateStr = data?['takedownDate'] as String?;
    final takedownDate = takedownDateStr != null ? DateTime.tryParse(takedownDateStr) : _periodeTil;

    final startDate = setupDate.isAfter(_periodeFra!) ? setupDate : _periodeFra!;
    final endDate = takedownDate != null && takedownDate.isBefore(_periodeTil!) ? takedownDate : _periodeTil!;

    final diff = endDate.difference(startDate).inDays + 1;
    return diff > 0 ? diff : 1;
  }

  // Generate invoice lines
  List<FakturaLinje> _generateFakturaLinjer() {
    final linjer = <FakturaLinje>[];

    // Equipment lines
    for (var log in _filteredEquipmentLogs) {
      final data = log.data ?? {};
      final daysInPeriod = _calculateDaysInPeriod(log);
      final prisPrDag = (data['prisPrDag'] as num?)?.toDouble() ?? 0;
      final quantity = (data['quantity'] as num?)?.toInt() ?? 1;
      final total = prisPrDag * daysInPeriod * quantity;

      // Skip cables (free)
      if (log.category.toLowerCase() == 'kabler') continue;

      linjer.add(FakturaLinje(
        id: log.id,
        beskrivelse: '${data['type'] ?? log.category}${data['customText'] != null ? ' - ${data['customText']}' : ''}${data['effekt'] != null ? ' (${data['effekt']} kW)' : ''}',
        kategori: log.category,
        type: 'equipment',
        periode: '$daysInPeriod dage',
        enhedspris: prisPrDag,
        antal: (daysInPeriod * quantity).toDouble(),
        total: total,
        maskinNr: data['maskinNr'] as String?,
        note: data['note'] as String?,
        opsaetningsdato: log.timestamp,
        nedtagningsdato: data['takedownDate'] as String?,
      ));
    }

    // Timer lines
    for (var log in _filteredTimerLogs) {
      final total = log.hours * log.rate;
      final typeLabel = log.type == 'Andet' ? (log.customType ?? 'Andet') : log.type;

      linjer.add(FakturaLinje(
        id: log.id,
        beskrivelse: '$typeLabel - Arbejdstimer',
        kategori: 'Timer',
        type: 'timer',
        periode: '${log.hours} timer',
        enhedspris: log.rate,
        antal: log.hours,
        total: total,
        note: log.note,
        opsaetningsdato: log.date,
        nedtagningsdato: log.date,
      ));
    }

    // Blok completion lines
    for (var completion in _filteredBlokCompletions) {
      final blok = _blokke.firstWhere(
        (b) => b.id == completion.blokId,
        orElse: () => Blok(
          id: '',
          sagId: '',
          navn: 'Unknown',
          pricingModel: 'dagsleje',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );

      final unitPrice = completion.completionType == 'lejligheder'
          ? blok.fastPrisPrLejlighed
          : blok.fastPrisPrM2;
      final total = completion.amountCompleted * unitPrice;

      linjer.add(FakturaLinje(
        id: completion.id,
        beskrivelse: '${blok.navn} - ${completion.completionType == 'lejligheder' ? 'Lejligheder' : 'M²'} færdigmeldt',
        kategori: 'Blok',
        type: 'blok_completion',
        periode: '${completion.amountCompleted} ${completion.completionType}',
        enhedspris: unitPrice,
        antal: completion.amountCompleted,
        total: total,
        note: completion.note,
        opsaetningsdato: completion.completionDate,
        nedtagningsdato: completion.completionDate,
      ));
    }

    return linjer;
  }

  // Calculate totals
  Map<String, double> _calculateTotals() {
    final linjer = _generateFakturaLinjer();

    double equipmentSubtotal = 0;
    double timerSubtotal = 0;
    double blokSubtotal = 0;

    for (var linje in linjer) {
      switch (linje.type) {
        case 'equipment':
          equipmentSubtotal += linje.total;
          break;
        case 'timer':
          timerSubtotal += linje.total;
          break;
        case 'blok_completion':
          blokSubtotal += linje.total;
          break;
      }
    }

    final subtotal = equipmentSubtotal + timerSubtotal + blokSubtotal;
    final rabatAmount = subtotal * (_rabat / 100);
    final subtotalAfterRabat = subtotal - rabatAmount;
    final momsAmount = subtotalAfterRabat * (_momsRate / 100);
    final totalAmount = subtotalAfterRabat + momsAmount;

    return {
      'equipmentSubtotal': equipmentSubtotal,
      'timerSubtotal': timerSubtotal,
      'blokSubtotal': blokSubtotal,
      'subtotal': subtotal,
      'rabatAmount': rabatAmount,
      'subtotalAfterRabat': subtotalAfterRabat,
      'momsAmount': momsAmount,
      'totalAmount': totalAmount,
    };
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'da_DK', symbol: 'DKK', decimalDigits: 2);
    return formatter.format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  String _generateFakturaNumber() {
    return '$_fakturaNummerPrefix${_fakturaNummerCounter.toString().padLeft(4, '0')}';
  }

  // Send to e-conomic
  Future<void> _sendToEconomic() async {
    if (_sag == null) return;

    setState(() => _isSending = true);

    try {
      final linjer = _generateFakturaLinjer();
      final totals = _calculateTotals();

      // Convert to e-conomic format
      final invoiceLines = linjer.map((l) => {
        'description': l.beskrivelse,
        'quantity': l.antal,
        'unitNetPrice': l.enhedspris,
      }).toList();

      // Add VAT line if needed
      if (_momsRate > 0) {
        // e-conomic handles VAT automatically based on VAT zone
      }

      // Add discount line if needed
      if (_rabat > 0) {
        invoiceLines.add({
          'description': 'Rabat (${_rabat.toStringAsFixed(0)}%)',
          'quantity': 1.0,
          'unitNetPrice': -totals['rabatAmount']!,
        });
      }

      final result = await _economicService.createDraftInvoice(
        sag: _sag!,
        lines: invoiceLines,
        notes: _note.isNotEmpty ? _note : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Faktura kladde oprettet i e-conomic (Nr: ${result['draftInvoiceNumber']})'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fejl ved oprettelse i e-conomic: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  // Export to JSON
  void _exportJson() {
    final linjer = _generateFakturaLinjer();
    final totals = _calculateTotals();

    final fakturaContent = {
      'fakturaNumber': _generateFakturaNumber(),
      'fakturaDate': _formatDate(_fakturaDate),
      'forfaldsDato': _formatDate(_forfaldsDato),
      'periode': {
        'fra': _periodeFra != null ? _formatDate(_periodeFra!) : null,
        'til': _periodeTil != null ? _formatDate(_periodeTil!) : null,
      },
      'firma': _firmaInfo,
      'kunde': {
        'navn': _sag?.byggeleder ?? '',
        'adresse': _sag?.adresse ?? '',
        'email': _sag?.byggelederEmail ?? '',
        'telefon': _sag?.byggelederTlf ?? '',
      },
      'sag': {
        'nummer': _sag?.sagsnr ?? '',
        'id': widget.sagId,
      },
      'linjer': linjer.map((l) => {
        'beskrivelse': l.beskrivelse,
        'kategori': l.kategori,
        'type': l.type,
        'periode': l.periode,
        'enhedspris': l.enhedspris,
        'antal': l.antal,
        'total': l.total,
        'maskinNr': l.maskinNr,
        'note': l.note,
      }).toList(),
      'totals': totals,
      'momsRate': _momsRate,
      'rabat': _rabat,
      'note': _note,
      'betalingsBetingelser': _betalingsBetingelser,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(fakturaContent);

    // For web, we would use html download. For now, show in dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('JSON Export'),
        content: SingleChildScrollView(
          child: SelectableText(
            jsonString,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Fejl: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Prøv igen'),
            ),
          ],
        ),
      );
    }

    final linjer = _generateFakturaLinjer();
    final totals = _calculateTotals();

    return Scaffold(
      body: Column(
        children: [
          // Header with e-conomic status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.slate700 : Colors.grey[200]!,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Faktura Generator',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Sag: ${_sag?.sagsnr ?? widget.sagId}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                    // e-conomic status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _economicConnected
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _economicConnected ? Colors.green : Colors.orange,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _economicConnected ? Icons.cloud_done : Icons.cloud_off,
                            size: 16,
                            color: _economicConnected ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _economicConnected ? 'e-conomic' : 'Offline',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _economicConnected ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Quick stats
                Row(
                  children: [
                    _buildStatCard(
                      'Udstyr',
                      _filteredEquipmentLogs.length.toString(),
                      Colors.blue,
                      Icons.inventory_2,
                    ),
                    const SizedBox(width: 8),
                    _buildStatCard(
                      'Timer',
                      _filteredTimerLogs.length.toString(),
                      Colors.green,
                      Icons.timer,
                    ),
                    const SizedBox(width: 8),
                    _buildStatCard(
                      'Blokke',
                      _filteredBlokCompletions.length.toString(),
                      Colors.purple,
                      Icons.check_circle,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.indigo[700],
                              ),
                            ),
                            Text(
                              _formatCurrency(totals['totalAmount'] ?? 0),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Oversigt'),
              Tab(text: 'Indstillinger'),
              Tab(text: 'Forhåndsvisning'),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOversigtTab(linjer, totals),
                _buildIndstillingerTab(),
                _buildForhaandsvisningTab(linjer, totals),
              ],
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.slate700 : Colors.grey[200]!,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _exportJson,
                    icon: const Icon(Icons.download),
                    label: const Text('Eksporter JSON'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _economicConnected && !_isSending ? _sendToEconomic : null,
                    icon: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(_isSending ? 'Sender...' : 'Send til e-conomic'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOversigtTab(List<FakturaLinje> linjer, Map<String, double> totals) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.date_range, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Faktureringsperiode',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _periodeFra ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => _periodeFra = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Fra dato',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: Text(
                              _periodeFra != null ? _formatDate(_periodeFra!) : 'Vælg dato',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _periodeTil ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => _periodeTil = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Til dato',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: Text(
                              _periodeTil != null ? _formatDate(_periodeTil!) : 'Vælg dato',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('Denne måned'),
                        onPressed: () {
                          final now = DateTime.now();
                          setState(() {
                            _periodeFra = DateTime(now.year, now.month, 1);
                            _periodeTil = DateTime(now.year, now.month + 1, 0);
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('Sidste måned'),
                        onPressed: () {
                          final now = DateTime.now();
                          setState(() {
                            _periodeFra = DateTime(now.year, now.month - 1, 1);
                            _periodeTil = DateTime(now.year, now.month, 0);
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('Vis alt'),
                        onPressed: () {
                          setState(() {
                            _periodeFra = null;
                            _periodeTil = null;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Invoice lines
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.list_alt, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Faktura Linjer (${linjer.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (linjer.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Ingen fakturerbare poster i den valgte periode'),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: linjer.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final linje = linjer[index];
                        return _buildLinjeItem(linje);
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Totals
          Card(
            color: Colors.blue.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTotalRow('Udstyr subtotal', totals['equipmentSubtotal'] ?? 0),
                  _buildTotalRow('Timer subtotal', totals['timerSubtotal'] ?? 0),
                  _buildTotalRow('Blok subtotal', totals['blokSubtotal'] ?? 0),
                  const Divider(),
                  _buildTotalRow('Subtotal', totals['subtotal'] ?? 0),
                  if (_rabat > 0)
                    _buildTotalRow(
                      'Rabat (${_rabat.toStringAsFixed(0)}%)',
                      -(totals['rabatAmount'] ?? 0),
                      isNegative: true,
                    ),
                  _buildTotalRow('Moms (${_momsRate.toStringAsFixed(0)}%)', totals['momsAmount'] ?? 0),
                  const Divider(thickness: 2),
                  _buildTotalRow(
                    'TOTAL',
                    totals['totalAmount'] ?? 0,
                    isBold: true,
                    fontSize: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinjeItem(FakturaLinje linje) {
    Color categoryColor;
    switch (linje.type) {
      case 'equipment':
        categoryColor = Colors.blue;
        break;
      case 'timer':
        categoryColor = Colors.green;
        break;
      case 'blok_completion':
        categoryColor = Colors.purple;
        break;
      default:
        categoryColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              linje.kategori,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: categoryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  linje.beskrivelse,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (linje.maskinNr != null)
                  Text(
                    'Maskin nr: ${linje.maskinNr}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                Text(
                  linje.periode,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(linje.total),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${_formatCurrency(linje.enhedspris)}/${linje.type == 'timer' ? 'time' : 'dag'}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isBold = false, bool isNegative = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isNegative ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndstillingerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Invoice settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Faktura Indstillinger',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _fakturaNummerPrefix,
                          decoration: const InputDecoration(
                            labelText: 'Prefix',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) => setState(() => _fakturaNummerPrefix = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          initialValue: _fakturaNummerCounter.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Nummer',
                            border: OutlineInputBorder(),
                            helperText: 'Næste faktura nummer',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() => _fakturaNummerCounter = int.tryParse(v) ?? 1001),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Faktura nummer: ${_generateFakturaNumber()}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _fakturaDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => _fakturaDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Faktura dato',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(_formatDate(_fakturaDate)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _forfaldsDato,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => _forfaldsDato = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Forfaldsdato',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(_formatDate(_forfaldsDato)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _betalingsBetingelser,
                    decoration: const InputDecoration(
                      labelText: 'Betalingsbetingelser',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _betalingsBetingelser = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Prices
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Priser og Rabat',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _momsRate.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Moms (%)',
                            border: OutlineInputBorder(),
                            suffixText: '%',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (v) => setState(() => _momsRate = double.tryParse(v) ?? 25.0),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: _rabat.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Rabat (%)',
                            border: OutlineInputBorder(),
                            suffixText: '%',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (v) => setState(() => _rabat = double.tryParse(v) ?? 0.0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Note
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Faktura Note',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _note,
                    decoration: const InputDecoration(
                      hintText: 'Ekstra noter til fakturaen...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    onChanged: (v) => setState(() => _note = v),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForhaandsvisningTab(List<FakturaLinje> linjer, Map<String, double> totals) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _firmaInfo['navn'] ?? '',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(_firmaInfo['adresse'] ?? ''),
                        Text('${_firmaInfo['postnummer']} ${_firmaInfo['by']}'),
                        Text('CVR: ${_firmaInfo['cvr']}'),
                        Text('Tlf: ${_firmaInfo['telefon']}'),
                        Text('Email: ${_firmaInfo['email']}'),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'FAKTURA',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Faktura nr: ${_generateFakturaNumber()}'),
                      Text('Dato: ${_formatDate(_fakturaDate)}'),
                      Text('Forfald: ${_formatDate(_forfaldsDato)}'),
                      if (_periodeFra != null && _periodeTil != null)
                        Text('Periode: ${_formatDate(_periodeFra!)} - ${_formatDate(_periodeTil!)}'),
                    ],
                  ),
                ],
              ),
              const Divider(height: 32),

              // Customer info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Faktureres til:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _sag?.byggeleder ?? 'Kunde',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(_sag?.adresse ?? ''),
                  if (_sag?.byggelederEmail != null) Text(_sag!.byggelederEmail!),
                  const SizedBox(height: 8),
                  Text('Sag nr: ${_sag?.sagsnr ?? widget.sagId}'),
                ],
              ),
              const SizedBox(height: 24),

              // Lines table header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                color: Colors.grey[200],
                child: const Row(
                  children: [
                    Expanded(flex: 4, child: Text('Beskrivelse', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('Periode', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('Pris', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                    Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                  ],
                ),
              ),

              // Lines
              ...linjer.map((linje) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(linje.beskrivelse),
                              if (linje.maskinNr != null)
                                Text(
                                  'Maskin nr: ${linje.maskinNr}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                ),
                            ],
                          ),
                        ),
                        Expanded(flex: 2, child: Text(linje.periode)),
                        Expanded(flex: 2, child: Text(_formatCurrency(linje.enhedspris), textAlign: TextAlign.right)),
                        Expanded(flex: 2, child: Text(_formatCurrency(linje.total), textAlign: TextAlign.right)),
                      ],
                    ),
                  )),

              const SizedBox(height: 24),

              // Totals
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 300,
                  child: Column(
                    children: [
                      _buildTotalRow('Subtotal', totals['subtotal'] ?? 0),
                      if (_rabat > 0)
                        _buildTotalRow('Rabat (${_rabat.toStringAsFixed(0)}%)', -(totals['rabatAmount'] ?? 0), isNegative: true),
                      _buildTotalRow('Moms (${_momsRate.toStringAsFixed(0)}%)', totals['momsAmount'] ?? 0),
                      const Divider(thickness: 2),
                      _buildTotalRow('TOTAL', totals['totalAmount'] ?? 0, isBold: true, fontSize: 16),
                    ],
                  ),
                ),
              ),

              // Note
              if (_note.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('Note:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_note),
              ],

              // Payment info
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.grey[100],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Betalingsinformation:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Betingelser: $_betalingsBetingelser'),
                    Text('Reg. nr: ${_firmaInfo['bankReg']}'),
                    Text('Konto nr: ${_firmaInfo['bankKonto']}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
