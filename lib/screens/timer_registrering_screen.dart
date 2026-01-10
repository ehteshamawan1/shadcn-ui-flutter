import 'package:flutter/material.dart';
import '../models/timer_log.dart';
import '../models/kostpris.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/responsive_builder.dart';
import '../widgets/ui/ska_badge.dart';
import '../widgets/ui/ska_button.dart';
import '../widgets/ui/ska_card.dart';
import '../widgets/ui/ska_input.dart';

class TimerRegistreringScreen extends StatefulWidget {
  final String? sagId;

  const TimerRegistreringScreen({this.sagId, super.key});

  @override
  State<TimerRegistreringScreen> createState() => _TimerRegistreringScreenState();
}

class _TimerRegistreringScreenState extends State<TimerRegistreringScreen> {
  final _dbService = DatabaseService();
  final _authService = AuthService();
  final _hoursController = TextEditingController();
  final _notesController = TextEditingController();
  final _rateController = TextEditingController(text: '545');

  late String _selectedWorkType;
  bool _isBillable = true;
  DateTime _selectedDate = DateTime.now();
  late List<TimerLog> _timerLogs;
  double _currentRate = 545;

  final List<String> _workTypes = [
    'Opsætning',
    'Nedtagning',
    'Tilsyn',
    'Målinger',
    'Skimmel',
    'Boring af drænhuller',
    'Andet',
  ];

  @override
  void initState() {
    super.initState();
    _selectedWorkType = _workTypes.first;
    _updateRate();
    _loadTimerLogs();
  }

  void _updateRate() {
    final category = _categoryForWorkType(_selectedWorkType);
    final rate = _dbService.getSalesPrice(widget.sagId ?? '', category);
    setState(() {
      _currentRate = rate;
      _rateController.text = rate.toStringAsFixed(0);
    });
  }

  void _loadTimerLogs() {
    setState(() {
      if (widget.sagId != null) {
        _timerLogs = _dbService.getTimerLogsBySag(widget.sagId!);
      } else {
        _timerLogs = _dbService.getAllTimerLogs();
      }
      _timerLogs.sort((a, b) => b.date.compareTo(a.date));
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveTimer() async {
    if (_hoursController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timer skal udfyldes')),
      );
      return;
    }

    try {
      final hours = double.parse(_hoursController.text);
      if (hours <= 0) {
        throw Exception('Timer skal vaere stoerre end 0');
      }

      final timerLog = TimerLog(
        id: 'timer_${DateTime.now().millisecondsSinceEpoch}',
        sagId: widget.sagId ?? 'no_sag',
        date: _selectedDate.toIso8601String().split('T').first,
        type: _selectedWorkType,
        hours: hours,
        rate: _currentRate,
        billable: _isBillable,
        note: _notesController.text.isNotEmpty ? _notesController.text : null,
        user: _authService.currentUser?.id ?? 'unknown',
        timestamp: DateTime.now().toIso8601String(),
      );

      await _dbService.addTimerLog(timerLog);
      _hoursController.clear();
      _notesController.clear();
      _loadTimerLogs();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Timer registreret')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fejl: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer registrering'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.p6,
        child: MaxWidthContainer(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkaCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkaCardHeader(
                      title: 'Registrer timer',
                      description: 'Standard timesats er 545 DKK/time.',
                    ),
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
                              _buildWorkTypeDropdown(),
                              _buildDatePicker(),
                            ],
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
                                label: 'Timer (decimal)',
                                placeholder: '8.5',
                                controller: _hoursController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                prefixIcon: const Icon(Icons.timer_outlined),
                              ),
                              SkaInput(
                                label: 'Timesats (DKK)',
                                controller: _rateController,
                                readOnly: true,
                                prefixIcon: const Icon(Icons.payments_outlined),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s4),
                          Row(
                            children: [
                              Checkbox(
                                value: _isBillable,
                                onChanged: (value) {
                                  setState(() => _isBillable = value ?? true);
                                },
                              ),
                              Text(
                                'Fakturerbar',
                                style: AppTypography.smMedium,
                              ),
                              const SizedBox(width: AppSpacing.s3),
                              SkaBadge(
                                text: _isBillable ? 'Fakturerbar' : 'Ikke fakturerbar',
                                variant: _isBillable ? BadgeVariant.success : BadgeVariant.warning,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s4),
                          SkaInput(
                            label: 'Noter',
                            placeholder: 'Tilføj noter til denne arbejdssession...',
                            controller: _notesController,
                            maxLines: 3,
                            minLines: 2,
                          ),
                          const SizedBox(height: AppSpacing.s5),
                          SkaButton(
                            onPressed: _saveTimer,
                            variant: ButtonVariant.primary,
                            size: ButtonSize.lg,
                            fullWidth: true,
                            icon: const Icon(Icons.save),
                            text: 'Registrer',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s6),
              if (_timerLogs.isNotEmpty) ...[
                Text('Timer oversigt', style: AppTypography.lgSemibold),
                const SizedBox(height: AppSpacing.s3),
                ..._timerLogs.map(_buildLogCard),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedWorkType,
      decoration: const InputDecoration(
        labelText: 'Arbejdstype',
        prefixIcon: Icon(Icons.work_outline),
      ),
      items: _workTypes
          .map((type) => DropdownMenuItem(
                value: type,
                child: Text(type),
              ))
          .toList(),
      onChanged: (value) {
        setState(() => _selectedWorkType = value ?? _workTypes.first);
        _updateRate();
      },
    );
  }

  String _categoryForWorkType(String workType) {
    final normalized = workType.toLowerCase();
    if (normalized.contains('opsæt') || normalized.contains('opsaet')) {
      return PriceCategory.laborOpsaetning;
    }
    if (normalized.contains('nedtag')) {
      return PriceCategory.laborNedtagning;
    }
    if (normalized.contains('tilsyn')) {
      return PriceCategory.laborTilsyn;
    }
    if (normalized.contains('måling') || normalized.contains('maaling')) {
      return PriceCategory.laborMaalinger;
    }
    if (normalized.contains('skimmel')) {
      return PriceCategory.laborSkimmel;
    }
    if (normalized.contains('dræn') || normalized.contains('draen')) {
      return PriceCategory.laborBoring;
    }
    return PriceCategory.laborAndet;
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Dato',
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
          style: AppTypography.sm.copyWith(color: AppColors.foreground),
        ),
      ),
    );
  }

  Widget _buildLogCard(TimerLog log) {
    return SkaCard(
      padding: AppSpacing.p4,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.blue50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.timer_outlined, color: AppColors.blue700, size: 20),
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${log.type} - ${log.hours}h', style: AppTypography.smSemibold),
                const SizedBox(height: AppSpacing.s1),
                Text(log.date, style: AppTypography.xs.copyWith(color: AppColors.mutedForeground)),
                if (log.note?.isNotEmpty == true)
                  Text(
                    log.note!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.xs.copyWith(color: AppColors.mutedForeground),
                  ),
              ],
            ),
          ),
          SkaBadge(
            text: log.billable ? 'Fakturerbar' : 'Ikke fakturerbar',
            variant: log.billable ? BadgeVariant.success : BadgeVariant.warning,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _notesController.dispose();
    _rateController.dispose();
    super.dispose();
  }
}
