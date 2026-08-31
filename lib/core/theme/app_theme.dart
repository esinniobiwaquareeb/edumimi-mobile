import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';

class AppTheme {
  static ThemeData get light {
    final baseTextTheme = GoogleFonts.publicSansTextTheme();
    final textTheme = baseTextTheme.copyWith(
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.4,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: AppColors.textPrimary,
        height: 1.5,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        color: AppColors.textDisabled,
        height: 1.4,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      error: AppColors.error,
      onError: Colors.white,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackground: AppColors.background,
      dividerColor: AppColors.border,
      surfaceColor: AppColors.surface,
      neutralSoft: AppColors.neutralSoft,
      primarySoft: AppColors.primarySoft,
      borderColor: AppColors.border,
      textSecondary: AppColors.textSecondary,
      textDisabled: AppColors.textDisabled,
    );
  }

  static ThemeData get dark {
    final baseTextTheme = GoogleFonts.publicSansTextTheme(
      ThemeData.dark().textTheme,
    );
    final textTheme = baseTextTheme.copyWith(
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.darkTextPrimary,
        letterSpacing: -0.4,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.darkTextPrimary,
        letterSpacing: -0.2,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.darkTextPrimary,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.darkTextPrimary,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: AppColors.darkTextPrimary,
        height: 1.5,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        color: AppColors.darkTextSecondary,
        height: 1.4,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );

    const darkOnPrimary = Color(0xFFF5F5F5);

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: darkOnPrimary,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkTextPrimary,
          onSurfaceVariant: AppColors.darkTextSecondary,
          outline: AppColors.darkBorder,
          error: AppColors.error,
          onError: Colors.white,
          surfaceContainerHighest: AppColors.darkSurfaceElevated,
        );

    return _buildTheme(
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackground: AppColors.darkBackground,
      dividerColor: AppColors.darkBorder,
      surfaceColor: AppColors.darkSurface,
      neutralSoft: AppColors.darkNeutralSoft,
      primarySoft: AppColors.darkPrimarySoft,
      borderColor: AppColors.darkBorder,
      textSecondary: AppColors.darkTextSecondary,
      textDisabled: AppColors.darkTextDisabled,
      isDark: true,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required Color scaffoldBackground,
    required Color dividerColor,
    required Color surfaceColor,
    required Color neutralSoft,
    required Color primarySoft,
    required Color borderColor,
    required Color textSecondary,
    required Color textDisabled,
    bool isDark = false,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      fontFamily: GoogleFonts.publicSans().fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: scaffoldBackground,
      dividerColor: dividerColor,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium,
        surfaceTintColor: Colors.transparent,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: borderColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        labelStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
        hintStyle: textTheme.bodyMedium?.copyWith(color: textDisabled),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: neutralSoft,
          disabledForegroundColor: textDisabled,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: primarySoft,
        surfaceTintColor: Colors.transparent,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : textSecondary,
            size: 22,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: neutralSoft,
        selectedColor: primarySoft,
        disabledColor: neutralSoft,
        labelStyle: textTheme.labelSmall!.copyWith(color: textSecondary),
        secondaryLabelStyle: textTheme.labelSmall!.copyWith(
          color: AppColors.primary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: borderColor),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? AppColors.darkNeutralSoft
            : AppColors.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        constraints: const BoxConstraints(maxWidth: 720),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: textSecondary,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          color: AppColors.primary,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : textSecondary,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? (isDark ? AppColors.darkTextPrimary : Colors.white)
              : textDisabled,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : neutralSoft,
        ),
      ),
    );
  }
}
