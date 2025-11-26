import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/timer_log.dart';

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

  late String _selectedWorkType;
  bool _isBillable = true;
  DateTime _selectedDate = DateTime.now();
  late List<TimerLog> _timerLogs;

  final List<String> _workTypes = [
    'Setup',
    'Takedown',
    'Inspection',
    'Measurements',
    'Mold',
    'Drilling',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedWorkType = _workTypes.first;
    _loadTimerLogs();
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
        throw Exception('Timer skal være større end 0');
      }

      final timerLog = TimerLog(
        id: 'timer_${DateTime.now().millisecondsSinceEpoch}',
        sagId: widget.sagId ?? 'no_sag',
        date: _selectedDate.toIso8601String().split('T').first,
        type: _selectedWorkType,
        hours: hours,
        rate: 0,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fejl: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer Registrering'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registrer timer',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Work type
                    DropdownButtonFormField<String>(
                      initialValue: _selectedWorkType,
                      decoration: const InputDecoration(
                        labelText: 'Arbejdstype',
                        border: OutlineInputBorder(),
                      ),
                      items: _workTypes
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedWorkType = value ?? _workTypes.first);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date
                    GestureDetector(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Dato',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Hours
                    TextField(
                      controller: _hoursController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Timer (decimal)',
                        hintText: '8.5',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Billable
                    CheckboxListTile(
                      value: _isBillable,
                      onChanged: (value) {
                        setState(() => _isBillable = value ?? true);
                      },
                      title: const Text('Fakturable'),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Noter',
                        border: OutlineInputBorder(),
                        hintText: 'Tilføj noter til denne arbejdssession...',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveTimer,
                        icon: const Icon(Icons.save),
                        label: const Text('Registrer'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // History
            if (_timerLogs.isNotEmpty) ...[
              Text(
                'Timer oversigt',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _timerLogs.length,
                itemBuilder: (context, index) {
                  final log = _timerLogs[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text('${log.type} - ${log.hours}h'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(log.date),
                          if (log.note?.isNotEmpty == true)
                            Text(
                              log.note!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(log.billable ? 'Fakturable' : 'Ikke fakturable'),
                        backgroundColor: (log.billable ? Colors.green : Colors.orange)
                            .withValues(alpha: 0.2),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
