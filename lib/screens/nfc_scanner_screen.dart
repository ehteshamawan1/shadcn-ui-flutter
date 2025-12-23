import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/affugter.dart';
import '../services/database_service.dart';
import '../services/nfc_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/responsive_builder.dart';
import '../widgets/theme_toggle.dart';
import '../widgets/ui/ska_button.dart';
import '../widgets/ui/ska_card.dart';
import '../widgets/ui/ska_input.dart';

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
          content: Text('NFC er ikke tilgaengelig paa denne enhed'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _startScanning() async {
    setState(() {
      _isScanning = true;
      _scanError = null;
    });

    try {
      await _nfcService.startScanning(
        onRead: (nfcData) {
          setState(() {
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
      if (!mounted) return;
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
                      hintText: 'F.eks. 2-2345',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Angiv tag nummer';
                      }
                      // X-XXXX format validation
                      final regex = RegExp(r'^\d-\d{4}$');
                      if (!regex.hasMatch(value)) {
                        return 'Format skal være X-XXXX (f.eks. 2-2345)';
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
                      DropdownMenuItem(value: 'adsorption', child: Text('Udtoerring - Adsorption')),
                      DropdownMenuItem(value: 'kondens', child: Text('Udtoerring - Kondens')),
                      DropdownMenuItem(value: 'varme', child: Text('Varme')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedType = value);
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vaelg type';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: maerkeController,
                    decoration: const InputDecoration(
                      labelText: 'Maerke',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Indtast maerke';
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
                          setState(() {
                            errorText = 'Hold telefonen paa NFC tagget nu...';
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
                            throw Exception('NFC skrivning fejlede - proev igen');
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
                        final errorMsg = e.toString().replaceAll('Exception:', '').trim();

                        _nfcService.resetWriteState();

                        setState(() {
                          errorText = errorMsg;
                          isSaving = false;
                        });
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
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _searchAndShowDatabaseDetails(nfcData.id);
            },
            icon: const Icon(Icons.search),
            label: const Text('Soeg i database'),
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
              _buildDetailRow('Maerke', affugter.maerke),
              if (affugter.model != null) _buildDetailRow('Model', affugter.model!),
              _buildDetailRow('Status', affugter.status),
              if (affugter.currentSagId != null) _buildDetailRow('Tilknyttet Sag', affugter.currentSagId!),
              if (affugter.serie != null) _buildDetailRow('Serienummer', affugter.serie!),
              if (affugter.note != null) _buildDetailRow('Note', affugter.note!),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC scanner'),
        elevation: 0,
        actions: const [
          ThemeToggle(),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.p6,
        child: MaxWidthContainer(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SkaCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkaCardHeader(
                      title: 'Manuel indtastning',
                      description: 'Indtast tag nummer manuelt for opslag.',
                    ),
                    SkaCardContent(
                      child: Column(
                        children: [
                          SkaInput(
                            label: 'Tag nummer',
                            placeholder: 'Indtast fx 2-2345',
                            controller: _manualIdController,
                            prefixIcon: const Icon(Icons.tag),
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                _searchEquipment(value);
                              }
                            },
                          ),
                          const SizedBox(height: AppSpacing.s4),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isNarrow = constraints.maxWidth < 400;
                              if (isNarrow) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    SkaButton(
                                      onPressed: () {
                                        if (_manualIdController.text.isNotEmpty) {
                                          _searchEquipment(_manualIdController.text);
                                        }
                                      },
                                      variant: ButtonVariant.primary,
                                      size: ButtonSize.lg,
                                      icon: const Icon(Icons.search),
                                      text: 'Soeg udstyr',
                                    ),
                                    const SizedBox(height: AppSpacing.s2),
                                    SkaButton(
                                      onPressed: () {
                                        _showCreateNewTagDialog(_manualIdController.text);
                                      },
                                      variant: ButtonVariant.outline,
                                      size: ButtonSize.lg,
                                      icon: const Icon(Icons.edit_outlined),
                                      text: 'Programmer tag',
                                    ),
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  Expanded(
                                    child: SkaButton(
                                      onPressed: () {
                                        if (_manualIdController.text.isNotEmpty) {
                                          _searchEquipment(_manualIdController.text);
                                        }
                                      },
                                      variant: ButtonVariant.primary,
                                      size: ButtonSize.lg,
                                      icon: const Icon(Icons.search),
                                      text: 'Soeg udstyr',
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.s3),
                                  Expanded(
                                    child: SkaButton(
                                      onPressed: () {
                                        _showCreateNewTagDialog(_manualIdController.text);
                                      },
                                      variant: ButtonVariant.outline,
                                      size: ButtonSize.lg,
                                      icon: const Icon(Icons.edit_outlined),
                                      text: 'Programmer tag',
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s6),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'ELLER',
                      style: AppTypography.xs.copyWith(color: AppColors.mutedForeground),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: AppSpacing.s6),
              SkaCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkaCardHeader(
                      title: 'NFC scanning',
                      description: 'Scan NFC tag automatisk via enheden.',
                    ),
                    SkaCardContent(
                      child: Column(
                        children: [
                          if (_isScanning)
                            Column(
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: AppSpacing.s3),
                                Text('Venter paa NFC-tag...', style: AppTypography.sm),
                                const SizedBox(height: AppSpacing.s3),
                                SkaButton(
                                  onPressed: () async {
                                    await _nfcService.stopScanning();
                                    setState(() => _isScanning = false);
                                  },
                                  variant: ButtonVariant.destructive,
                                  text: 'Stop scanning',
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppColors.successLight,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.nfc, size: 64, color: AppColors.success),
                                ),
                                const SizedBox(height: AppSpacing.s4),
                                SkaButton(
                                  onPressed: _startScanning,
                                  variant: ButtonVariant.primary,
                                  size: ButtonSize.lg,
                                  icon: const Icon(Icons.nfc),
                                  text: 'Start NFC scanning',
                                ),
                              ],
                            ),
                          if (_scanError != null) ...[
                            const SizedBox(height: AppSpacing.s4),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.errorLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.error),
                              ),
                              child: Text(
                                'Fejl: $_scanError',
                                style: AppTypography.sm.copyWith(color: AppColors.error),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
