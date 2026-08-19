import 'package:flutter/material.dart';
import 'package:mock_mobile/core/constants/mock_voice.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/theme/theme_context.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: context.appBorder),
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.onSurface.withValues(alpha: context.isDarkMode ? 0.18 : 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/branding/logo-icon.png',
                    width: 72,
                    height: 72,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: AppSpacing.page),
                const MockBrandLockup(),
                const SizedBox(height: AppSpacing.section),
                Text(
                  MockVoice.brandTagline,
                  textAlign: TextAlign.center,
                  style: context.pageSubtitle,
                ),
                const SizedBox(height: AppSpacing.page),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
