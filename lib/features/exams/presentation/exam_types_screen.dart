import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/theme/theme_context.dart';
import 'package:mock_mobile/core/theme/app_icons.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/auth/providers/auth_providers.dart';
import 'package:mock_mobile/features/mock/data/mock_portal_repository.dart';

class ExamTypesScreen extends ConsumerStatefulWidget {
  const ExamTypesScreen({super.key});

  @override
  ConsumerState<ExamTypesScreen> createState() => _ExamTypesScreenState();
}

class _ExamTypesScreenState extends ConsumerState<ExamTypesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final examTypesAsync = ref.watch(examTypesProvider);
    final user = ref.watch(authControllerProvider).user;
    final primarySlug = user?.mockProfile?.interests?.primaryExamTypeSlug;
    final subjectIds = user?.mockProfile?.interests?.subjectIds ?? const [];
    final query = _searchController.text.trim().toLowerCase();

    return Scaffold(
      appBar: const MockDetailAppBar(title: 'Exam catalog'),
      body: examTypesAsync.when(
        loading: () => const MockLoadingView(message: 'Loading exam categories…'),
        error: (error, _) => MockErrorView(message: error.toString(), onRetry: () => ref.invalidate(examTypesProvider)),
        data: (examTypes) {
          final sorted = [...examTypes]..sort((left, right) {
              final leftScore = (left.slug == primarySlug ? 1 : 0) +
                  (left.subjects.any((subject) => subjectIds.contains(subject.id)) ? 2 : 0);
              final rightScore = (right.slug == primarySlug ? 1 : 0) +
                  (right.subjects.any((subject) => subjectIds.contains(subject.id)) ? 2 : 0);
              return rightScore.compareTo(leftScore);
            });
          final filtered = sorted.where((type) {
            if (query.isEmpty) return true;
            return type.title.toLowerCase().contains(query) ||
                (type.description?.toLowerCase().contains(query) ?? false);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.page),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Choose an exam path', style: context.pageTitle),
                    const SizedBox(height: AppSpacing.item),
                    Text('Open the exam type you want to practice.', style: context.pageSubtitle),
                    const SizedBox(height: AppSpacing.section),
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search exam types…',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const MockEmptyState(title: 'No matches', message: 'Try another search term.')
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.page),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.section),
                        itemBuilder: (context, index) {
                          final type = filtered[index];
                          return MockCard(
                            child: InkWell(
                              onTap: () => context.push('/exam-types/${type.slug}'),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(type.title, style: context.cardTitle),
                                        if (type.description?.isNotEmpty == true) ...[
                                          const SizedBox(height: AppSpacing.item),
                                          Text(type.description!, style: context.bodySecondary),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (type.slug == primarySlug)
                                    const MockChip(label: 'Your exam', tone: MockChipTone.success),
                                  MockLongArrowIcon(
                                    direction: MockLongArrowDirection.right,
                                    size: AppIcons.forwardSize,
                                    color: context.appTextSecondary,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
