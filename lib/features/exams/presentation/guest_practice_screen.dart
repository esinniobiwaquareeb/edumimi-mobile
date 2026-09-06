import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/mock/data/mock_portal_repository.dart';

class GuestPracticeScreen extends ConsumerWidget {
  const GuestPracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exams = ref.watch(examsCatalogProvider(null));
    return Scaffold(
      appBar: AppBar(title: const Text('Try practice')),
      body: exams.when(
        loading: () => const MockLoadingView(message: 'Loading practice…'),
        error: (error, _) => MockErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(examsCatalogProvider(null)),
        ),
        data: (items) {
          final eligible = items
              .where(
                (exam) =>
                    !exam.isLocked &&
                    (exam.mode == 'PRACTICE' || exam.mode == 'TOPIC_DRILL'),
              )
              .toList();
          if (eligible.isEmpty) {
            return const MockEmptyState(
              title: 'Practice is coming soon',
              message: 'Create an account to see the full catalogue.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.page),
            itemCount: eligible.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.item),
            itemBuilder: (context, index) {
              final exam = eligible[index];
              return MockExamCard(
                title: exam.title,
                subtitle: '${exam.examTypeLabel} · ${exam.subjectLabel}',
                meta: '${exam.totalQuestions} questions',
                onTap: () => context.push('/try/${exam.slug}'),
              );
            },
          );
        },
      ),
    );
  }
}
