import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mock_mobile/core/constants/mock_voice.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
import 'package:mock_mobile/core/theme/app_icons.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/theme/theme_context.dart';
import 'package:mock_mobile/shared/models/mock_attempt.dart';

class MockPrimaryButton extends StatelessWidget {
  const MockPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(label),
    );
  }
}

class MockSecondaryButton extends StatelessWidget {
  const MockSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}

class MockTextField extends StatefulWidget {
  const MockTextField({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.obscurable = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final bool obscurable;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;

  @override
  State<MockTextField> createState() => _MockTextFieldState();
}

class _MockTextFieldState extends State<MockTextField> {
  late bool _obscured;

  bool get _hasVisibilityToggle => widget.obscurable || widget.obscureText;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscurable || widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _hasVisibilityToggle ? _obscured : widget.obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: _hasVisibilityToggle
            ? IconButton(
                icon: Icon(
                  _obscured ? AppIcons.eyeOff : AppIcons.eye,
                  size: 20,
                  color: context.appTextSecondary,
                ),
                tooltip: _obscured ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : null,
      ),
    );
  }
}

class MockCard extends StatelessWidget {
  const MockCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.page),
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    if (!elevated) {
      return Card(child: Padding(padding: padding, child: child));
    }

    final colors = context.colors;
    final surfaceColor = context.isDarkMode && elevated ? AppColors.darkSurfaceElevated : colors.surface;
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: colors.onSurface.withValues(alpha: context.isDarkMode ? 0.1 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

enum MockChipTone { primary, neutral, success }

class MockChip extends StatelessWidget {
  const MockChip({super.key, required this.label, this.tone = MockChipTone.neutral});

  final String label;
  final MockChipTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, border) = switch (tone) {
      MockChipTone.primary => (context.appPrimarySoft, AppColors.primary, context.appBorder),
      MockChipTone.success => (context.appSuccessSoft, AppColors.success, context.appBorder),
      MockChipTone.neutral => (context.appNeutralSoft, context.appTextSecondary, context.appBorder),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: context.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}

class MockPageHeader extends StatelessWidget {
  const MockPageHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.pageTitle),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.item),
          Text(subtitle!, style: context.pageSubtitle),
        ],
      ],
    );
  }
}

class MockSectionTitle extends StatelessWidget {
  const MockSectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: context.sectionTitle);
  }
}

enum MockNoticeTone { error, info, success }

class MockInlineNotice extends StatelessWidget {
  const MockInlineNotice.error({super.key, required this.message}) : tone = MockNoticeTone.error;

  const MockInlineNotice.info({super.key, required this.message}) : tone = MockNoticeTone.info;

  const MockInlineNotice.success({super.key, required this.message}) : tone = MockNoticeTone.success;

  final String message;
  final MockNoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      MockNoticeTone.error => (context.appErrorSoft, AppColors.error),
      MockNoticeTone.info => (context.appNeutralSoft, context.appTextSecondary),
      MockNoticeTone.success => (context.appSuccessSoft, AppColors.success),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.section),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.appBorder),
      ),
      child: Text(message, style: context.body.copyWith(color: colors.$2)),
    );
  }
}
class MockMetaRow extends StatelessWidget {
  const MockMetaRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.item),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label.toUpperCase(), style: context.label),
          Text(
            value,
            style: emphasis ? context.cardTitle : context.body,
          ),
        ],
      ),
    );
  }
}

class MockEmptyState extends StatelessWidget {
  const MockEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, textAlign: TextAlign.center, style: context.sectionTitle),
            const SizedBox(height: AppSpacing.item),
            Text(message, textAlign: TextAlign.center, style: context.bodySecondary),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.page),
              MockPrimaryButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

class MockLoadingView extends StatelessWidget {
  const MockLoadingView({super.key, this.message = 'Loading…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.section),
          Text(message, style: context.bodySecondary),
        ],
      ),
    );
  }
}

class MockErrorView extends StatelessWidget {
  const MockErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center, style: context.bodySecondary),
            const SizedBox(height: AppSpacing.page),
            MockSecondaryButton(label: 'Try again', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class MockExamCard extends StatelessWidget {
  const MockExamCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.meta,
    this.reason,
    required this.onTap,
    this.locked = false,
  });

  final String title;
  final String subtitle;
  final String meta;
  final String? reason;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MockCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: locked ? null : onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(title, style: context.cardTitle)),
                if (locked)
                  const MockChip(label: 'Locked', tone: MockChipTone.neutral)
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: context.appTextDisabled,
                  ),
              ],
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(subtitle, style: context.bodySecondary.copyWith(fontSize: 13)),
            ],
            if (reason != null && reason!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.item),
              Text(reason!, style: context.caption.copyWith(color: context.appTextSecondary)),
            ],
            const SizedBox(height: AppSpacing.section),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: context.appNeutralSoft,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(meta, style: context.caption.copyWith(fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}

class MockSegmentedControl<T extends Object> extends StatelessWidget {
  const MockSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    required this.labelBuilder,
  });

  final List<T> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T value) labelBuilder;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.item,
      runSpacing: AppSpacing.item,
      children: segments.map((segment) {
        final isSelected = segment == selected;
        return FilterChip(
          label: Text(labelBuilder(segment)),
          selected: isSelected,
          showCheckmark: false,
          onSelected: (_) => onChanged(segment),
          backgroundColor: context.colors.surface,
          selectedColor: context.appPrimarySoft,
          side: BorderSide(color: isSelected ? AppColors.primary : context.appBorder),
          labelStyle: context.caption.copyWith(
            color: isSelected ? AppColors.primary : context.appTextSecondary,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }
}

class MockUserAvatar extends StatelessWidget {
  const MockUserAvatar({
    super.key,
    required this.initials,
    this.imageUrl,
    this.size = 44,
  });

  final String initials;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = imageUrl?.trim();
    if (trimmedUrl != null && trimmedUrl.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Image.network(
            trimmedUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _MockInitialsAvatar(initials: initials, size: size),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }
              return _MockInitialsAvatar(initials: initials, size: size);
            },
          ),
        ),
      );
    }

    return _MockInitialsAvatar(initials: initials, size: size);
  }
}

class _MockInitialsAvatar extends StatelessWidget {
  const _MockInitialsAvatar({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: context.appNeutralSoft,
      child: Text(
        initials,
        style: context.caption.copyWith(
          color: context.colors.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.28,
        ),
      ),
    );
  }
}

String mockTimeBasedGreeting([DateTime? at]) {
  final hour = (at ?? DateTime.now()).hour;
  if (hour < 12) {
    return 'Good morning';
  }
  if (hour < 17) {
    return 'Good afternoon';
  }
  return 'Good evening';
}

class MockBrandLockup extends StatelessWidget {
  const MockBrandLockup({super.key, this.compact = false, this.withLogo = false});

  final bool compact;
  final bool withLogo;

  @override
  Widget build(BuildContext context) {
    final lockup = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            style: context.pageTitle.copyWith(
              fontSize: compact ? 16 : 18,
              letterSpacing: -0.3,
            ),
            children: const [
              TextSpan(text: 'mock'),
              TextSpan(text: '.edumimi', style: TextStyle(color: AppColors.primary)),
            ],
          ),
        ),
        if (!compact)
          Text(
            'Part of Edumimi',
            style: context.caption.copyWith(letterSpacing: 1.1, fontSize: 11),
          ),
      ],
    );

    if (!withLogo) {
      return lockup;
    }

    return Row(
      children: [
        Container(
          width: compact ? 34 : 40,
          height: compact ? 34 : 40,
          decoration: BoxDecoration(
            color: context.appNeutralSoft,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: context.appBorder),
          ),
          padding: const EdgeInsets.all(6),
          child: Image.asset(
            'assets/branding/logo-icon.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: lockup),
      ],
    );
  }
}

class MockScreenBody extends StatelessWidget {
  const MockScreenBody({super.key, required this.child, this.padding = const EdgeInsets.all(AppSpacing.page)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: padding, child: child);
  }
}

class MockAppHeader extends StatelessWidget implements PreferredSizeWidget {
  const MockAppHeader({
    super.key,
    this.userName,
    this.userInitials,
    this.avatarUrl,
    this.onProfileTap,
    this.streakDays,
    this.streakAtRisk = false,
    this.isVerified = false,
    this.onCommunityTap,
    this.onNotificationsTap,
    this.showNotificationBadge = false,
  });

  final String? userName;
  final String? userInitials;
  final String? avatarUrl;
  final VoidCallback? onProfileTap;
  final int? streakDays;
  final bool streakAtRisk;
  final bool isVerified;
  final VoidCallback? onCommunityTap;
  final VoidCallback? onNotificationsTap;
  final bool showNotificationBadge;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final trimmedName = userName?.trim();
    final showProfile = trimmedName != null && trimmedName.isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(bottom: BorderSide(color: context.appBorder, width: 0.5)),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            context.colors.surface,
            context.appHeaderGradientEnd,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.item),
            child: Row(
              children: [
                if (showProfile)
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onProfileTap,
                        child: Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.page),
                          child: Row(
                            children: [
                              MockUserAvatar(
                                initials: userInitials ?? 'U',
                                imageUrl: avatarUrl,
                                size: 40,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      mockTimeBasedGreeting(),
                                      style: context.caption.copyWith(
                                        color: context.appTextSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            trimmedName,
                                            style: context.body.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: context.colors.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isVerified) ...[
                                          const SizedBox(width: 6),
                                          const MockChip(label: 'Verified', tone: MockChipTone.success),
                                        ],
                                        if (streakDays != null && streakDays! > 0) ...[
                                          const SizedBox(width: 6),
                                          _MockHeaderStreakBadge(
                                            streakDays: streakDays!,
                                            streakAtRisk: streakAtRisk,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const Spacer(),
                if (onCommunityTap != null)
                  _MockHeaderIconButton(
                    icon: AppIcons.community,
                    tooltip: 'Study Squad chat',
                    onTap: onCommunityTap!,
                  ),
                if (onNotificationsTap != null)
                  _MockHeaderIconButton(
                    icon: AppIcons.notifications,
                    tooltip: 'Notifications',
                    onTap: onNotificationsTap!,
                    showBadge: showNotificationBadge,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MockHeaderIconButton extends StatelessWidget {
  const _MockHeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.showBadge = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Material(
        color: context.appNeutralSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: context.appBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Tooltip(
          message: tooltip,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 38,
              height: 38,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, size: 20, color: context.appTextSecondary),
                  if (showBadge)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: streakAtRiskColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.colors.surface, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const streakAtRiskColor = Color(0xFFD97706);
}

class _MockHeaderStreakBadge extends StatelessWidget {
  const _MockHeaderStreakBadge({
    required this.streakDays,
    this.streakAtRisk = false,
  });

  final int streakDays;
  final bool streakAtRisk;

  @override
  Widget build(BuildContext context) {
    final warningBg = context.isDarkMode ? AppColors.darkWarningSoft : const Color(0xFFFFFBEB);
    final warningBorder = context.isDarkMode ? const Color(0xFF6B4423) : const Color(0xFFFDE68A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: streakAtRisk ? warningBg : context.appPrimarySoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: streakAtRisk ? warningBorder : context.appBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            AppIcons.streak,
            size: 12,
            color: streakAtRisk ? const Color(0xFFD97706) : AppColors.primary,
          ),
          const SizedBox(width: 3),
          Text(
            '$streakDays',
            style: context.caption.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: streakAtRisk ? const Color(0xFFB45309) : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class MockNavDestination {
  const MockNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class MockGlassNavBar extends StatelessWidget {
  const MockGlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<MockNavDestination> destinations;

  bool get _useGlassEffect => Platform.isIOS;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final barContent = Padding(
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottomInset > 0 ? 4 : 8),
      child: Row(
        children: List.generate(destinations.length, (index) {
          final destination = destinations[index];
          final isSelected = index == selectedIndex;
          return Expanded(
            child: _MockNavItem(
              destination: destination,
              isSelected: isSelected,
              onTap: () => onDestinationSelected(index),
            ),
          );
        }),
      ),
    );

    if (_useGlassEffect) {
      final blurSigma = context.isDarkMode ? 20.0 : 32.0;
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.appNavGlassTop,
                  context.appNavGlassBottom,
                ],
              ),
              border: Border(
                top: BorderSide(
                  color: context.appBorder.withValues(alpha: context.isDarkMode ? 0.35 : 0.45),
                ),
              ),
            ),
            child: barContent,
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.isDarkMode ? AppColors.darkSurface : context.colors.surface,
        border: Border(top: BorderSide(color: context.appBorder.withValues(alpha: 0.8))),
        boxShadow: [
          BoxShadow(
            color: context.colors.onSurface.withValues(alpha: context.isDarkMode ? 0.12 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: barContent,
    );
  }
}

class _MockNavItem extends StatelessWidget {
  const _MockNavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final MockNavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? context.appPrimarySoft.withValues(alpha: context.isDarkMode ? 0.65 : 0.9)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? destination.selectedIcon : destination.icon,
                size: 22,
                color: isSelected ? AppColors.primary : context.appTextSecondary,
              ),
              const SizedBox(height: 2),
              Text(
                destination.label,
                style: context.caption.copyWith(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : context.appTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MockStatTile extends StatelessWidget {
  const MockStatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData? icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.section),
        decoration: BoxDecoration(
          color: context.appNeutralSoft,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: context.appBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: context.appTextSecondary),
                  const SizedBox(width: 6),
                ],
                Expanded(child: Text(label.toUpperCase(), style: context.label)),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: context.sectionTitle.copyWith(letterSpacing: -0.2)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: context.caption),
            ],
          ],
        ),
      ),
    );
  }
}

class MockWeakTopicChip extends StatelessWidget {
  const MockWeakTopicChip({super.key, required this.topic});

  final MockWeakTopic topic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.appNeutralSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(topic.displayLabel, style: context.caption.copyWith(fontWeight: FontWeight.w600, color: context.colors.onSurface)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 1,
            height: 12,
            color: context.appBorder,
          ),
          Text('${topic.percent}%', style: context.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
        ],
      ),
    );
  }
}

class MockPodiumCard extends StatelessWidget {
  const MockPodiumCard({super.key, required this.rank, required this.name, required this.score, this.subtitle});

  final int rank;
  final String name;
  final String score;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return MockCard(
      elevated: rank <= 3,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank == 1 ? context.appPrimarySoft : context.appNeutralSoft,
              shape: BoxShape.circle,
              border: Border.all(color: rank == 1 ? AppColors.primary.withValues(alpha: 0.3) : context.appBorder),
            ),
            child: Text(
              '#$rank',
              style: context.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: rank == 1 ? AppColors.primary : context.appTextSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.section),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: context.cardTitle),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: context.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          Text(score, style: context.sectionTitle.copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }
}

class MockScoreRing extends StatelessWidget {
  const MockScoreRing({super.key, required this.percent, this.size = 52});

  final num percent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final normalized = (percent.clamp(0, 100) / 100).toDouble();
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: normalized,
              strokeWidth: 4,
              backgroundColor: context.appNeutralSoft,
              color: AppColors.primary,
            ),
          ),
          Text(
            '${percent.round()}%',
            style: context.caption.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurface, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// Standard back control using the long-tail Lucide arrow ([AppIcons.back]).
class MockBackButton extends StatelessWidget {
  const MockBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(AppIcons.back),
      tooltip: 'Back',
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
    );
  }
}

class MockDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MockDetailAppBar({super.key, required this.title, this.leading, this.onBack});

  final String title;
  final Widget? leading;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: leading ?? MockBackButton(onPressed: onBack),
      title: Text(title, style: context.cardTitle),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: context.appBorder),
      ),
    );
  }
}

class MockAuthCard extends StatelessWidget {
  const MockAuthCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MockCard(
      elevated: true,
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}

enum MockConfirmDialogVariant { danger, warning, info }

/// Themed confirmation dialog aligned with mock-frontend ConfirmDialog.
class MockConfirmDialog {
  MockConfirmDialog._();

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = MockVoice.cancel,
    MockConfirmDialogVariant variant = MockConfirmDialogVariant.warning,
    bool hideCancel = false,
    IconData? icon,
    bool isDestructiveConfirm = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: !hideCancel,
      builder: (dialogContext) => _MockConfirmDialogContent(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        variant: variant,
        hideCancel: hideCancel,
        icon: icon,
        isDestructiveConfirm: isDestructiveConfirm,
      ),
    );
    return confirmed ?? false;
  }
}

class _MockConfirmDialogContent extends StatelessWidget {
  const _MockConfirmDialogContent({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.variant,
    required this.hideCancel,
    this.icon,
    required this.isDestructiveConfirm,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final MockConfirmDialogVariant variant;
  final bool hideCancel;
  final IconData? icon;
  final bool isDestructiveConfirm;

  @override
  Widget build(BuildContext context) {
    final isDanger = variant == MockConfirmDialogVariant.danger || isDestructiveConfirm;
    final iconBackground = isDanger ? context.appErrorSoft : context.appPrimarySoft;
    final iconColor = isDanger ? AppColors.error : AppColors.primary;
    final dialogIcon = icon ??
        switch (variant) {
          MockConfirmDialogVariant.danger => LucideIcons.alertTriangle,
          MockConfirmDialogVariant.warning => LucideIcons.info,
          MockConfirmDialogVariant.info => LucideIcons.info,
        };

    return AlertDialog(
      backgroundColor: context.colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: context.appBorder),
      ),
      contentPadding: const EdgeInsets.fromLTRB(AppSpacing.page, 20, AppSpacing.page, 0),
      actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.section, AppSpacing.page, AppSpacing.page),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(dialogIcon, size: 20, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.section),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.cardTitle),
                const SizedBox(height: AppSpacing.item),
                Text(message, style: context.bodySecondary),
              ],
            ),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: hideCancel
              ? FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(confirmLabel),
                )
              : Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(cancelLabel),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.section),
                    Expanded(
                      child: isDestructiveConfirm
                          ? FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(confirmLabel),
                            )
                          : FilledButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(confirmLabel),
                            ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
