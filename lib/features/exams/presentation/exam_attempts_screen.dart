import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/exams/exam_attempt_utils.dart';
import 'package:mock_mobile/features/exams/presentation/widgets/exam_attempt_history_card.dart';
import 'package:mock_mobile/features/mock/data/mock_portal_repository.dart';

class ExamAttemptsScreen extends ConsumerWidget {
  const ExamAttemptsScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examAsync = ref.watch(examDetailProvider(slug));
    final attemptsAsync = ref.watch(attemptsProvider);

    return Scaffold(
      appBar: const MockDetailAppBar(title: 'Past attempts'),
      body: examAsync.when(
        loading: () => const MockLoadingView(message: 'Loading attempts…'),
        error: (error, _) => MockErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(examDetailProvider(slug)),
        ),
        data: (exam) {
          return attemptsAsync.when(
            loading: () => const MockLoadingView(message: 'Loading attempts…'),
            error: (error, _) => MockErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(attemptsProvider),
            ),
            data: (attempts) {
              final pastAttempts = filterSubmittedAttemptsForExam(attempts, exam);

              if (pastAttempts.isEmpty) {
                return MockEmptyState(
                  title: 'No attempts yet',
                  message: 'Your submitted scores for ${exam.title} will appear here.',
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(attemptsProvider);
                  ref.invalidate(examDetailProvider(slug));
                },
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.page),
                  children: [
                    Text(exam.title, style: context.pageTitle),
                    const SizedBox(height: 4),
                    Text(
                      '${pastAttempts.length} submitted attempt${pastAttempts.length == 1 ? '' : 's'}',
                      style: context.bodySecondary,
                    ),
                    const SizedBox(height: AppSpacing.page),
                    ...pastAttempts.map(
                      (attempt) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.section),
                        child: ExamAttemptHistoryCard(attempt: attempt),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
