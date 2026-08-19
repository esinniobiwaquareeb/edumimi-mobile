import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/network/api_exception.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
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
      appBar: AppBar(title: const Text('Exam details')),
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
      padding: const EdgeInsets.all(16),
      children: [
        Text(exam.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
        ],
        const SizedBox(height: 16),
        MockCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MockChip(label: formatMockMode(exam.mode), tone: MockChipTone.primary),
              const SizedBox(height: 12),
              Text('${exam.totalQuestions} questions · ${exam.durationMinutes} minutes'),
              if (exam.description != null && exam.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                MockRichContent(content: exam.description),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        MockPrimaryButton(
          label: exam.isLocked ? 'Unlock full access' : 'Start practice',
          isLoading: _isStarting,
          onPressed: exam.isLocked ? () => context.push('/packages') : _start,
        ),
      ],
    );
  }
}
