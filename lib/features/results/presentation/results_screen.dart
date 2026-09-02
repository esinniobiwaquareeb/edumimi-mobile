import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/theme/app_icons.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/core/widgets/mock_adaptive_layout.dart';
import 'package:mock_mobile/features/mock/data/mock_portal_repository.dart';
import 'package:mock_mobile/shared/models/mock_attempt.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attemptsAsync = ref.watch(attemptsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.page,
            AppSpacing.page,
            0,
          ),
          child: MockPageHeader(
            title: 'My Scores',
            subtitle: 'Your progress and submitted attempts.',
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        Expanded(
          child: attemptsAsync.when(
            loading: () => const MockLoadingView(message: 'Loading results…'),
            error: (error, _) => MockErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(attemptsProvider),
            ),
            data: (attempts) {
              if (attempts.isEmpty) {
                return const MockEmptyState(
                  title: 'No attempts yet',
                  message:
                      'Your scores will show up here after your first practice.',
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(attemptsProvider),
                child: MockAdaptiveLayout.isWide(context)
                    ? GridView.builder(
                        padding: MockTabScrollPadding.list(context),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 500,
                              mainAxisExtent: 220,
                              crossAxisSpacing: AppSpacing.section,
                              mainAxisSpacing: AppSpacing.section,
                            ),
                        itemCount: attempts.length,
                        itemBuilder: (context, index) =>
                            _AttemptCard(attempt: attempts[index]),
                      )
                    : ListView.separated(
                        padding: MockTabScrollPadding.list(context),
                        itemCount: attempts.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.section),
                        itemBuilder: (context, index) => MockContentWidth(
                          child: _AttemptCard(attempt: attempts[index]),
                        ),
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AttemptCard extends StatelessWidget {
  const _AttemptCard({required this.attempt});

  final MockAttempt attempt;

  @override
  Widget build(BuildContext context) {
    return MockCard(
      elevated: attempt.isSubmitted,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: attempt.isSubmitted
            ? () => context.push('/results/${attempt.id}')
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (attempt.isSubmitted)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.section),
                child: MockScoreRing(percent: attempt.percentScore),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attempt.exam?.title ?? 'Mock exam',
                    style: context.cardTitle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    attempt.exam?.examType?.title ?? 'General',
                    style: context.caption,
                  ),
                  const SizedBox(height: AppSpacing.section),
                  MockMetaRow(
                    label: 'Status',
                    value: attempt.status.replaceAll('_', ' '),
                  ),
                  MockMetaRow(
                    label: 'Score',
                    value: '${attempt.score}/${attempt.totalPossibleScore}',
                  ),
                  if (attempt.isSubmitted)
                    MockMetaRow(
                      label: 'Percent',
                      value: '${attempt.percentScore}%',
                    ),
                ],
              ),
            ),
            if (attempt.isSubmitted)
              MockLongArrowIcon(
                direction: MockLongArrowDirection.right,
                size: AppIcons.forwardSize,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.35),
              ),
          ],
        ),
      ),
    );
  }
}
