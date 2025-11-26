import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';
import '../models/sag.dart';
import 'package:uuid/uuid.dart';

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

  Future<void> _saveSag() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final sag = Sag(
        id: const Uuid().v4(),
        sagsnr: _sagsnrController.text.trim(),
        adresse: _adresseController.text.trim(),
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
        region: _selectedRegion,
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
        Navigator.pop(context, true); // Return true to signal successful creation
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ny Sag', style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurface)),
            Text('Opret en ny sag', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          ],
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Annuller'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sag Information
                _buildSection(
                  icon: Icons.folder_outlined,
                  title: 'Sag Information',
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _sagsnrController,
                            label: 'Sagsnummer',
                            hint: '2025-001',
                            icon: Icons.tag,
                            required: true,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Sagsnummer er påkrævet';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdown(
                            value: _selectedSagType,
                            label: 'Sag Type',
                            icon: Icons.category_outlined,
                            items: _sagTypes,
                            onChanged: (value) {
                              setState(() => _selectedSagType = value ?? 'udtørring');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Adresse
                _buildSection(
                  icon: Icons.location_on_outlined,
                  title: 'Adresse',
                  children: [
                    _buildTextField(
                      controller: _adresseController,
                      label: 'Vejnavn og husnummer',
                      hint: 'Eksempel Vej 123',
                      icon: Icons.home_outlined,
                      required: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Adresse er påkrævet';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildTextField(
                            controller: _postnrController,
                            label: 'Postnummer',
                            hint: '0000',
                            icon: Icons.mail_outline,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            controller: _byController,
                            label: 'By',
                            hint: 'Bynavn',
                            icon: Icons.location_city_outlined,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Kontaktoplysninger
                _buildSection(
                  icon: Icons.contacts_outlined,
                  title: 'Kontaktoplysninger',
                  children: [
                    _buildTextField(
                      controller: _byggelederController,
                      label: 'Byggeleder',
                      hint: 'Navn på byggeleder',
                      icon: Icons.person_outline,
                      required: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Byggeleder er påkrævet';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _byggelederTlfController,
                            label: 'Telefon',
                            hint: '12345678',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _byggelederEmailController,
                            label: 'Email',
                            hint: 'email@example.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Bygherre Information
                _buildSection(
                  icon: Icons.business_outlined,
                  title: 'Bygherre Information',
                  children: [
                    _buildTextField(
                      controller: _bygherreController,
                      label: 'Bygherre',
                      hint: 'Navn på bygherre/selskab',
                      icon: Icons.apartment_outlined,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _cvrNrController,
                            label: 'CVR Nummer',
                            hint: '12345678',
                            icon: Icons.business_center_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _kundensSagsrefController,
                            label: 'Kundens Sagsreference',
                            hint: 'Kundens interne reference',
                            icon: Icons.receipt_long_outlined,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Projekt Detaljer
                _buildSection(
                  icon: Icons.settings_outlined,
                  title: 'Projekt Detaljer',
                  children: [
                    _buildDropdown(
                      value: _selectedRegion,
                      label: 'Region',
                      icon: Icons.map_outlined,
                      items: _regions,
                      onChanged: (value) {
                        setState(() => _selectedRegion = value ?? 'sjælland');
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _beskrivrelseController,
                      label: 'Beskrivelse',
                      hint: 'Beskriv sagen og eventuelle særlige forhold...',
                      icon: Icons.description_outlined,
                      maxLines: 4,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSaving ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Annuller'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: isDark ? AppColors.slate700 : Colors.grey[300]!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveSag,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(_isSaving ? 'Opretter sag...' : 'Opret Sag'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.slate700 : Colors.grey[200]!),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate800 : Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: isDark ? AppColors.slate700 : Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? AppColors.slate700 : Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? AppColors.slate700 : Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        filled: true,
        fillColor: isDark ? AppColors.slate800 : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? AppColors.slate700 : Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? AppColors.slate700 : Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: isDark ? AppColors.slate800 : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item[0].toUpperCase() + item.substring(1)),
              ))
          .toList(),
      onChanged: onChanged,
    );
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
