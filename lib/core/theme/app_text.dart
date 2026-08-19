import 'package:flutter/material.dart';

extension AppText on BuildContext {
  TextTheme get _text => Theme.of(this).textTheme;
  ColorScheme get _colors => Theme.of(this).colorScheme;

  TextStyle get pageTitle => _text.headlineSmall!.copyWith(
        fontWeight: FontWeight.w700,
        color: _colors.onSurface,
        letterSpacing: -0.2,
      );

  TextStyle get pageSubtitle => _text.bodyMedium!.copyWith(
        color: _colors.onSurfaceVariant,
        height: 1.45,
      );

  TextStyle get sectionTitle => _text.titleMedium!.copyWith(
        fontWeight: FontWeight.w600,
        color: _colors.onSurface,
      );

  TextStyle get cardTitle => _text.titleSmall!.copyWith(
        fontWeight: FontWeight.w600,
        color: _colors.onSurface,
      );

  TextStyle get body => _text.bodyMedium!.copyWith(
        color: _colors.onSurface,
        height: 1.5,
      );

  TextStyle get bodySecondary => _text.bodyMedium!.copyWith(
        color: _colors.onSurfaceVariant,
        height: 1.5,
      );

  TextStyle get caption => _text.bodySmall!.copyWith(
        color: _colors.onSurfaceVariant,
        height: 1.4,
      );

  TextStyle get label => _text.labelSmall!.copyWith(
        color: _colors.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      );
}
