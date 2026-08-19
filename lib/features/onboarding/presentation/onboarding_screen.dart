import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/constants/mock_voice.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/theme/theme_context.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/auth/providers/auth_providers.dart';
import 'package:mock_mobile/features/onboarding/providers/onboarding_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  var _pageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingControllerProvider.notifier).completeOnboarding();
    if (!mounted) {
      return;
    }
    final loggedIn = ref.read(authControllerProvider).isAuthenticated;
    context.go(loggedIn ? '/dashboard' : '/login');
  }

  void _next() {
    final lastPage = MockVoice.onboardingPages.length - 1;
    if (_pageIndex >= lastPage) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  IconData _iconFor(String iconName) {
    return switch (iconName) {
      'menu_book_outlined' => Icons.menu_book_outlined,
      'wifi_off_outlined' => Icons.wifi_off_outlined,
      'bar_chart_outlined' => Icons.bar_chart_outlined,
      'emoji_events_outlined' => Icons.emoji_events_outlined,
      _ => Icons.check_circle_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final pages = MockVoice.onboardingPages;
    final isLastPage = _pageIndex >= pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) => setState(() => _pageIndex = index),
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                            border: Border.all(color: context.appBorder),
                            boxShadow: [
                              BoxShadow(
                                color: context.colors.onSurface.withValues(alpha: context.isDarkMode ? 0.18 : 0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            _iconFor(page.iconName),
                            size: 36,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.page),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: context.pageTitle.copyWith(fontSize: 24, letterSpacing: -0.4),
                        ),
                        const SizedBox(height: AppSpacing.section),
                        Text(
                          page.body,
                          textAlign: TextAlign.center,
                          style: context.pageSubtitle,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _pageIndex == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _pageIndex == index ? AppColors.primary : context.appBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.page),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                0,
                AppSpacing.page,
                AppSpacing.page,
              ),
              child: MockPrimaryButton(
                label: isLastPage ? 'Get started' : 'Next',
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
