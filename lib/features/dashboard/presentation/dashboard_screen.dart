import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
import 'package:mock_mobile/core/utils/text_utils.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/core/widgets/offline_status_banner.dart';
import 'package:mock_mobile/features/mock/data/mock_portal_repository.dart';
import 'package:mock_mobile/shared/models/mock_exam.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(examFeedProvider);
    final insightsAsync = ref.watch(studyInsightsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(examFeedProvider);
        ref.invalidate(studyInsightsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Dashboard', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('Pick up where you left off.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          const OfflineStatusBanner(),
          insightsAsync.when(
            loading: () => const MockCard(child: MockLoadingView(message: 'Loading insights…')),
            error: (_, __) => const SizedBox.shrink(),
            data: (insights) => MockCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${insights.streakDays}-day streak', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text('${insights.submittedAttempts} submitted attempts', style: const TextStyle(color: AppColors.textSecondary)),
                  if (insights.weakTopics.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Fix these topics', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: insights.weakTopics.take(3).map((topic) => MockChip(label: topic)).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          feedAsync.when(
            loading: () => const MockLoadingView(message: 'Loading practice…'),
            error: (error, _) => MockErrorView(message: error.toString(), onRetry: () => ref.invalidate(examFeedProvider)),
            data: (feed) {
              final exams = feed.recommended.isNotEmpty ? feed.recommended : feed.all.take(5).toList();
              if (exams.isEmpty) {
                return MockEmptyState(
                  title: 'No practice ready yet',
                  message: 'Browse exams and start your first drill.',
                  actionLabel: 'Browse practice',
                  onAction: () => context.go('/exams'),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recommended for you', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 12),
                  ...exams.map((exam) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ExamListTile(exam: exam),
                      )),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ExamListTile extends StatelessWidget {
  const _ExamListTile({required this.exam});

  final MockExam exam;

  @override
  Widget build(BuildContext context) {
    final subtitle = [exam.examTypeLabel, exam.subjectLabel].where((part) => part.isNotEmpty).join(' · ');
    return MockExamCard(
      title: exam.title,
      subtitle: subtitle,
      meta: '${formatMockMode(exam.mode)} · ${exam.totalQuestions} questions · ${exam.durationMinutes} min',
      reason: exam.recommendationReason,
      locked: exam.isLocked,
      onTap: () => context.push('/exams/${exam.slug}'),
    );
  }
}
