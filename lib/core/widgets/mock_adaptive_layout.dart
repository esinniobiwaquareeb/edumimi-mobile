import 'package:flutter/material.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';

/// Shared responsive measurements for phone, iPad, and desktop-sized windows.
abstract final class MockAdaptiveLayout {
  static const double tabletBreakpoint = 720;
  static const double wideBreakpoint = 1024;
  static const double contentMaxWidth = 1040;
  static const double readingMaxWidth = 820;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wideBreakpoint;

  static double pageInset(BuildContext context) =>
      isTablet(context) ? 32 : AppSpacing.page;

  static double maxContentWidth(BuildContext context) =>
      isWide(context) ? contentMaxWidth : double.infinity;
}

/// Centers application content on larger displays without changing phone layouts.
class MockContentFrame extends StatelessWidget {
  const MockContentFrame({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final resolvedPadding =
        padding ??
        EdgeInsets.symmetric(
          horizontal: MockAdaptiveLayout.pageInset(context),
          vertical: AppSpacing.page,
        );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? MockAdaptiveLayout.maxContentWidth(context),
        ),
        child: Padding(padding: resolvedPadding, child: child),
      ),
    );
  }
}

class MockContentWidth extends StatelessWidget {
  const MockContentWidth({super.key, required this.child, this.maxWidth});

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? MockAdaptiveLayout.maxContentWidth(context),
        ),
        child: child,
      ),
    );
  }
}
