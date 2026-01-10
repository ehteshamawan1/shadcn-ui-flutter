import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/sag.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/responsive_builder.dart';
import '../widgets/ui/ska_button.dart';
import '../widgets/ui/ska_card.dart';
import '../widgets/ui/ska_input.dart';

class NySagScreen extends StatefulWidget {
  const NySagScreen({super.key});

  @override
  State<NySagScreen> createState() => _NySagScreenState();
}

class _NySagScreenState extends State<NySagScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();
  final _authService = AuthService();
  final _sagsnrController = TextEditingController();
  final _adresseController = TextEditingController();
  final _postnrController = TextEditingController();
  final _byController = TextEditingController();
  final _byggelederController = TextEditingController();
  final _byggelederEmailController = TextEditingController();
  final _byggelederTlfController = TextEditingController();
  final _bygherreController = TextEditingController();
  final _cvrNrController = TextEditingController();
  final _kundensSagsrefController = TextEditingController();
  final _beskrivrelseController = TextEditingController();

  String _selectedSagType = 'udtørring';
  String _selectedRegion = 'sjælland';
  final bool _isActive = true;
  bool _isSaving = false;

  final List<String> _sagTypes = ['udtørring', 'varme', 'begge'];
  final List<String> _regions = ['sjælland', 'fyn', 'jylland'];

  String? _regionFromPostnummer(String postnummer) {
    final normalized = postnummer.trim();
    if (normalized.isEmpty) return null;
    final value = int.tryParse(normalized);
    if (value == null) return null;
    if (value >= 0 && value <= 4999) {
      return 'sjælland';
    }
    if (value >= 5000 && value <= 5999) {
      return 'fyn';
    }
    if (value >= 6000 && value <= 9999) {
      return 'jylland';
    }
    return null;
  }

  Future<void> _saveSag() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final derivedRegion = _regionFromPostnummer(_postnrController.text);
      final sag = Sag(
        id: const Uuid().v4(),
        sagsnr: _sagsnrController.text.trim(),
        adresse: _adresseController.text.trim(),
        postnummer: _postnrController.text.trim().isNotEmpty ? _postnrController.text.trim() : null,
        by: _byController.text.trim().isNotEmpty ? _byController.text.trim() : null,
        byggeleder: _byggelederController.text.trim(),
        byggelederEmail: _byggelederEmailController.text.isNotEmpty
            ? _byggelederEmailController.text.trim()
            : null,
        byggelederTlf: _byggelederTlfController.text.isNotEmpty
            ? _byggelederTlfController.text.trim()
            : null,
        bygherre: _bygherreController.text.isNotEmpty ? _bygherreController.text.trim() : null,
        cvrNr: _cvrNrController.text.isNotEmpty ? _cvrNrController.text.trim() : null,
        beskrivelse:
            _beskrivrelseController.text.isNotEmpty ? _beskrivrelseController.text.trim() : null,
        status: 'aktiv',
        aktiv: _isActive,
        sagType: _selectedSagType,
        region: derivedRegion ?? _selectedRegion,
        oprettetAf: _authService.currentUser?.name ?? 'unknown',
        oprettetDato: DateTime.now().toIso8601String(),
        opdateretDato: DateTime.now().toIso8601String(),
      );

      await _dbService.addSag(sag);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Sag oprettet succesfuldt'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, sag);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Fejl: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ny sag', style: AppTypography.lgSemibold),
            Text(
              'Opret en ny sag',
              style: AppTypography.xs.copyWith(color: AppColors.mutedForeground),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          SkaButton(
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.ghost,
            size: ButtonSize.sm,
            icon: const Icon(Icons.close, size: 18),
            text: 'Annuller',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: AppSpacing.p6,
          child: MaxWidthContainer(
            maxWidth: 900,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionCard(
                  icon: Icons.folder_outlined,
                  title: 'Sag information',
                  child: ResponsiveGrid(
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
                        prefixIcon: const Icon(Icons.tag),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Sagsnummer er påkrævet';
                          }
                          return null;
                        },
                      ),
                      _buildDropdown(
                        label: 'Sag type',
                        icon: Icons.category_outlined,
                        value: _selectedSagType,
                        items: _sagTypes,
                        onChanged: (value) {
                          setState(() => _selectedSagType = value ?? 'udtørring');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s6),
                _buildSectionCard(
                  icon: Icons.location_on_outlined,
                  title: 'Adresse',
                  child: Column(
                    children: [
                      SkaInput(
                        label: 'Vejnavn og husnummer *',
                        placeholder: 'Eksempel Vej 123',
                        controller: _adresseController,
                        prefixIcon: const Icon(Icons.home_outlined),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Adresse er påkrævet';
                          }
                          return null;
                        },
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
                            controller: _postnrController,
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              final derived = _regionFromPostnummer(value);
                              if (derived != null && derived != _selectedRegion) {
                                setState(() => _selectedRegion = derived);
                              }
                            },
                            prefixIcon: const Icon(Icons.mail_outline),
                          ),
                          SkaInput(
                            label: 'By',
                            placeholder: 'Bynavn',
                            controller: _byController,
                            prefixIcon: const Icon(Icons.location_city_outlined),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s6),
                _buildSectionCard(
                  icon: Icons.contacts_outlined,
                  title: 'Kontaktoplysninger',
                  child: Column(
                    children: [
                      SkaInput(
                        label: 'Byggeleder *',
                        placeholder: 'Navn på byggeleder',
                        controller: _byggelederController,
                        prefixIcon: const Icon(Icons.person_outline),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Byggeleder er påkrævet';
                          }
                          return null;
                        },
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
                            prefixIcon: const Icon(Icons.phone_outlined),
                          ),
                          SkaInput(
                            label: 'Email',
                            placeholder: 'email@example.com',
                            controller: _byggelederEmailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s6),
                _buildSectionCard(
                  icon: Icons.business_outlined,
                  title: 'Bygherre information',
                  child: Column(
                    children: [
                      SkaInput(
                        label: 'Bygherre',
                        placeholder: 'Navn på bygherre/selskab',
                        controller: _bygherreController,
                        prefixIcon: const Icon(Icons.apartment_outlined),
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
                            label: 'CVR nummer',
                            placeholder: '12345678',
                            controller: _cvrNrController,
                            keyboardType: TextInputType.number,
                            prefixIcon: const Icon(Icons.business_center_outlined),
                          ),
                          SkaInput(
                            label: 'Kundens sagsreference',
                            placeholder: 'Kundens interne reference',
                            controller: _kundensSagsrefController,
                            prefixIcon: const Icon(Icons.receipt_long_outlined),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s6),
                _buildSectionCard(
                  icon: Icons.settings_outlined,
                  title: 'Projekt detaljer',
                  child: Column(
                    children: [
                      _buildDropdown(
                        label: 'Region',
                        icon: Icons.map_outlined,
                        value: _selectedRegion,
                        items: _regions,
                        onChanged: (value) {
                          setState(() => _selectedRegion = value ?? 'sjælland');
                        },
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      SkaInput(
                        label: 'Beskrivelse',
                        placeholder: 'Beskriv sagen og eventuelle særlige forhold...',
                        controller: _beskrivrelseController,
                        prefixIcon: const Icon(Icons.description_outlined),
                        maxLines: 4,
                        minLines: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s6),
                Row(
                  children: [
                    Expanded(
                      child: SkaButton(
                        onPressed: _isSaving ? null : () => Navigator.pop(context),
                        variant: ButtonVariant.outline,
                        size: ButtonSize.lg,
                        text: 'Annuller',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s4),
                    Expanded(
                      flex: 2,
                      child: SkaButton(
                        onPressed: _isSaving ? null : _saveSag,
                        variant: ButtonVariant.primary,
                        size: ButtonSize.lg,
                        fullWidth: true,
                        loading: _isSaving,
                        text: _isSaving ? 'Opretter sag...' : 'Opret sag',
                        icon: _isSaving ? null : const Icon(Icons.check_circle_outline),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return SkaCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkaCardHeader(
            title: title,
            trailing: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
          ),
          SkaCardContent(child: child),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(_formatLabel(item)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  String _formatLabel(String value) {
    switch (value) {
      case 'udtørring':
        return 'Udtørring';
      case 'sjælland':
        return 'Sjælland';
      case 'jylland':
        return 'Jylland';
      case 'fyn':
        return 'Fyn';
      default:
        return value.isNotEmpty ? value[0].toUpperCase() + value.substring(1) : value;
    }
  }

  @override
  void dispose() {
    _sagsnrController.dispose();
    _adresseController.dispose();
    _postnrController.dispose();
    _byController.dispose();
    _byggelederController.dispose();
    _byggelederEmailController.dispose();
    _byggelederTlfController.dispose();
    _bygherreController.dispose();
    _cvrNrController.dispose();
    _kundensSagsrefController.dispose();
    _beskrivrelseController.dispose();
    super.dispose();
  }
}
