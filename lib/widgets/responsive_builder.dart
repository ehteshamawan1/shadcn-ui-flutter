import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Responsive builder widget that displays different layouts based on screen size
/// Follows the breakpoints defined in the execution plan
class ResponsiveBuilder extends StatelessWidget {
  /// Widget to display on mobile screens (< 768px)
  final Widget mobile;

  /// Widget to display on tablet screens (>= 768px and < 1024px)
  /// Falls back to mobile if not provided
  final Widget? tablet;

  /// Widget to display on desktop screens (>= 1024px)
  /// Falls back to tablet or mobile if not provided
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop: >= 1024px
        if (constraints.maxWidth >= Breakpoints.lg) {
          return desktop ?? tablet ?? mobile;
        }

        // Tablet: >= 768px and < 1024px
        if (constraints.maxWidth >= Breakpoints.md) {
          return tablet ?? mobile;
        }

        // Mobile: < 768px
        return mobile;
      },
    );
  }
}

/// Helper extension to easily check device type in BuildContext
extension ResponsiveContext on BuildContext {
  bool get isMobile => Breakpoints.isMobile(this);
  bool get isTablet => Breakpoints.isTablet(this);
  bool get isDesktop => Breakpoints.isDesktop(this);
  bool get isExtraLarge => Breakpoints.isExtraLarge(this);

  /// Get the current screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get the current screen height
  double get screenHeight => MediaQuery.of(this).size.height;
}

/// Responsive value builder - returns different values based on screen size
class ResponsiveValue<T> {
  final T mobile;
  final T? tablet;
  final T? desktop;

  const ResponsiveValue({
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  T getValue(BuildContext context) {
    if (context.isDesktop && desktop != null) {
      return desktop!;
    }
    if (context.isTablet && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}

/// Responsive padding helper
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets mobile;
  final EdgeInsets? tablet;
  final EdgeInsets? desktop;

  const ResponsivePadding({
    super.key,
    required this.child,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveValue<EdgeInsets>(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    ).getValue(context);

    return Padding(
      padding: padding,
      child: child,
    );
  }
}

/// Responsive grid helper - automatically adjusts columns based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns,
    this.desktopColumns,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveValue<int>(
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
    ).getValue(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = columns;
        final itemWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return SizedBox(
              width: itemWidth,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

/// Max width container for desktop - prevents content from stretching too wide
class MaxWidthContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets? padding;

  const MaxWidthContainer({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: padding,
        child: child,
      ),
    );
  }
}
