import 'package:flutter/material.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';

/// Theme-aware semantic colors for widgets that need more than [ColorScheme] alone.
extension AppThemeContext on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  ColorScheme get colors => Theme.of(this).colorScheme;

  Color get appNeutralSoft => isDarkMode ? AppColors.darkNeutralSoft : AppColors.neutralSoft;

  Color get appPrimarySoft => isDarkMode ? AppColors.darkPrimarySoft : AppColors.primarySoft;

  Color get appBorder => isDarkMode ? AppColors.darkBorder : AppColors.border;

  Color get appTextSecondary => isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;

  Color get appTextDisabled => isDarkMode ? AppColors.darkTextDisabled : AppColors.textDisabled;

  Color get appSuccessSoft => isDarkMode ? AppColors.darkSuccessSoft : AppColors.successSoft;

  Color get appErrorSoft => isDarkMode ? AppColors.darkErrorSoft : AppColors.errorSoft;

  Color get appWarningSoft => isDarkMode ? AppColors.darkWarningSoft : AppColors.warningSoft;

  /// Subtle header wash — low contrast in dark mode for extended reading comfort.
  Color get appHeaderGradientEnd => isDarkMode
      ? AppColors.darkPrimarySoft.withValues(alpha: 0.22)
      : AppColors.primarySoft.withValues(alpha: 0.35);

  /// Dark glass nav: translucent charcoal, not frosted white.
  Color get appNavGlassTop =>
      isDarkMode ? AppColors.darkBackground.withValues(alpha: 0.78) : colors.surface.withValues(alpha: 0.58);

  Color get appNavGlassBottom =>
      isDarkMode ? AppColors.darkSurface.withValues(alpha: 0.92) : colors.surface.withValues(alpha: 0.82);
}
