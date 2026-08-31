import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
import 'package:mock_mobile/core/theme/theme_context.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/utils/text_utils.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/core/widgets/mock_adaptive_layout.dart';
import 'package:mock_mobile/features/auth/providers/auth_providers.dart';
import 'package:mock_mobile/features/mock/data/mock_portal_repository.dart';
import 'package:mock_mobile/shared/models/mock_exam.dart';

typedef ExamCatalogParams = ({
  String examTypeSlug,
  String? subjectSlug,
  int? paperYearFrom,
  int? paperYearTo,
});

final examCatalogProvider = FutureProvider.autoDispose
    .family<List<MockExam>, ExamCatalogParams>((ref, params) {
      return ref
          .watch(mockPortalRepositoryProvider)
          .fetchExams(
            examTypeSlug: params.examTypeSlug,
            subjectSlug: params.subjectSlug,
            paperYearFrom: params.paperYearFrom,
            paperYearTo: params.paperYearTo,
          );
    });

class ExamCatalogScreen extends ConsumerStatefulWidget {
  const ExamCatalogScreen({super.key, required this.examTypeSlug});

  final String examTypeSlug;

  @override
  ConsumerState<ExamCatalogScreen> createState() => _ExamCatalogScreenState();
}

class _ExamCatalogScreenState extends ConsumerState<ExamCatalogScreen> {
  final _searchController = TextEditingController();
  String? _selectedSubjectSlug;
  int? _paperYearFrom;
  int? _paperYearTo;

  @override
  void initState() {
    super.initState();
    final interests = ref
        .read(authControllerProvider)
        .user
        ?.mockProfile
        ?.interests;
    _paperYearFrom = interests?.paperYearFrom;
    _paperYearTo = interests?.paperYearTo;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final examTypeAsync = ref.watch(
      examTypeDetailProvider(widget.examTypeSlug),
    );
    final catalogParams = (
      examTypeSlug: widget.examTypeSlug,
      subjectSlug: _selectedSubjectSlug,
      paperYearFrom: _paperYearFrom,
      paperYearTo: _paperYearTo,
    );
    final examsAsync = ref.watch(examCatalogProvider(catalogParams));

    return Scaffold(
      appBar: MockDetailAppBar(
        title: examTypeAsync.maybeWhen(
          data: (type) => type.title,
          orElse: () => 'Practice',
        ),
      ),
      body: examTypeAsync.when(
        loading: () => const MockLoadingView(message: 'Loading catalog…'),
        error: (error, _) => MockErrorView(
          message: error.toString(),
          onRetry: () =>
              ref.invalidate(examTypeDetailProvider(widget.examTypeSlug)),
        ),
        data: (examType) {
          final subjects = [...examType.subjects]
            ..sort((a, b) => a.name.compareTo(b.name));
          final query = _searchController.text.trim().toLowerCase();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MockContentWidth(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.page),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.examTypeSlug == 'jamb')
                        TextButton(
                          onPressed: () => context.push('/jamb/syllabus'),
                          child: const Text('JAMB syllabus & novels →'),
                        ),
                      TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search exams…',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.section),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'All subjects',
                              selected: _selectedSubjectSlug == null,
                              onTap: () =>
                                  setState(() => _selectedSubjectSlug = null),
                            ),
                            ...subjects.map(
                              (subject) => _FilterChip(
                                label: subject.name,
                                selected: _selectedSubjectSlug == subject.slug,
                                onTap: () => setState(
                                  () => _selectedSubjectSlug = subject.slug,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.section),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              value: _paperYearFrom,
                              decoration: const InputDecoration(
                                labelText: 'From year',
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('Any'),
                                ),
                                ...List.generate(15, (index) {
                                  final year = DateTime.now().year - index;
                                  return DropdownMenuItem(
                                    value: year,
                                    child: Text('$year'),
                                  );
                                }),
                              ],
                              onChanged: (value) =>
                                  setState(() => _paperYearFrom = value),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.section),
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              value: _paperYearTo,
                              decoration: const InputDecoration(
                                labelText: 'To year',
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('Any'),
                                ),
                                ...List.generate(15, (index) {
                                  final year = DateTime.now().year - index;
                                  return DropdownMenuItem(
                                    value: year,
                                    child: Text('$year'),
                                  );
                                }),
                              ],
                              onChanged: (value) =>
                                  setState(() => _paperYearTo = value),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: examsAsync.when(
                  loading: () =>
                      const MockLoadingView(message: 'Loading exams…'),
                  error: (error, _) => MockErrorView(
                    message: error.toString(),
                    onRetry: () =>
                        ref.invalidate(examCatalogProvider(catalogParams)),
                  ),
                  data: (exams) {
                    final filtered = exams.where((exam) {
                      if (query.isNotEmpty &&
                          !exam.title.toLowerCase().contains(query) &&
                          !exam.subjectLabel.toLowerCase().contains(query)) {
                        return false;
                      }
                      if (_selectedSubjectSlug != null &&
                          exam.subject?.slug != _selectedSubjectSlug) {
                        return false;
                      }
                      return true;
                    }).toList();

                    if (filtered.isEmpty) {
                      return const MockEmptyState(
                        title: 'No exams found',
                        message: 'Try another filter.',
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(examCatalogProvider(catalogParams)),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.page,
                          0,
                          AppSpacing.page,
                          AppSpacing.page,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.section),
                        itemBuilder: (context, index) {
                          final exam = filtered[index];
                          final subtitle = [
                            exam.examTypeLabel,
                            exam.subjectLabel,
                          ].where((part) => part.isNotEmpty).join(' · ');
                          final yearLabel = exam.examYear != null
                              ? '${exam.examYear} · '
                              : '';
                          return MockContentWidth(
                            child: MockExamCard(
                              title: exam.title,
                              subtitle: subtitle,
                              meta:
                                  '$yearLabel${formatMockMode(exam.mode)} · ${exam.totalQuestions} questions',
                              locked: exam.isLocked,
                              onTap: () => context.push('/exams/${exam.slug}'),
                            ),
                          );
                        },
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.item),
      child: Material(
        color: selected ? context.appPrimarySoft : context.colors.surface,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? AppColors.primary : context.appBorder,
              ),
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
      ),
    );
  }
}
