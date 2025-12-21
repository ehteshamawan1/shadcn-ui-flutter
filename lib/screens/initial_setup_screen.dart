import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ui/ska_button.dart';
import '../widgets/ui/ska_card.dart';
import '../widgets/ui/ska_input.dart';

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
        Navigator.of(context).pushReplacementNamed('/sager');
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
            padding: AppSpacing.p6,
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
                      style: AppTypography.xl2Bold,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sagshaandtering',
                      style: AppTypography.sm.copyWith(
                        color: AppColors.mutedForeground,
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
                    SkaInput(
                      label: 'Administrator navn',
                      placeholder: 'Indtast dit navn',
                      controller: _nameController,
                      enabled: !_isLoading,
                      prefixIcon: const Icon(Icons.person),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Indtast et navn';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SkaInput(
                      label: 'PIN kode (4 cifre)',
                      placeholder: '****',
                      controller: _pinController,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Indtast en PIN';
                        }
                        if (value.length != 4) {
                          return 'PIN skal vaere 4 cifre';
                        }
                        if (int.tryParse(value) == null) {
                          return 'PIN skal kun indeholde tal';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SkaInput(
                      label: 'Bekraeft PIN',
                      placeholder: '****',
                      controller: _confirmPinController,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_outline),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Bekraeft din PIN';
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
                      child: SkaButton(
                        onPressed: _isLoading ? null : _handleSetup,
                        variant: ButtonVariant.primary,
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
                        text: _isLoading ? 'Opretter...' : 'Opret administrator',
                      ),
                    ),
                    const SizedBox(height: 24),
                    SkaCard(
                      padding: AppSpacing.p3,
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.warning),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Denne bruger vil vaere administrator og kan oprette flere brugere senere',
                              style: AppTypography.xs.copyWith(color: AppColors.mutedForeground),
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
