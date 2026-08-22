import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mock_mobile/core/constants/mock_voice.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/theme/theme_context.dart';

class OnboardingAmbientBackground extends StatefulWidget {
  const OnboardingAmbientBackground({super.key, required this.pageIndex});

  final int pageIndex;

  @override
  State<OnboardingAmbientBackground> createState() => _OnboardingAmbientBackgroundState();
}

class _OnboardingAmbientBackgroundState extends State<OnboardingAmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentForPage(widget.pageIndex);
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = 0.5 + (_pulseController.value * 0.5);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.colors.surface,
                accent.withValues(alpha: context.isDarkMode ? 0.18 * pulse : 0.12 * pulse),
                context.isDarkMode ? AppColors.darkBackground : AppColors.background,
              ],
            ),
          ),
          child: child,
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: _GlowOrb(
              color: accent.withValues(alpha: context.isDarkMode ? 0.16 : 0.1),
              size: 220,
            ),
          ),
          Positioned(
            bottom: 120,
            left: -60,
            child: _GlowOrb(
              color: AppColors.primary.withValues(alpha: context.isDarkMode ? 0.12 : 0.08),
              size: 180,
            ),
          ),
        ],
      ),
    );
  }

  Color _accentForPage(int index) {
    return switch (index % 4) {
      0 => AppColors.primarySoft,
      1 => const Color(0xFFE0F2FE),
      2 => const Color(0xFFEDE9FE),
      _ => const Color(0xFFFFF7ED),
    };
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

class OnboardingPageSlide extends StatelessWidget {
  const OnboardingPageSlide({
    super.key,
    required this.page,
    required this.pageIndex,
    required this.pageController,
  });

  final MockOnboardingPage page;
  final int pageIndex;
  final PageController pageController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pageController,
      builder: (context, child) {
        final currentPage = pageController.hasClients ? pageController.page ?? pageIndex.toDouble() : pageIndex.toDouble();
        final delta = (currentPage - pageIndex).abs().clamp(0.0, 1.0);
        final opacity = Curves.easeOut.transform(1 - delta);
        final slideX = (pageIndex - currentPage) * 36;
        final scale = 0.92 + (opacity * 0.08);

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(slideX, 12 * delta),
            transformHitTests: false,
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
      child: _OnboardingPageContent(page: page, pageIndex: pageIndex),
    );
  }
}

class _OnboardingPageContent extends StatefulWidget {
  const _OnboardingPageContent({required this.page, required this.pageIndex});

  final MockOnboardingPage page;
  final int pageIndex;

  @override
  State<_OnboardingPageContent> createState() => _OnboardingPageContentState();
}

class _OnboardingPageContentState extends State<_OnboardingPageContent> with SingleTickerProviderStateMixin {
  late final AnimationController _iconController;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconFloat;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _iconScale = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );
    _iconFloat = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _iconController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _iconFloat.value),
                child: Transform.scale(
                  scale: _iconScale.value,
                  child: child,
                ),
              );
            },
            child: _OnboardingIconBadge(icon: _iconFor(widget.page.iconName), pageIndex: widget.pageIndex),
          ),
          const SizedBox(height: AppSpacing.page + 4),
          Text(
            widget.page.title,
            textAlign: TextAlign.center,
            style: context.pageTitle.copyWith(fontSize: 28, letterSpacing: -0.6, height: 1.15),
          ),
          const SizedBox(height: AppSpacing.section),
          Text(
            widget.page.body,
            textAlign: TextAlign.center,
            style: context.pageSubtitle.copyWith(height: 1.55),
          ),
        ],
      ),
    );
  }
}

class _OnboardingIconBadge extends StatelessWidget {
  const _OnboardingIconBadge({required this.icon, required this.pageIndex});

  final IconData icon;
  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    final ringColor = AppColors.primary.withValues(alpha: context.isDarkMode ? 0.35 : 0.18);
    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: pageIndex * 0.18,
            child: Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ringColor, width: 1.5),
              ),
            ),
          ),
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: context.appBorder.withValues(alpha: 0.85)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: context.isDarkMode ? 0.18 : 0.08),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(icon, size: 38, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class OnboardingProgressDots extends StatelessWidget {
  const OnboardingProgressDots({
    super.key,
    required this.count,
    required this.activeIndex,
    required this.pageController,
  });

  final int count;
  final int activeIndex;
  final PageController pageController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pageController,
      builder: (context, _) {
        final page = pageController.hasClients ? pageController.page ?? activeIndex.toDouble() : activeIndex.toDouble();
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(count, (index) {
            final distance = (page - index).abs();
            final width = 8.0 + (math.max(0, 1 - distance) * 18);
            final opacity = 0.35 + (math.max(0, 1 - distance) * 0.65);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: width,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: opacity),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        );
      },
    );
  }
}

class OnboardingStepProgress extends StatelessWidget {
  const OnboardingStepProgress({super.key, required this.step, required this.totalSteps});

  final int step;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final progress = step / totalSteps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Step $step of $totalSteps', style: context.label.copyWith(color: AppColors.primary)),
            const Spacer(),
            Text('${(progress * 100).round()}%', style: context.caption),
          ],
        ),
        const SizedBox(height: AppSpacing.item),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(color: context.appBorder.withValues(alpha: 0.55)),
                ),
                AnimatedAlign(
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerLeft,
                  widthFactor: progress.clamp(0.05, 1),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.85),
                          AppColors.primary,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class OnboardingStepTransition extends StatelessWidget {
  const OnboardingStepTransition({super.key, required this.step, required this.child});

  final int step;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0.05, 0.02),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(step),
        child: child,
      ),
    );
  }
}

class OnboardingFadeInList extends StatelessWidget {
  const OnboardingFadeInList({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + (index * 70).clamp(0, 280)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 16),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

IconData _iconFor(String iconName) {
  return switch (iconName) {
    'menu_book_outlined' => LucideIcons.bookOpen,
    'wifi_off_outlined' => LucideIcons.wifiOff,
    'bar_chart_outlined' => LucideIcons.barChart3,
    'emoji_events_outlined' => LucideIcons.trophy,
    _ => LucideIcons.sparkles,
  };
}
