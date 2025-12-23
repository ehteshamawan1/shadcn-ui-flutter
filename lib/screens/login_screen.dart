import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../providers/theme_provider.dart' as legacy_theme;
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import '../widgets/ui/ska_button.dart';
import '../widgets/ui/ska_card.dart';
import '../widgets/ui/ska_badge.dart';
import '../widgets/responsive_builder.dart';
import '../widgets/theme_toggle.dart';

/// Login screen matching React Login.tsx exactly
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _dbService = DatabaseService();
  String _pin = '';
  bool _isLoading = false;
  String? _error;
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.backgroundGradientFrom, // blue-50
                  AppColors.backgroundGradientTo, // indigo-100
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: AppSpacing.p6,
                  child: MaxWidthContainer(
                    maxWidth: 400,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLoginCard(),
                        const SizedBox(height: 24),
                        _buildAvailableUsers(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: ThemeToggle(size: ButtonSize.icon),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return SkaCard(
      padding: AppSpacing.p6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header - Logo
          Image.asset(
            'assets/images/logo.png',
            height: 60,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Text(
            'Indtast din 4-cifrede kode',
            style: AppTypography.sm.copyWith(
              color: AppColors.lightForeground,
            ),
          ),
          const SizedBox(height: 24),

          // Version info box
          _buildVersionInfo(),
          const SizedBox(height: 24),

          // PIN input with show/hide toggle
          _buildPinInput(),
          const SizedBox(height: 16),

          // Number pad
          _buildNumberPad(),
          const SizedBox(height: 16),

          // Error message
          if (_error != null) _buildErrorMessage(),
          if (_error != null) const SizedBox(height: 16),

          // Login button
          SkaButton(
            text: 'Log ind',
            variant: ButtonVariant.primary,
            fullWidth: true,
            loading: _isLoading,
            onPressed: _pin.length == 4 ? _handleLogin : null,
          ),
        ],
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Container(
      padding: AppSpacing.p3,
      decoration: BoxDecoration(
        color: AppColors.blue50,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: AppColors.blue200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.code,
                size: 16,
                color: AppColors.blue600,
              ),
              const SizedBox(width: 6),
              Text(
                'Version 2.0.0',
                style: AppTypography.xsSemibold.copyWith(
                  color: AppColors.blue700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Build: 19. december 2025',
            style: AppTypography.xs.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _buildFeatureTag('NFC'),
              _buildFeatureTag('Offline'),
              _buildFeatureTag('Sync'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.blue100,
        borderRadius: AppRadius.radiusMd,
      ),
      child: Text(
        label,
        style: AppTypography.xs.copyWith(
          color: AppColors.blue700,
        ),
      ),
    );
  }

  Widget _buildPinInput() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // PIN display
            Expanded(
              child: Container(
                padding: AppSpacing.symmetric(
                  horizontal: AppSpacing.s4,
                  vertical: AppSpacing.s3,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: AppRadius.radiusMd,
                ),
                child: Text(
                  _obscureText
                      ? '•' * _pin.length + '_' * (4 - _pin.length)
                      : _pin.padRight(4, '_'),
                  style: AppTypography.style(
                    size: AppTypography.text2xl,
                    weight: AppTypography.fontBold,
                    letterSpacing: AppTypography.trackingWidest,
                  ).copyWith(color: AppColors.foreground),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Show/hide toggle
            SkaButton(
              variant: ButtonVariant.ghost,
              size: ButtonSize.icon,
              child: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        // Rows 1-3: numbers 1-9
        for (int row = 0; row < 3; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                for (int col = 1; col <= 3; col++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: col < 3 ? 8 : 0,
                      ),
                      child: _buildNumberButton((row * 3 + col).toString()),
                    ),
                  ),
              ],
            ),
          ),
        // Bottom row: Ryd, 0, Backspace
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildActionButton('Ryd', Icons.clear, _clearPin),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildNumberButton('0'),
              ),
            ),
            Expanded(
              child: _buildActionButton('←', Icons.backspace, _backspace),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberButton(String number) {
    return SizedBox(
      height: 48,
      child: SkaButton(
        text: number,
        variant: ButtonVariant.outline,
        onPressed: _pin.length < 4 ? () => _addDigit(number) : null,
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      height: 48,
      child: SkaButton(
        text: label,
        variant: ButtonVariant.outline,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: AppSpacing.p2,
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: AppRadius.radiusMd,
      ),
      child: Text(
        _error!,
        style: AppTypography.sm.copyWith(
          color: AppColors.error,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAvailableUsers() {
    final users = _dbService.getAllUsers();
    if (users.isEmpty) return const SizedBox.shrink();

    return SkaCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: AppSpacing.p4,
            child: Text(
              'Tilgængelige brugere',
              style: AppTypography.smSemibold.copyWith(
                color: AppColors.foreground,
              ),
            ),
          ),
          const Divider(height: 1),
          ...users.map((user) => _buildUserItem(user)),
        ],
      ),
    );
  }

  Widget _buildUserItem(user) {
    return InkWell(
      onTap: () {
        // Show hint that user should enter their PIN
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Indtast PIN for ${user.name}'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Padding(
        padding: AppSpacing.p4,
        child: Row(
          children: [
            Icon(
              Icons.person,
              color: AppColors.mutedForeground,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                user.name,
                style: AppTypography.sm.copyWith(
                  color: AppColors.foreground,
                ),
              ),
            ),
            Icon(
              Icons.lock_outline,
              color: AppColors.mutedForeground,
              size: 16,
            ),
            const SizedBox(width: 8),
            SkaBadge(
              text: '4 cifre',
              variant: BadgeVariant.secondary,
              small: true,
            ),
          ],
        ),
      ),
    );
  }

  void _addDigit(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin += digit;
        _error = null;
      });
    }
  }

  void _backspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _error = null;
      });
    }
  }

  void _clearPin() {
    setState(() {
      _pin = '';
      _error = null;
    });
  }

  Future<void> _handleLogin() async {
    if (_pin.length != 4) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Validate PIN format
    if (!_authService.isValidPin(_pin)) {
      setState(() {
        _error = 'PIN skal være 4 cifre';
        _isLoading = false;
        _pin = '';
      });
      return;
    }

    // Attempt login
    final success = await _authService.login(_pin);

    if (!mounted) return;

    if (success) {
      // Reload theme for logged-in user
      await context.read<legacy_theme.ThemeProvider>().reloadForCurrentUser();
      if (!mounted) return;

      // Navigate to sager (matches React)
      Navigator.of(context).pushReplacementNamed('/sager');
    } else {
      setState(() {
        _error = 'Forkert PIN';
        _pin = '';
        _isLoading = false;
      });
    }
  }
}
