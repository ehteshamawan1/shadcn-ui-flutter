import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import '../services/sync_service.dart';
import 'ui/ska_badge.dart';
import 'ui/ska_button.dart';

/// Enhanced offline indicator matching React EnhancedOfflineIndicator.tsx
/// Shows online/offline status, pending changes count, and sync controls
class OfflineIndicator extends StatefulWidget {
  const OfflineIndicator({super.key});

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  final SyncService _syncService = SyncService();
  bool _isOnline = true;
  int _pendingCount = 0;
  bool _isSyncing = false;
  String? _lastError;
  StreamSubscription? _syncSubscription;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    _listenToSync();
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  void _listenToSync() {
    // Listen for sync status changes
    _syncSubscription = _syncService.syncStatusStream.listen((_) {
      if (mounted) {
        _loadStatus();
      }
    });
  }

  Future<void> _loadStatus() async {
    final isOnline = await _syncService.isOnline();
    final pendingCount = await _syncService.getPendingChangesCount();
    final isSyncing = _syncService.isSyncing;

    if (mounted) {
      setState(() {
        _isOnline = isOnline;
        _pendingCount = pendingCount;
        _isSyncing = isSyncing;
      });
    }
  }

  Future<void> _forceSync() async {
    if (!_isOnline || _isSyncing) return;

    setState(() {
      _isSyncing = true;
      _lastError = null;
    });

    try {
      await _syncService.syncNow();
      await _loadStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Synkronisering gennemført'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _lastError = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Synkronisering fejlede: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: _isOnline ? 'Online - Klik for detaljer' : 'Offline - Klik for detaljer',
      icon: _buildIcon(),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusLg,
        side: BorderSide(color: AppColors.border, width: 1),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status header
                Row(
                  children: [
                    Icon(
                      _isOnline ? Icons.cloud_done : Icons.cloud_off,
                      color: _isOnline ? AppColors.success : AppColors.mutedForeground,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isOnline ? 'Online' : 'Offline',
                      style: AppTypography.baseSemibold.copyWith(
                        color: AppColors.foreground,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Pending changes count
                if (_pendingCount > 0) ...[
                  Container(
                    padding: AppSpacing.p3,
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: AppRadius.radiusMd,
                      border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.pending_actions,
                          size: 16,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$_pendingCount ventende ændring${_pendingCount > 1 ? 'er' : ''}',
                            style: AppTypography.sm.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Sync status
                if (_isSyncing) ...[
                  Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Synkroniserer...',
                        style: AppTypography.sm.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Error message
                if (_lastError != null) ...[
                  Container(
                    padding: AppSpacing.p3,
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: AppRadius.radiusMd,
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 16,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _lastError!,
                            style: AppTypography.xs.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Force sync button
                if (_isOnline && !_isSyncing) ...[
                  SkaButton(
                    text: 'Synkroniser nu',
                    icon: const Icon(Icons.sync, size: 16),
                    variant: ButtonVariant.outline,
                    size: ButtonSize.sm,
                    fullWidth: true,
                    onPressed: _forceSync,
                  ),
                ],

                // Offline mode info
                if (!_isOnline) ...[
                  Text(
                    'Ændringer gemmes lokalt og synkroniseres automatisk når du kommer online igen.',
                    style: AppTypography.xs.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIcon() {
    if (_isSyncing) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            AppColors.primary,
          ),
        ),
      );
    }

    if (!_isOnline) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.cloud_off,
            color: AppColors.mutedForeground,
            size: 20,
          ),
          if (_pendingCount > 0)
            Positioned(
              right: -6,
              top: -6,
              child: SkaBadgeCount(
                count: _pendingCount,
                backgroundColor: AppColors.warning,
              ),
            ),
        ],
      );
    }

    if (_pendingCount > 0) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.cloud_queue,
            color: AppColors.warning,
            size: 20,
          ),
          Positioned(
            right: -6,
            top: -6,
            child: SkaBadgeCount(
              count: _pendingCount,
              backgroundColor: AppColors.warning,
            ),
          ),
        ],
      );
    }

    return Icon(
      Icons.cloud_done,
      color: AppColors.success,
      size: 20,
    );
  }
}
