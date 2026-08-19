import 'package:flutter/material.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';

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

class MockTextField extends StatelessWidget {
  const MockTextField({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class MockCard extends StatelessWidget {
  const MockCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: padding, child: child),
    );
  }
}

class MockChip extends StatelessWidget {
  const MockChip({super.key, required this.label, this.tone = MockChipTone.neutral});

  final String label;
  final MockChipTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      MockChipTone.primary => (AppColors.primarySoft, AppColors.primary),
      MockChipTone.success => (const Color(0xFFD1FAE5), AppColors.success),
      MockChipTone.neutral => (AppColors.background, AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colors.$2,
        ),
      ),
    );
  }
}

enum MockChipTone { primary, success, neutral }

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
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
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
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
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
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
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
        borderRadius: BorderRadius.circular(16),
        onTap: locked ? null : onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
                if (locked) const MockChip(label: 'Locked', tone: MockChipTone.neutral),
              ],
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
            if (reason != null && reason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(reason!, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 10),
            Text(meta, style: const TextStyle(color: AppColors.textDisabled, fontSize: 12)),
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
      spacing: 8,
      runSpacing: 8,
      children: segments.map((segment) {
        final isSelected = segment == selected;
        return ChoiceChip(
          label: Text(labelBuilder(segment)),
          selected: isSelected,
          onSelected: (_) => onChanged(segment),
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        );
      }).toList(),
    );
  }
}

class MockUserAvatar extends StatelessWidget {
  const MockUserAvatar({super.key, required this.initials, this.size = 44});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primarySoft,
      child: Text(
        initials,
        style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w800),
      ),
    );
  }
}
