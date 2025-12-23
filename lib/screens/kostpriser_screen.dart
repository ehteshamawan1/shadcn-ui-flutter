import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/kostpris.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ui/ska_button.dart';
import '../widgets/ui/ska_card.dart';
import '../widgets/ui/ska_input.dart';

/// Admin screen for managing cost prices (Kostpriser) and default sales prices
/// Only accessible to admin users
class KostpriserScreen extends StatefulWidget {
  const KostpriserScreen({super.key});

  @override
  State<KostpriserScreen> createState() => _KostpriserScreenState();
}

class _KostpriserScreenState extends State<KostpriserScreen> with SingleTickerProviderStateMixin {
  final _dbService = DatabaseService();
  final _authService = AuthService();
  late TabController _tabController;
  bool _isLoading = true;
  List<Kostpris> _kostpriser = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Initialize default kostpriser if empty
    await _dbService.initDefaultKostpriser();

    final kostpriser = _dbService.getAllKostpriser();
    setState(() {
      _kostpriser = kostpriser;
      _isLoading = false;
    });
  }

  List<Kostpris> _getKostpriserForGroup(String group) {
    return _kostpriser.where((k) => k.groupName == group).toList()
      ..sort((a, b) => a.category.compareTo(b.category));
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'da_DK', symbol: 'DKK', decimalDigits: 0);
    return formatter.format(amount);
  }

  Future<void> _editKostpris(Kostpris kostpris) async {
    final kostprisController = TextEditingController(text: kostpris.kostpris.toStringAsFixed(0));
    final salgsprisController = TextEditingController(text: kostpris.salgspris.toStringAsFixed(0));

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rediger ${kostpris.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SkaInput(
              label: 'Kostpris (DKK)',
              helper: 'Intern omkostning - kun synlig for admin',
              controller: kostprisController,
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.lock),
            ),
            const SizedBox(height: 16),
            SkaInput(
              label: 'Salgspris (DKK)',
              helper: 'Standard salgspris paa fakturaer',
              controller: salgsprisController,
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.receipt),
            ),
            const SizedBox(height: 16),
            // Show calculated margin
            Builder(
              builder: (context) {
                final kostprisValue = double.tryParse(kostprisController.text) ?? 0;
                final salgsprisValue = double.tryParse(salgsprisController.text) ?? 0;
                final margin = salgsprisValue > 0
                    ? ((salgsprisValue - kostprisValue) / salgsprisValue * 100)
                    : 0.0;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: margin >= 30 ? Colors.green.withOpacity(0.1)
                         : margin >= 15 ? Colors.orange.withOpacity(0.1)
                         : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Avance:'),
                      Text(
                        '${margin.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: margin >= 30 ? Colors.green
                               : margin >= 15 ? Colors.orange
                               : Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          SkaButton(
            onPressed: () => Navigator.pop(context, false),
            variant: ButtonVariant.ghost,
            text: 'Annuller',
          ),
          SkaButton(
            onPressed: () => Navigator.pop(context, true),
            variant: ButtonVariant.primary,
            text: 'Gem',
          ),
        ],
      ),
    );

    if (result == true) {
      final newKostpris = double.tryParse(kostprisController.text) ?? kostpris.kostpris;
      final newSalgspris = double.tryParse(salgsprisController.text) ?? kostpris.salgspris;

      final updated = kostpris.copyWith(
        kostpris: newKostpris,
        salgspris: newSalgspris,
        updatedAt: DateTime.now().toIso8601String(),
      );

      await _dbService.upsertKostpris(updated, byUserName: _authService.currentUser?.name);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${kostpris.displayName} opdateret'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }

    kostprisController.dispose();
    salgsprisController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kostpriser Administration'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Opdater',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Information',
            onPressed: () => _showInfoDialog(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Timer'),
            Tab(text: 'Udstyr'),
            Tab(text: 'Blokke'),
            Tab(text: 'Overhead'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.amber.withOpacity(0.2),
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: Colors.amber[800]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Kun admin har adgang til denne side. Kostpriser bruges til rentabilitetsberegning.',
                          style: TextStyle(color: Colors.amber[900], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

                // Summary cards
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildSummaryCard(
                        'Gennemsnit avance',
                        '${_calculateAverageMargin().toStringAsFixed(1)}%',
                        _calculateAverageMargin() >= 30 ? Colors.green : Colors.orange,
                        Icons.trending_up,
                      ),
                      const SizedBox(width: 12),
                      _buildSummaryCard(
                        'Antal priser',
                        '${_kostpriser.length}',
                        AppColors.primary,
                        Icons.list_alt,
                      ),
                    ],
                  ),
                ),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPriceList('Timer'),
                      _buildPriceList('Udstyr'),
                      _buildPriceList('Blokke'),
                      _buildPriceList('Overhead'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: SkaCard(
        padding: AppSpacing.p4,
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.xs.copyWith(color: AppColors.mutedForeground)),
                Text(
                  value,
                  style: AppTypography.lgSemibold.copyWith(color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateAverageMargin() {
    if (_kostpriser.isEmpty) return 0;
    final margins = _kostpriser.map((k) => k.profitMargin).toList();
    return margins.reduce((a, b) => a + b) / margins.length;
  }

  Widget _buildPriceList(String group) {
    final priser = _getKostpriserForGroup(group);

    if (priser.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.price_change_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Ingen priser i denne kategori',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: priser.length,
      itemBuilder: (context, index) {
        final pris = priser[index];
        return _buildPriceCard(pris);
      },
    );
  }

  Widget _buildPriceCard(Kostpris pris) {
    final margin = pris.profitMargin;
    final marginColor = margin >= 30 ? Colors.green
                      : margin >= 15 ? Colors.orange
                      : Colors.red;

    return SkaCard(
      padding: AppSpacing.p4,
      onTap: () => _editKostpris(pris),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIconForCategory(pris.category),
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),

          // Name
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pris.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  pris.category,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Cost price (admin only)
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      _formatCurrency(pris.kostpris),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Text(
                  'Kostpris',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Sales price
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(pris.salgspris),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Salgspris',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Margin
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: marginColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${margin.toStringAsFixed(0)}%',
              style: TextStyle(
                color: marginColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),

          // Edit button
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editKostpris(pris),
            tooltip: 'Rediger',
          ),
        ],
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    if (category.startsWith('labor_')) return Icons.timer;
    if (category.startsWith('equipment_')) return Icons.inventory_2;
    if (category.startsWith('blok_')) return Icons.view_quilt;
    if (category.contains('overhead')) return Icons.percent;
    if (category.contains('drift')) return Icons.settings;
    return Icons.payments;
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Om Kostpriser'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kostpriser Administration',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Her kan du konfigurere alle priser i systemet:',
            ),
            SizedBox(height: 8),
            Text('Kostpris: Din interne omkostning (kun synlig for admin)'),
            SizedBox(height: 4),
            Text('Salgspris: Standard pris på fakturaer'),
            SizedBox(height: 4),
            Text('Avance: Beregnet margin (salgspris - kostpris)'),
            SizedBox(height: 16),
            Text(
              'Salgspriser kan overstyres per sag i sag-detaljer.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 16),
            Text(
              'Farve-koder for avance:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text('Grøn: 30%+ (God avance)'),
            Text('Orange: 15-30% (OK avance)'),
            Text('Rød: Under 15% (Lav avance)'),
          ],
        ),
        actions: [
          SkaButton(
            text: 'Luk',
            variant: ButtonVariant.secondary,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
