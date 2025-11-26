import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _appSecretController = TextEditingController();
  final _agreementGrantController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _appSecretController.text = prefs.getString('economic_app_secret') ?? '';
      _agreementGrantController.text = prefs.getString('economic_agreement_grant') ?? '';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fejl ved indlæsning: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('economic_app_secret', _appSecretController.text);
      await prefs.setString('economic_agreement_grant', _agreementGrantController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Indstillinger gemt'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fejl ved gemning: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _appSecretController.dispose();
    _agreementGrantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Indstillinger'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'e-conomic API Konfiguration',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gem dine e-conomic API credentials her, så du ikke behøver at indtaste dem hver gang du eksporterer sager.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _appSecretController,
                              decoration: const InputDecoration(
                                labelText: 'App Secret Token',
                                helperText: 'Dit e-conomic App Secret Token',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.key),
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Dette felt er påkrævet';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _agreementGrantController,
                              decoration: const InputDecoration(
                                labelText: 'Agreement Grant Token',
                                helperText: 'Dit e-conomic Agreement Grant Token',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.verified_user),
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Dette felt er påkrævet';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue[700]),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Du kan finde dine API credentials i e-conomic under Indstillinger → API.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[900],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Gem Indstillinger'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Get saved credentials
  static Future<Map<String, String>?> getSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final appSecret = prefs.getString('economic_app_secret');
      final agreementGrant = prefs.getString('economic_agreement_grant');

      if (appSecret != null && agreementGrant != null &&
          appSecret.isNotEmpty && agreementGrant.isNotEmpty) {
        return {
          'appSecretToken': appSecret,
          'agreementGrantToken': agreementGrant,
        };
      }
    } catch (e) {
      debugPrint('Error loading credentials: $e');
    }
    return null;
  }
}
