import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/economic_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ui/ska_button.dart';
import '../widgets/ui/ska_card.dart';
import '../widgets/ui/ska_input.dart';
import 'dropdown_settings_screen.dart';

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
  bool _isTesting = false;
  String? _testResult;
  bool? _testSuccess;

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
            content: Text('Fejl ved indlaesning: $e'),
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

      final economicService = EconomicService();
      economicService.setCredentials(
        appSecretToken: _appSecretController.text,
        agreementGrantToken: _agreementGrantController.text,
      );

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

  Future<void> _testConnection() async {
    final appSecret = _appSecretController.text.trim();
    final agreementGrant = _agreementGrantController.text.trim();

    if (appSecret.isEmpty || agreementGrant.isEmpty) {
      setState(() {
        _testResult = 'Indtast venligst begge tokens foerst';
        _testSuccess = false;
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
      _testSuccess = null;
    });

    try {
      final service = EconomicService();
      service.setCredentials(
        appSecretToken: appSecret,
        agreementGrantToken: agreementGrant,
      );

      final result = await service.testConnection();
      final agreementName = result['agreement']?['name'] ?? 'Ukendt';

      if (mounted) {
        setState(() {
          _testResult = 'Forbindelse OK - $agreementName';
          _testSuccess = true;
          _isTesting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testResult = 'Forbindelse fejlede: ${e.toString().replaceAll('Exception:', '').trim()}';
          _testSuccess = false;
          _isTesting = false;
        });
      }
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
        title: const Text('Admin indstillinger'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppSpacing.p6,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('e-conomic API konfiguration', style: AppTypography.lgSemibold),
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      'Gem dine e-conomic API credentials her, saa du ikke skal indtaste dem hver gang.',
                      style: AppTypography.sm.copyWith(color: AppColors.mutedForeground),
                    ),
                    const SizedBox(height: AppSpacing.s6),
                    SkaCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SkaCardHeader(title: 'Credentials'),
                          SkaCardContent(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SkaInput(
                                  label: 'App Secret Token',
                                  helper: 'Dit e-conomic App Secret Token',
                                  controller: _appSecretController,
                                  prefixIcon: const Icon(Icons.key),
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Dette felt er påkrævet';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.s4),
                                SkaInput(
                                  label: 'Agreement Grant Token',
                                  helper: 'Dit e-conomic Agreement Grant Token',
                                  controller: _agreementGrantController,
                                  prefixIcon: const Icon(Icons.verified_user),
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Dette felt er påkrævet';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.s4),
                                Container(
                                  padding: AppSpacing.p3,
                                  decoration: BoxDecoration(
                                    color: AppColors.blue50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.blue200),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline, color: AppColors.blue700),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Find API credentials i e-conomic under Indstillinger > API.',
                                          style: AppTypography.xs.copyWith(color: AppColors.blue700),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.s4),
                                SkaButton(
                                  onPressed: _isTesting ? null : _testConnection,
                                  variant: ButtonVariant.outline,
                                  fullWidth: true,
                                  icon: _isTesting
                                      ? const SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.wifi_tethering),
                                  text: _isTesting ? 'Tester forbindelse...' : 'Test forbindelse',
                                ),
                                if (_testResult != null) ...[
                                  const SizedBox(height: AppSpacing.s3),
                                  Container(
                                    padding: AppSpacing.p3,
                                    decoration: BoxDecoration(
                                      color: _testSuccess == true
                                          ? AppColors.successLight
                                          : AppColors.errorLight,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _testSuccess == true
                                            ? AppColors.success
                                            : AppColors.error,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _testSuccess == true ? Icons.check_circle : Icons.error,
                                          color: _testSuccess == true ? AppColors.success : AppColors.error,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _testResult!,
                                            style: AppTypography.xs.copyWith(
                                              color: _testSuccess == true ? AppColors.success : AppColors.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s6),
                    SkaButton(
                      onPressed: _isSaving ? null : _saveSettings,
                      variant: ButtonVariant.primary,
                      size: ButtonSize.lg,
                      fullWidth: true,
                      text: _isSaving ? 'Gemmer...' : 'Gem indstillinger',
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    const Divider(),
                    const SizedBox(height: AppSpacing.s4),
                    Text('Andre indstillinger', style: AppTypography.lgSemibold),
                    const SizedBox(height: AppSpacing.s4),
                    SkaCard(
                      padding: AppSpacing.p4,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const DropdownSettingsScreen(),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.list_alt, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.s3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Dropdown indstillinger', style: AppTypography.smSemibold),
                                Text(
                                  'Administrer valgmuligheder i dropdown menuer',
                                  style: AppTypography.xs.copyWith(color: AppColors.mutedForeground),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: AppColors.mutedForeground),
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
