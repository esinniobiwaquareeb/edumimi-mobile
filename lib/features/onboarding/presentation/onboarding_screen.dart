import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/constants/mock_voice.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/auth/providers/auth_providers.dart';
import 'package:mock_mobile/features/onboarding/presentation/widgets/onboarding_widgets.dart';
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
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = MockVoice.onboardingPages;
    final isLastPage = _pageIndex >= pages.length - 1;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          OnboardingAmbientBackground(pageIndex: _pageIndex),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.item, AppSpacing.page, 0),
                  child: Row(
                    children: [
                      const MockBrandLogo(compact: true),
                      const Spacer(),
                      TextButton(
                        onPressed: _finish,
                        child: Text('Skip', style: context.bodySecondary),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: pages.length,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) => setState(() => _pageIndex = index),
                    itemBuilder: (context, index) {
                      return OnboardingPageSlide(
                        page: pages[index],
                        pageIndex: index,
                        pageController: _pageController,
                      );
                    },
                  ),
                ),
                OnboardingProgressDots(
                  count: pages.length,
                  activeIndex: _pageIndex,
                  pageController: _pageController,
                ),
                const SizedBox(height: AppSpacing.page),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    0,
                    AppSpacing.page,
                    AppSpacing.page,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: MockPrimaryButton(
                      key: ValueKey<bool>(isLastPage),
                      label: isLastPage ? 'Get started' : 'Continue',
                      onPressed: _next,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
