import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/roles_and_features.dart';
import '../models/affugter.dart';
import '../models/sag.dart';
import '../models/user.dart';
import '../providers/theme_provider.dart' as legacy_theme;
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/nfc_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/access_controlled_widget.dart';
import '../widgets/offline_indicator.dart';
import '../widgets/project_leader_dropdown.dart';
import '../widgets/responsive_builder.dart';
import '../widgets/theme_toggle.dart';
import '../widgets/ui/ska_badge.dart';
import '../widgets/ui/ska_button.dart';
import '../widgets/ui/ska_card.dart';
import '../widgets/ui/ska_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  final _databaseService = DatabaseService();
  final _nfcService = NFCService();

  User? _currentUser;
  List<Sag> _aktiveSager = [];
  List<Affugter> _alleAffugtere = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _loadDashboardData();
  }

  void _checkAuth() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return;
    }
    _currentUser = currentUser;
  }

  Future<void> _loadDashboardData() async {
    try {
      final alleSager = _databaseService.getAllSager();
      final alleAffugtere = _databaseService.getAllAffugtere();

      setState(() {
        _aktiveSager = alleSager.where((sag) => sag.aktiv).toList();
        _alleAffugtere = alleAffugtere;
      });
    } catch (error) {
      debugPrint('Error loading dashboard data: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;
    await context.read<legacy_theme.ThemeProvider>().reloadForCurrentUser();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _handleUdstyrInfo() async {
    final isSupported = await _nfcService.isSupported();
    if (!mounted) return;
    if (!isSupported) {
      await SkaDialog.showAlert(
        context: context,
        title: 'NFC ikke tilgængelig',
        message: 'NFC scanning er kun tilgængelig på Android enheder.',
      );
      return;
    }

    bool dialogOpen = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
        child: Padding(
          padding: AppSpacing.p6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.nfc, size: 32, color: AppColors.primary),
              const SizedBox(height: AppSpacing.s4),
              Text(
                'Udstyr info',
                style: AppTypography.lgSemibold.copyWith(color: AppColors.foreground),
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                'Hold telefonen på NFC-tagget for at slå udstyret op',
                style: AppTypography.sm.copyWith(color: AppColors.mutedForeground),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s4),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.s4),
              SkaButton(
                variant: ButtonVariant.ghost,
                text: 'Annuller',
                onPressed: () {
                  dialogOpen = false;
                  _nfcService.stopScanning();
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      dialogOpen = false;
      _nfcService.stopScanning();
    });

    await _nfcService.startScanning(
      onRead: (nfcData) async {
        if (!mounted) return;
        if (dialogOpen) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        await _showEquipmentLookupResult(nfcData);
      },
      onError: (message) async {
        if (!mounted) return;
        if (dialogOpen) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        await SkaDialog.showAlert(
          context: context,
          title: 'NFC fejl',
          message: message,
        );
      },
    );
  }

  Future<void> _showEquipmentLookupResult(NFCData nfcData) async {
    if (nfcData.id.isEmpty) {
      await SkaDialog.showAlert(
        context: context,
        title: 'Udstyr ikke fundet',
        message: 'Der blev ikke fundet et udstyr-ID på NFC-tagget.',
      );
      return;
    }

    Affugter? affugter;
    try {
      affugter = _databaseService.getAffugterByNr(nfcData.id);
    } catch (_) {
      affugter = null;
    }

    if (affugter == null) {
      await SkaDialog.showAlert(
        context: context,
        title: 'Udstyr ikke fundet',
        message: 'Udstyr med nr. ${nfcData.id} findes ikke i databasen.',
      );
      return;
    }

    Sag? sag;
    if (affugter.currentSagId != null && affugter.currentSagId!.isNotEmpty) {
      sag = await _databaseService.getSag(affugter.currentSagId!);
    }

    if (!mounted) return;
    await SkaDialog.show(
      context: context,
      title: 'Udstyr information',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Nr', affugter.nr),
          _buildInfoRow('Type', affugter.type),
          _buildInfoRow('Mærke', affugter.maerke),
          if (affugter.model != null && affugter.model!.isNotEmpty)
            _buildInfoRow('Model', affugter.model!),
          _buildInfoRow('Status', affugter.status),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Tildelt til',
            style: AppTypography.smSemibold.copyWith(color: AppColors.foreground),
          ),
          const SizedBox(height: AppSpacing.s2),
          if (sag != null && (sag.arkiveret != true))
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Sag', sag.sagsnr),
                _buildInfoRow('Adresse', sag.adresse),
                _buildInfoRow('Byggeleder', sag.byggeleder),
              ],
            )
          else
            Text(
              'Ikke tildelt til aktiv sag',
              style: AppTypography.sm.copyWith(color: AppColors.mutedForeground),
            ),
        ],
      ),
      actions: [
        SkaButton(
          variant: ButtonVariant.ghost,
          text: 'Luk',
          onPressed: () => Navigator.of(context).pop(),
        ),
        if (sag != null && (sag.arkiveret != true))
          SkaButton(
            text: 'Åbn sag',
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, '/sager/${sag!.id}');
            },
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: AppTypography.sm.copyWith(color: AppColors.mutedForeground),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.sm.copyWith(color: AppColors.foreground),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _getAffugterStats() {
    final hjemme = _alleAffugtere.where((a) => a.status == 'hjemme').length;
    final udlejet = _alleAffugtere.where((a) => a.status == 'udlejet').length;
    final defekt = _alleAffugtere.where((a) => a.status == 'defekt').length;

    return {
      'hjemme': hjemme,
      'udlejet': udlejet,
      'defekt': defekt,
      'total': _alleAffugtere.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_authService.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final stats = _getAffugterStats();
    final currentSag = _aktiveSager.isNotEmpty ? _aktiveSager.first : null;

    final statsSection = _buildStatsSection(stats);
    final actionsSection = _buildMainActionsSection();
    final recentSection = _buildRecentCasesSection();

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: Column(
        children: [
          _buildHeader(currentSag),
          Expanded(
            child: SingleChildScrollView(
              child: MaxWidthContainer(
                padding: AppSpacing.p4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (statsSection != null) ...[
                      statsSection,
                      const SizedBox(height: AppSpacing.s6),
                    ],
                    if (actionsSection != null) ...[
                      actionsSection,
                      const SizedBox(height: AppSpacing.s6),
                    ],
                    if (recentSection != null) recentSection,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Sag? currentSag) {
    final userName = _currentUser?.name ?? '';
    final role = _currentUser?.role ?? '';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: AppShadows.shadowSm,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: AppSpacing.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SKA-DAN',
                      style: AppTypography.style(
                        size: AppTypography.textXl,
                        weight: AppTypography.fontBold,
                        color: AppColors.titleBlue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Velkommen, $userName',
                      style: AppTypography.sm.copyWith(
                        color: AppColors.lightForeground,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: AppSpacing.s2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ProjectLeaderDropdown(
                    currentSag: currentSag,
                    showWhenEmpty: true,
                  ),
                  const ThemeToggle(),
                  const OfflineIndicator(),
                  SkaBadge(
                    text: role,
                    variant: role == AppRoles.admin ? BadgeVariant.primary : BadgeVariant.secondary,
                    small: true,
                  ),
                  SkaButton(
                    variant: ButtonVariant.ghost,
                    size: ButtonSize.sm,
                    child: const Icon(Icons.logout, size: 16),
                    onPressed: _handleLogout,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildStatsSection(Map<String, int> stats) {
    final cards = <Widget>[];

    if (_authService.hasFeature(AppFeatures.viewCases)) {
      cards.add(
        _buildStatCard(
          label: 'Aktive sager',
          value: '${_aktiveSager.length}',
          icon: Icons.description,
          iconColor: AppColors.primary,
          valueColor: AppColors.foreground,
          onTap: () => Navigator.pushNamed(context, '/sager'),
        ),
      );
    }

    if (_authService.hasFeature(AppFeatures.equipmentManagement)) {
      cards.addAll([
        _buildStatCard(
          label: 'Affugtere hjemme',
          value: '${stats['hjemme']}',
          icon: Icons.inventory_2,
          iconColor: AppColors.success,
          valueColor: AppColors.success,
          onTap: () => Navigator.pushNamed(context, '/affugtere'),
        ),
        _buildStatCard(
          label: 'Udlejet',
          value: '${stats['udlejet']}',
          icon: Icons.inventory_2,
          iconColor: AppColors.warning,
          valueColor: AppColors.warning,
          onTap: () => Navigator.pushNamed(context, '/affugtere'),
        ),
        _buildStatCard(
          label: 'Defekt',
          value: '${stats['defekt']}',
          icon: Icons.inventory_2,
          iconColor: AppColors.error,
          valueColor: AppColors.error,
          onTap: () => Navigator.pushNamed(context, '/affugtere'),
        ),
      ]);
    }

    if (cards.isEmpty) {
      return null;
    }

    return _buildResponsiveGrid(
      children: cards,
      mobileColumns: 2,
      tabletColumns: 4,
      desktopColumns: 4,
      spacing: AppSpacing.s4,
    );
  }

  Widget? _buildMainActionsSection() {
    final actions = <Widget>[];

    if (_authService.hasFeature(AppFeatures.viewCases)) {
      actions.add(
        _buildActionButton(
          title: 'Sager',
          subtitle: 'Se og opret sager',
          icon: Icons.description,
          variant: ButtonVariant.primary,
          onTap: () => Navigator.pushNamed(context, '/sager'),
        ),
      );
    }

    if (_authService.hasFeature(AppFeatures.nfcScanning)) {
      actions.add(
        _buildActionButton(
          title: 'NFC Scanner',
          subtitle: 'Scan affugtere',
          icon: Icons.smartphone,
          variant: ButtonVariant.outline,
          onTap: () => Navigator.pushNamed(context, '/nfc-scanner'),
        ),
      );
      actions.add(
        _buildActionButton(
          title: 'Udstyr info',
          subtitle: 'Slå udstyr op via NFC',
          icon: Icons.nfc,
          variant: ButtonVariant.outline,
          onTap: _handleUdstyrInfo,
        ),
      );
    }

    if (_authService.hasFeature(AppFeatures.equipmentManagement)) {
      actions.addAll([
        _buildActionButton(
          title: 'Affugter lager',
          subtitle: 'Lageroversigt',
          icon: Icons.inventory_2,
          variant: ButtonVariant.outline,
          onTap: () => Navigator.pushNamed(context, '/affugtere'),
        ),
        _buildActionButton(
          title: 'Udstyr Oversigt',
          subtitle: 'Alt udstyr på tværs af sager',
          icon: Icons.build,
          variant: ButtonVariant.outline,
          onTap: () => Navigator.pushNamed(context, '/udstyr-oversigt'),
        ),
      ]);
    }

    if (actions.isEmpty) {
      return null;
    }

    return SkaCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkaCardHeader(
            title: 'Hovedfunktioner',
            description: 'Vælg en funktion for at komme i gang',
            padding: AppSpacing.p4,
          ),
          SkaCardContent(
            padding: AppSpacing.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s4),
            child: _buildResponsiveGrid(
              children: actions,
              mobileColumns: 1,
              tabletColumns: 2,
              desktopColumns: 2,
              spacing: AppSpacing.s3,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildRecentCasesSection() {
    if (!_authService.hasFeature(AppFeatures.viewCases)) {
      return null;
    }

    if (_aktiveSager.isEmpty) {
      return _buildNoCasesCard();
    }

    return SkaCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkaCardHeader(
            title: 'Seneste sager',
            description: 'Aktive sager - klik for detaljer eller hurtige handlinger',
            padding: AppSpacing.p4,
            trailing: AccessControlledWidget(
              featureKey: AppFeatures.createCases,
              child: SkaButton(
                size: ButtonSize.sm,
                icon: const Icon(Icons.add, size: 16),
                text: 'Ny sag',
                onPressed: () => Navigator.pushNamed(context, '/sager/ny'),
              ),
            ),
          ),
          SkaCardContent(
            padding: AppSpacing.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s4),
            child: Column(
              children: [
                ..._aktiveSager.take(5).map(_buildSagItem),
                if (_aktiveSager.length > 5) ...[
                  const SizedBox(height: AppSpacing.s3),
                  SkaButton(
                    variant: ButtonVariant.ghost,
                    size: ButtonSize.sm,
                    fullWidth: true,
                    text: 'Se alle sager (${_aktiveSager.length})',
                    onPressed: () => Navigator.pushNamed(context, '/sager'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCasesCard() {
    return SkaCard(
      padding: AppSpacing.p8,
      child: Column(
        children: [
          const Icon(
            Icons.description,
            size: 48,
            color: AppColors.gray400,
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Ingen aktive sager',
            style: AppTypography.lgSemibold.copyWith(
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Opret din første sag for at komme i gang',
            style: AppTypography.sm.copyWith(
              color: AppColors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
          AccessControlledWidget(
            featureKey: AppFeatures.createCases,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s4),
              child: SkaButton(
                icon: const Icon(Icons.add, size: 16),
                text: 'Opret første sag',
                onPressed: () => Navigator.pushNamed(context, '/sager/ny'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color valueColor,
    required VoidCallback onTap,
  }) {
    return SkaCard(
      padding: AppSpacing.p4,
      hoverable: true,
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.sm.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTypography.xl2Bold.copyWith(
                  color: valueColor,
                ),
              ),
            ],
          ),
          Icon(icon, size: 32, color: iconColor),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required ButtonVariant variant,
    required VoidCallback onTap,
  }) {
    final isPrimary = variant == ButtonVariant.primary;
    final titleColor = isPrimary ? AppColors.primaryForeground : AppColors.foreground;
    final subtitleColor = isPrimary
        ? AppColors.primaryForeground.withOpacity(0.7)
        : AppColors.mutedForeground;

    return SkaButton(
      onPressed: onTap,
      variant: variant,
      size: ButtonSize.xl,
      fullWidth: true,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(icon, size: 20, color: titleColor),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTypography.smSemibold.copyWith(
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.xs.copyWith(
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSagItem(Sag sag) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.radiusLg,
          hoverColor: AppColors.backgroundSecondary,
          onTap: () => Navigator.pushNamed(context, '/sager/${sag.id}'),
          child: Ink(
            padding: AppSpacing.p3,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppRadius.radiusLg,
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sag.sagsnr,
                        style: AppTypography.smSemibold.copyWith(
                          color: AppColors.foreground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sag.adresse,
                        style: AppTypography.sm.copyWith(
                          color: AppColors.lightForeground,
                        ),
                      ),
                      Text(
                        sag.byggeleder,
                        style: AppTypography.xs.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SkaBadge(
                      text: 'Aktiv',
                      variant: BadgeVariant.outline,
                      small: true,
                    ),
                    const SizedBox(width: AppSpacing.s2),
                    if (_authService.hasFeature(AppFeatures.nfcScanning))
                      SkaButton(
                        variant: ButtonVariant.outline,
                        size: ButtonSize.sm,
                        onPressed: () => Navigator.pushNamed(context, '/nfc-scanner/${sag.id}'),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.smartphone, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'NFC',
                              style: AppTypography.xsMedium.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_authService.hasFeature(AppFeatures.timeTracking)) ...[
                      const SizedBox(width: AppSpacing.s2),
                      SkaButton(
                        variant: ButtonVariant.outline,
                        size: ButtonSize.sm,
                        onPressed: () => Navigator.pushNamed(context, '/timer/${sag.id}'),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer, size: 14, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              'Timer',
                              style: AppTypography.xsMedium.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveGrid({
    required List<Widget> children,
    required int mobileColumns,
    required int tabletColumns,
    required int desktopColumns,
    required double spacing,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (children.isEmpty) {
          return const SizedBox.shrink();
        }

        int columns = mobileColumns;
        if (constraints.maxWidth >= Breakpoints.lg) {
          columns = desktopColumns;
        } else if (constraints.maxWidth >= Breakpoints.md) {
          columns = tabletColumns;
        }

        if (children.length < columns) {
          columns = children.length;
        }

        final totalSpacing = spacing * (columns - 1);
        final itemWidth = (constraints.maxWidth - totalSpacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map(
                (child) => SizedBox(
                  width: itemWidth,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }
}
