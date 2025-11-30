import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// Widget that conditionally shows its child based on user permissions.
///
/// Usage:
/// ```dart
/// AccessControlledWidget(
///   featureKey: AppFeatures.profitability,
///   child: ElevatedButton(...),
/// )
/// ```
///
/// The widget will be hidden if the user doesn't have the specified feature.
/// Admins always have access to all features.
class AccessControlledWidget extends StatelessWidget {
  /// The feature key to check (e.g., 'rentabilitet', 'faktura')
  final String featureKey;

  /// The widget to show if user has access
  final Widget child;

  /// Optional widget to show if user doesn't have access
  /// If null, nothing will be rendered
  final Widget? fallback;

  /// If true, shows a disabled version of the child instead of hiding it
  final bool showDisabled;

  /// Optional callback when an unauthorized user tries to access
  final VoidCallback? onAccessDenied;

  const AccessControlledWidget({
    super.key,
    required this.featureKey,
    required this.child,
    this.fallback,
    this.showDisabled = false,
    this.onAccessDenied,
  });

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final hasAccess = authService.hasFeature(featureKey);

    if (hasAccess) {
      return child;
    }

    if (showDisabled) {
      return Opacity(
        opacity: 0.5,
        child: IgnorePointer(
          child: child,
        ),
      );
    }

    return fallback ?? const SizedBox.shrink();
  }
}

/// Widget that shows different content based on whether user is admin
class AdminOnlyWidget extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const AdminOnlyWidget({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    if (authService.isAdmin) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

/// Extension on BuildContext for easy access control checks
extension AccessControlExtension on BuildContext {
  bool hasFeature(String featureKey) {
    return AuthService().hasFeature(featureKey);
  }

  bool get isAdmin => AuthService().isAdmin;

  List<String> get availableFeatures => AuthService().getAvailableFeatures();
}

/// A navigation item that's only shown if user has access
class AccessControlledNavItem {
  final String featureKey;
  final String route;
  final IconData icon;
  final String label;
  final String? subtitle;

  const AccessControlledNavItem({
    required this.featureKey,
    required this.route,
    required this.icon,
    required this.label,
    this.subtitle,
  });

  bool get isAccessible => AuthService().hasFeature(featureKey);
}

/// Helper class to filter navigation items based on user permissions
class AccessControlHelper {
  static final _authService = AuthService();

  /// Filter a list of navigation items to only include accessible ones
  static List<T> filterAccessible<T extends AccessControlledNavItem>(List<T> items) {
    return items.where((item) => item.isAccessible).toList();
  }

  /// Check if user can access a specific feature
  static bool canAccess(String featureKey) {
    return _authService.hasFeature(featureKey);
  }

  /// Check if user is admin
  static bool get isAdmin => _authService.isAdmin;

  /// Get all features the current user has access to
  static List<String> get availableFeatures => _authService.getAvailableFeatures();
}
