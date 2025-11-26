import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class InitialSetupScreen extends StatefulWidget {
  const InitialSetupScreen({super.key});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _dbService = DatabaseService();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _handleSetup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create first admin user
      final user = User(
        id: 'user_admin_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        pin: _pinController.text,
        role: 'admin',
        createdAt: DateTime.now().toIso8601String(),
      );

      await _dbService.addUser(user);

      // Auto-login the new user
      await _authService.login(_pinController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin bruger oprettet'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fejl: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SvgPicture.asset(
                      'assets/images/ska-dan-white.svg',
                      height: 100,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Velkommen til SKA-DAN',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sagshåndtering',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            size: 48,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Første gang opsætning',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Opret den første administrator bruger for at komme i gang',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        labelText: 'Administrator navn',
                        hintText: 'Indtast dit navn',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Indtast et navn';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pinController,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'PIN kode (4 cifre)',
                        hintText: '••••',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.lock),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Indtast en PIN';
                        }
                        if (value.length != 4) {
                          return 'PIN skal være 4 cifre';
                        }
                        if (int.tryParse(value) == null) {
                          return 'PIN skal kun indeholde tal';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPinController,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Bekræft PIN',
                        hintText: '••••',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Bekræft din PIN';
                        }
                        if (value != _pinController.text) {
                          return 'PIN koderne matcher ikke';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleSetup,
                        icon: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle),
                        label: Text(_isLoading ? 'Opretter...' : 'Opret administrator'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Denne bruger vil være administrator og kan oprette flere brugere senere',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
