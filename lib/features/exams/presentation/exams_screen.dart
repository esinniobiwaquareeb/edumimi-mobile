import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
import 'package:mock_mobile/core/theme/theme_context.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
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
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final examTypesAsync = ref.watch(examTypesProvider);
    final examsAsync = ref.watch(examsCatalogProvider(_selectedExamTypeSlug));
    final query = _searchController.text.trim().toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.page, AppSpacing.page, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MockPageHeader(
                title: 'Practice',
                subtitle: 'Browse mocks and drills by exam type.',
              ),
              const SizedBox(height: AppSpacing.section),
              Row(
                children: [
                  Expanded(
                    child: MockSecondaryButton(
                      label: 'Exam catalog',
                      onPressed: () => context.push('/exam-types'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.item),
                  Expanded(
                    child: MockSecondaryButton(
                      label: 'Post-UTME',
                      onPressed: () => context.push('/post-utme'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.section),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search exams…',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.section),
              examTypesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (types) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ExamTypeChip(
                        label: 'All',
                        selected: _selectedExamTypeSlug == null,
                        onSelected: () => setState(() => _selectedExamTypeSlug = null),
                      ),
                      const SizedBox(width: AppSpacing.item),
                      ...types.map(
                        (type) => Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.item),
                          child: _ExamTypeChip(
                            label: type.title,
                            selected: _selectedExamTypeSlug == type.slug,
                            onSelected: () => setState(() => _selectedExamTypeSlug = type.slug),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        Expanded(
          child: examsAsync.when(
            loading: () => const MockLoadingView(message: 'Loading exams…'),
            error: (error, _) => MockErrorView(message: error.toString(), onRetry: () => ref.invalidate(examsCatalogProvider(_selectedExamTypeSlug))),
            data: (exams) {
              final filtered = exams.where((exam) {
                if (query.isEmpty) return true;
                return exam.title.toLowerCase().contains(query) ||
                    exam.subjectLabel.toLowerCase().contains(query) ||
                    exam.examTypeLabel.toLowerCase().contains(query);
              }).toList();
              if (filtered.isEmpty) {
                return const MockEmptyState(title: 'No exams found', message: 'Try another exam type filter.');
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(examsCatalogProvider(_selectedExamTypeSlug)),
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.page,
                    AppSpacing.page,
                    AppSpacing.page + AppSpacing.glassNavClearance,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.section),
                  itemBuilder: (context, index) {
                    final exam = filtered[index];
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

class _ExamTypeChip extends StatelessWidget {
  const _ExamTypeChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? context.appPrimarySoft : context.colors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? AppColors.primary.withValues(alpha: 0.4) : context.appBorder),
          ),
          child: Text(
            label,
            style: context.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.primary : context.appTextSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
