import 'package:flutter/material.dart';

/// Utility class for responsive layout breakpoints, font scaling, and helper widgets
class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  /// Breakpoint definitions
  static const double mobileMax = 600;
  static const double tabletMax = 1000;
  static const double maxContentWidth = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileMax;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mobileMax &&
      MediaQuery.sizeOf(context).width < tabletMax;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletMax;

  /// Dynamically computes scaled font size for desktop/windows vs mobile
  static double fontSize(BuildContext context, double mobileSize, {double? desktopSize}) {
    final double width = MediaQuery.sizeOf(context).width;
    if (width >= tabletMax) {
      return desktopSize ?? (mobileSize * 1.22);
    } else if (width >= mobileMax) {
      return desktopSize != null ? (mobileSize + desktopSize) / 2 : (mobileSize * 1.12);
    }
    return mobileSize;
  }

  /// Returns grid cross axis count dynamically based on current width
  static int getGridCrossAxisCount(BuildContext context, {double targetTileWidth = 380}) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobileMax) return 1;
    int count = (width / targetTileWidth).floor();
    return count < 1 ? 1 : count;
  }

  /// Calculates max item width for constrained centered containers
  static double getContentPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width > maxContentWidth) {
      return (width - maxContentWidth) / 2;
    }
    return isMobile(context) ? 12 : 24;
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;

    if (width >= tabletMax) {
      return desktop;
    } else if (width >= mobileMax && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}

/// Helper wrapper to center and constrain content for desktop screens
class ResponsiveCenteredBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveCenteredBody({
    super.key,
    required this.child,
    this.maxWidth = Responsive.maxContentWidth,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
