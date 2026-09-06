import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/mock/data/mock_portal_repository.dart';

class GuestResultScreen extends StatelessWidget {
  const GuestResultScreen({super.key, this.result});

  final GuestAttemptResult? result;

  @override
  Widget build(BuildContext context) {
    final result = this.result;
    if (result == null) {
      return Scaffold(
        appBar: const MockDetailAppBar(title: 'Practice complete'),
        body: MockEmptyState(
          title: 'Practice result unavailable',
          message: 'Start another practice session to see your result.',
          actionLabel: 'Browse practice',
          onAction: () => context.go('/try'),
        ),
      );
    }
    return Scaffold(
      appBar: const MockDetailAppBar(title: 'Practice complete'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(result.examTitle, style: context.pageTitle),
                const SizedBox(height: AppSpacing.section),
                MockCard(
                  elevated: true,
                  child: Column(
                    children: [
                      Text(
                        '${result.percentScore.round()}%',
                        style: context.pageTitle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${result.score} of ${result.totalPossibleScore} marks',
                        style: context.bodySecondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.page),
                Text(
                  'Create a free account to save attempts, track progress, and continue practising.',
                  style: context.bodySecondary,
                ),
                const SizedBox(height: AppSpacing.section),
                MockPrimaryButton(
                  label: 'Create free account',
                  onPressed: () => context.go('/signup'),
                ),
                const SizedBox(height: AppSpacing.item),
                MockSecondaryButton(
                  label: 'Browse more practice',
                  onPressed: () => GoRouter.of(context).go('/try'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
