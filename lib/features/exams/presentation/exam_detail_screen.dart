import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/network/api_exception.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/utils/text_utils.dart' show formatMockMode;
import 'package:mock_mobile/core/widgets/mock_rich_content.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/mock/data/mock_portal_repository.dart';
import 'package:mock_mobile/shared/models/mock_exam.dart';

class ExamDetailScreen extends ConsumerWidget {
  const ExamDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examAsync = ref.watch(examDetailProvider(slug));

    return Scaffold(
      appBar: const MockDetailAppBar(title: 'Exam details'),
      body: examAsync.when(
        loading: () => const MockLoadingView(message: 'Loading exam…'),
        error: (error, _) => MockErrorView(message: error.toString(), onRetry: () => ref.invalidate(examDetailProvider(slug))),
        data: (exam) => _ExamDetailBody(exam: exam),
      ),
    );
  }
}

class _ExamDetailBody extends ConsumerStatefulWidget {
  const _ExamDetailBody({required this.exam});

  final MockExam exam;

  @override
  ConsumerState<_ExamDetailBody> createState() => _ExamDetailBodyState();
}

class _ExamDetailBodyState extends ConsumerState<_ExamDetailBody> {
  var _isStarting = false;

  Future<void> _start() async {
    if (widget.exam.isLocked) {
      return;
    }
    setState(() => _isStarting = true);
    try {
      context.push('/exams/${widget.exam.slug}/take');
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exam = widget.exam;
    final subtitle = [exam.examTypeLabel, exam.subjectLabel].where((part) => part.isNotEmpty).join(' · ');

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.page),
      children: [
        Text(exam.title, style: context.pageTitle),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.item),
          Text(subtitle, style: context.bodySecondary),
        ],
        const SizedBox(height: AppSpacing.page),
        MockCard(
          elevated: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.item,
                runSpacing: AppSpacing.item,
                children: [
                  MockChip(label: formatMockMode(exam.mode), tone: MockChipTone.primary),
                  MockChip(label: '${exam.totalQuestions} questions', tone: MockChipTone.neutral),
                  MockChip(label: '${exam.durationMinutes} min', tone: MockChipTone.neutral),
                ],
              ),
              if (exam.description != null && exam.description!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.page),
                const MockSectionTitle(title: 'About this exam'),
                const SizedBox(height: AppSpacing.item),
                MockRichContent(content: exam.description),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.page),
        MockPrimaryButton(
          label: exam.isLocked ? 'Unlock full access' : 'Start practice',
          isLoading: _isStarting,
          onPressed: exam.isLocked ? () => context.push('/packages') : _start,
        ),
      ],
    );
  }
}
