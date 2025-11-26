import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../providers/theme_provider.dart';
import '../models/user.dart';
import '../models/sag.dart';
import '../models/affugter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  final _databaseService = DatabaseService();
  late User _currentUser;
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
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error loading dashboard data: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      await context.read<ThemeProvider>().reloadForCurrentUser();
      Navigator.of(context).pushReplacementNamed('/login');
    }
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
      return Scaffold(
        appBar: AppBar(
          title: const Text('SKA-DAN'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final stats = _getAffugterStats();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            SvgPicture.asset(
              'assets/images/ska-dan-white.svg',
              height: 32,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : null,
            ),
          ],
        ),
        actions: [
          // User info and settings menu
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            onSelected: (value) {
              switch (value) {
                case 'users':
                  Navigator.pushNamed(context, '/users');
                  break;
                case 'settings':
                  Navigator.pushNamed(context, '/admin-settings');
                  break;
                case 'role-permissions':
                  Navigator.pushNamed(context, '/role-permissions');
                  break;
                case 'theme':
                  final themeProvider = context.read<ThemeProvider>();
                  themeProvider.setThemeMode(
                    themeProvider.themeMode == ThemeMode.dark
                        ? ThemeMode.light
                        : ThemeMode.dark,
                  );
                  break;
                case 'logout':
                  _handleLogout();
                  break;
              }
            },
            itemBuilder: (context) {
              final theme = Theme.of(context);
              return [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentUser.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _currentUser.role == 'admin'
                            ? AppColors.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _currentUser.role.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: _currentUser.role == 'admin' ? Colors.white : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              if (_authService.currentUser?.role == 'admin') ...[
                const PopupMenuItem(
                  value: 'users',
                  child: Row(
                    children: [
                      Icon(Icons.people, size: 20),
                      SizedBox(width: 12),
                      Text('Brugeradministration'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, size: 20),
                      SizedBox(width: 12),
                      Text('Indstillinger'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'role-permissions',
                  child: Row(
                    children: [
                      Icon(Icons.security, size: 20),
                      SizedBox(width: 12),
                      Text('Roller & Tilladelser'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
              ],
              PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(
                      context.read<ThemeProvider>().themeMode == ThemeMode.dark
                          ? Icons.light_mode
                          : Icons.dark_mode,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      context.read<ThemeProvider>().themeMode == ThemeMode.dark
                          ? 'Lyst tema'
                          : 'Mørkt tema',
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Log ud', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ];
            },
            child: Builder(
              builder: (context) {
                final theme = Theme.of(context);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentUser.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _currentUser.role == 'admin'
                                  ? AppColors.primary
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _currentUser.role.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: _currentUser.role == 'admin' ? Colors.white : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.settings, color: theme.colorScheme.onSurfaceVariant, size: 20),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final isNarrow = screenWidth < 600;
          final statColumns = isNarrow ? 2 : 4;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Actions
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hovedfunktioner',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Vælg en funktion for at komme i gang',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Primary Functions - full width
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildActionButton(
                                title: 'Sager',
                                subtitle: 'Se og opret sager',
                                icon: Icons.description,
                                onTap: () => Navigator.pushNamed(context, '/sager'),
                                isPrimary: true,
                              ),
                              const SizedBox(height: 12),
                              _buildActionButton(
                                title: 'NFC Scanner',
                                subtitle: 'Scan affugtere',
                                icon: Icons.nfc,
                                onTap: () => Navigator.pushNamed(context, '/nfc-scanner'),
                              ),
                              const SizedBox(height: 12),
                              _buildActionButton(
                                title: 'Udstyr Oversigt',
                                subtitle: 'Affugtere og udstyr med NFC',
                                icon: Icons.air,
                                onTap: () => Navigator.pushNamed(context, '/affugtere'),
                              ),
                            ],
                          ),

                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Quick Stats - responsive grid
                  GridView.count(
                    crossAxisCount: statColumns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    childAspectRatio: isNarrow ? 1.5 : 1.3,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStatCard(
                        label: 'Aktive sager',
                        value: '${_aktiveSager.length}',
                        icon: Icons.description,
                        color: AppColors.primary,
                        onTap: () => Navigator.pushNamed(context, '/sager'),
                      ),
                      _buildStatCard(
                        label: 'Affugtere hjemme',
                        value: '${stats['hjemme']}',
                        icon: Icons.home,
                        color: Colors.green,
                        onTap: () => Navigator.pushNamed(context, '/affugtere'),
                      ),
                      _buildStatCard(
                        label: 'Udlejet',
                        value: '${stats['udlejet']}',
                        icon: Icons.inventory_2,
                        color: Colors.orange,
                        onTap: () => Navigator.pushNamed(context, '/affugtere'),
                      ),
                      _buildStatCard(
                        label: 'Defekt',
                        value: '${stats['defekt']}',
                        icon: Icons.warning,
                        color: Colors.red,
                        onTap: () => Navigator.pushNamed(context, '/affugtere'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Recent Cases
                  if (_aktiveSager.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Seneste sager',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    Text(
                                      'Aktive sager - klik for detaljer eller hurtige handlinger',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                if (_authService.currentUser?.role == 'admin')
                                  TextButton.icon(
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Ny sag'),
                                    onPressed: () => Navigator.pushNamed(context, '/ny-sag'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ..._aktiveSager.take(5).map((sag) => _buildSagItem(sag)),
                            if (_aktiveSager.length > 5)
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, '/sager'),
                                child: Text('Se alle sager (${_aktiveSager.length})'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.description,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Ingen aktive sager',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      color: color.withValues(alpha: 0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return SizedBox(
      height: 80,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: isPrimary ? AppColors.primary : theme.cardColor,
              foregroundColor: isPrimary ? Colors.white : theme.colorScheme.onSurface,
              elevation: isPrimary ? 2 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isPrimary ? BorderSide.none : BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              padding: const EdgeInsets.all(12),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isPrimary ? Colors.white : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isPrimary ? Colors.white70 : theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSagItem(Sag sag) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/sager/${sag.id}'),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sag.sagsnr,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sag.adresse,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    sag.byggeleder,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Aktiv',
                style: TextStyle(fontSize: 11),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.nfc, size: 18, color: AppColors.primary),
              onPressed: () => Navigator.pushNamed(context, '/nfc-scanner'),
              tooltip: 'NFC',
            ),
            IconButton(
              icon: const Icon(Icons.timer, size: 18, color: Colors.green),
              onPressed: () => Navigator.pushNamed(context, '/timer'),
              tooltip: 'Timer',
            ),
          ],
        ),
      ),
    );
  }
}
