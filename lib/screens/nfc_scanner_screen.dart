import 'package:flutter/material.dart';
import '../services/nfc_service.dart';
import '../services/database_service.dart';
import '../providers/theme_provider.dart';
import '../models/affugter.dart';
import 'package:uuid/uuid.dart';

class NFCScannerScreen extends StatefulWidget {
  final String? sagId;

  const NFCScannerScreen({this.sagId, super.key});

  @override
  State<NFCScannerScreen> createState() => _NFCScannerScreenState();
}

class _NFCScannerScreenState extends State<NFCScannerScreen> {
  final _nfcService = NFCService();
  final _dbService = DatabaseService();
  final _manualIdController = TextEditingController();

  bool _isScanning = false;
  NFCData? _lastScannedData;
  String? _scanError;

  @override
  void initState() {
    super.initState();
    _checkNfcSupport();
  }

  Future<void> _checkNfcSupport() async {
    final isSupported = await _nfcService.isSupported();
    if (!isSupported && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NFC er ikke tilgængelig på denne enhed'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _startScanning() async {
    setState(() {
      _isScanning = true;
      _scanError = null;
      _lastScannedData = null;
    });

    try {
      await _nfcService.startScanning(
        onRead: (nfcData) {
          setState(() {
            _lastScannedData = nfcData;
            _isScanning = false;
          });
          if (nfcData.id.isEmpty || (nfcData.data?['blankTag'] == true)) {
            _showCreateNewTagDialog(_manualIdController.text);
          } else {
            _showEquipmentDialog(nfcData);
          }
        },
        onError: (error) {
          setState(() {
            _scanError = error;
            _isScanning = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        },
      );
    } catch (e) {
      setState(() {
        _scanError = e.toString();
        _isScanning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fejl: $e')),
      );
    }
  }

  Future<void> _searchEquipment(String equipmentId) async {
    try {
      final allAffugtere = _dbService.getAllAffugtere();
      final affugter = allAffugtere.firstWhere(
        (a) => a.nr == equipmentId,
        orElse: () => throw Exception('Udstyr ikke fundet: $equipmentId'),
      );

      if (mounted) {
        final nfcData = NFCData(
          id: affugter.nr,
          type: 'affugter',
          navn: '${affugter.maerke} - ${affugter.nr}',
          status: affugter.status,
        );
        _showEquipmentDialog(nfcData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            action: SnackBarAction(
              label: 'Opret nyt',
              onPressed: () => _showCreateNewTagDialog(equipmentId),
            ),
          ),
        );
      }
    }
  }


  void _showCreateNewTagDialog(String tagId) {
    final tagIdController = TextEditingController(text: tagId);
    final maerkeController = TextEditingController();
    final modelController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedType = 'adsorption';
    bool writeToTag = true;
    bool isSaving = false;
    String? errorText;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Programmer nyt NFC-tag'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ERROR DISPLAY AT TOP - more visible to user
                  if (errorText != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: errorText!.contains('Hold telefonen')
                            ? Colors.blue.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: errorText!.contains('Hold telefonen')
                              ? Colors.blue
                              : Colors.red,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            errorText!.contains('Hold telefonen')
                                ? Icons.nfc
                                : Icons.error,
                            color: errorText!.contains('Hold telefonen')
                                ? Colors.blue
                                : Colors.red,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              errorText!,
                              style: TextStyle(
                                color: errorText!.contains('Hold telefonen')
                                    ? Colors.blue.shade800
                                    : Colors.red.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  TextFormField(
                    controller: tagIdController,
                    decoration: const InputDecoration(
                      labelText: 'Tag nummer',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Angiv tag nummer';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'adsorption', child: Text('Udtørring - Adsorption')),
                      DropdownMenuItem(value: 'kondens', child: Text('Udtørring - Kondens')),
                      DropdownMenuItem(value: 'varme', child: Text('Varme')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedType = value);
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vælg type';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: maerkeController,
                    decoration: const InputDecoration(
                      labelText: 'Mærke',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Indtast mærke';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: modelController,
                    decoration: const InputDecoration(
                      labelText: 'Model',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: writeToTag,
                    onChanged: (value) => setState(() => writeToTag = value),
                    title: const Text('Skriv til NFC-tag nu'),
                    subtitle: const Text('Hold telefonen på tagget under skrivning'),
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
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      final tagNumber = tagIdController.text.trim();
                      setState(() {
                        isSaving = true;
                        errorText = null;
                      });

                      final now = DateTime.now().toIso8601String();
                      final newAffugter = Affugter(
                        id: const Uuid().v4(),
                        nr: tagNumber,
                        type: selectedType,
                        maerke: maerkeController.text,
                        model: modelController.text.isNotEmpty ? modelController.text : null,
                        status: 'hjemme',
                        createdAt: now,
                        updatedAt: now,
                      );

                      try {
                        final exists = _dbService.getAllAffugtere().any((a) => a.nr == tagNumber);
                        if (exists) {
                          throw Exception('Tag nummeret findes allerede');
                        }

                        if (writeToTag) {
                          // Show instruction to user
                          setState(() {
                            errorText = 'Hold telefonen på NFC tagget nu...';
                          });

                          final writeSuccess = await _nfcService.writeEquipmentToTag(
                            NFCEquipmentData(
                              id: tagNumber,
                              navn: '${maerkeController.text} - $tagNumber',
                              type: selectedType,
                              maerke: maerkeController.text,
                              model: modelController.text.isNotEmpty ? modelController.text : null,
                              status: 'hjemme',
                            ),
                          );

                          if (!writeSuccess) {
                            throw Exception('NFC skrivning fejlede - prøv igen');
                          }
                        }

                        await _dbService.addAffugter(newAffugter);

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(writeToTag ? 'NFC-tag programmeret og udstyr oprettet!' : 'Udstyr oprettet'),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          _searchEquipment(tagNumber);
                        }
                      } catch (e) {
                        String errorMsg = e.toString().replaceAll('Exception:', '').trim();

                        // Reset NFC service state to allow retry
                        _nfcService.resetWriteState();

                        setState(() {
                          errorText = errorMsg;
                          isSaving = false;
                        });
                        // Error is now displayed prominently at the TOP of the dialog
                        // No SnackBar needed - it would appear BEHIND the dialog
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Opret'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEquipmentDialog(NFCData nfcData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scannet NFC Tag'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID', nfcData.id),
              _buildDetailRow('Type', nfcData.type),
              if (nfcData.navn != null) _buildDetailRow('Navn', nfcData.navn!),
              if (nfcData.status != null) _buildDetailRow('Status', nfcData.status!),
              if (nfcData.placering != null) _buildDetailRow('Placering', nfcData.placering!),
              if (nfcData.sagId != null) _buildDetailRow('Sag ID', nfcData.sagId!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Luk'),
          ),
          // Search in database button
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _searchAndShowDatabaseDetails(nfcData.id);
            },
            icon: const Icon(Icons.search),
            label: const Text('Søg i database'),
          ),
          if (widget.sagId != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Udstyr tilknyttet sag ${widget.sagId}')),
                );
              },
              child: const Text('Tilknyt sag'),
            ),
        ],
      ),
    );
  }

  void _searchAndShowDatabaseDetails(String equipmentId) {
    try {
      final allAffugtere = _dbService.getAllAffugtere();
      final affugter = allAffugtere.firstWhere(
        (a) => a.nr == equipmentId,
        orElse: () => throw Exception('Udstyr ikke fundet i database'),
      );

      // Show full database details
      _showDatabaseEquipmentDialog(affugter);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Opret nyt',
              onPressed: () => _showCreateNewTagDialog(equipmentId),
            ),
          ),
        );
      }
    }
  }

  void _showDatabaseEquipmentDialog(Affugter affugter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.inventory_2, color: Colors.green[700]),
            const SizedBox(width: 8),
            const Text('Database Detaljer'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Nr', affugter.nr),
              _buildDetailRow('Type', affugter.type),
              _buildDetailRow('Mærke', affugter.maerke),
              if (affugter.model != null) _buildDetailRow('Model', affugter.model!),
              _buildDetailRow('Status', affugter.status),
              if (affugter.currentSagId != null)
                _buildDetailRow('Tilknyttet Sag', affugter.currentSagId!),
              if (affugter.serie != null)
                _buildDetailRow('Serienummer', affugter.serie!),
              if (affugter.note != null)
                _buildDetailRow('Note', affugter.note!),
              _buildDetailRow('Oprettet', affugter.createdAt.substring(0, 10)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Luk'),
          ),
          if (widget.sagId != null && affugter.status == 'hjemme')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Udstyr tilknyttet sag ${widget.sagId}')),
                );
              },
              child: const Text('Tilknyt til sag'),
            ),
        ],
      ),
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
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('NFC Scanner'),
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Manual search - Highlighted section
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manuel indtastning',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                            Text(
                              'Indtast tag nummer manuelt',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _manualIdController,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Tag nummer',
                      hintText: 'Indtast fx. 2-2345',
                      prefixIcon: const Icon(Icons.tag, size: 20),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          if (_manualIdController.text.isNotEmpty) {
                            _searchEquipment(_manualIdController.text);
                          }
                        },
                        tooltip: 'Søg',
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? AppColors.slate700 : Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? AppColors.slate700 : Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.slate800 : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _searchEquipment(value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_manualIdController.text.isNotEmpty) {
                          _searchEquipment(_manualIdController.text);
                        }
                      },
                      icon: const Icon(Icons.search),
                      label: const Text('Søg udstyr'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showCreateNewTagDialog(_manualIdController.text);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Programmer nyt NFC-tag'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
            const SizedBox(height: 24),

            // Divider with text
            Row(
              children: [
                Expanded(child: Divider(color: isDark ? AppColors.slate700 : Colors.grey[300])),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'ELLER',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: isDark ? AppColors.slate700 : Colors.grey[300])),
              ],
            ),
            const SizedBox(height: 24),

            // NFC scan
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.slate700 : Colors.grey[200]!,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.nfc,
                          color: Colors.green[700],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NFC Scanning',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                            Text(
                              'Scan NFC tag automatisk',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: _isScanning
                        ? Column(
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              const Text('Venter på NFC-tag...'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () async {
                                  await _nfcService.stopScanning();
                                  setState(() => _isScanning = false);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Stop scanning'),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.nfc,
                                  size: 64,
                                  color: Colors.green[700],
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _startScanning,
                                  icon: const Icon(Icons.nfc),
                                  label: const Text('Start NFC Scanning'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[700],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  if (_scanError != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(
                        'Fejl: $_scanError',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _manualIdController.dispose();
    _nfcService.stopScanning();
    super.dispose();
  }
}
