import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
import 'package:mock_mobile/core/utils/text_utils.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/mock/data/mock_portal_repository.dart';

class ExamsScreen extends ConsumerStatefulWidget {
  const ExamsScreen({super.key});

  @override
  ConsumerState<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends ConsumerState<ExamsScreen> {
  String? _selectedExamTypeSlug;

  @override
  Widget build(BuildContext context) {
    final examTypesAsync = ref.watch(examTypesProvider);
    final examsAsync = ref.watch(examsCatalogProvider(_selectedExamTypeSlug));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Practice', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('Browse mocks and drills by exam type.', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              examTypesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (types) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedExamTypeSlug == null,
                      onSelected: (_) => setState(() => _selectedExamTypeSlug = null),
                    ),
                    ...types.map(
                      (type) => ChoiceChip(
                        label: Text(type.title),
                        selected: _selectedExamTypeSlug == type.slug,
                        onSelected: (_) => setState(() => _selectedExamTypeSlug = type.slug),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: examsAsync.when(
            loading: () => const MockLoadingView(message: 'Loading exams…'),
            error: (error, _) => MockErrorView(message: error.toString(), onRetry: () => ref.invalidate(examsCatalogProvider(_selectedExamTypeSlug))),
            data: (exams) {
              if (exams.isEmpty) {
                return const MockEmptyState(title: 'No exams found', message: 'Try another exam type filter.');
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(examsCatalogProvider(_selectedExamTypeSlug)),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: exams.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final exam = exams[index];
                    final subtitle = [exam.examTypeLabel, exam.subjectLabel].where((part) => part.isNotEmpty).join(' · ');
                    return MockExamCard(
                      title: exam.title,
                      subtitle: subtitle,
                      meta: '${formatMockMode(exam.mode)} · ${exam.totalQuestions} questions',
                      locked: exam.isLocked,
                      onTap: () => context.push('/exams/${exam.slug}'),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
