import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mock_mobile/core/network/api_exception.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/theme/theme_context.dart';
import 'package:mock_mobile/core/utils/text_utils.dart' show formatMockDifficulty, formatMockMode;
import 'package:mock_mobile/core/widgets/mock_rich_content.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/exams/exam_attempt_utils.dart';
import 'package:mock_mobile/features/exams/presentation/widgets/exam_attempt_history_card.dart';
import 'package:mock_mobile/features/mock/data/mock_portal_repository.dart';
import 'package:mock_mobile/shared/models/mock_attempt.dart';
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
        error: (error, _) => MockErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(examDetailProvider(slug)),
        ),
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
        MockToast.error(context, error.message);
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
    final attemptsAsync = ref.watch(attemptsProvider);
    final pastAttempts = attemptsAsync.maybeWhen(
      data: (attempts) => filterSubmittedAttemptsForExam(attempts, exam),
      orElse: () => const <MockAttempt>[],
    );
    final bestScore = _resolveBestScore(exam, pastAttempts);
    final previewQuestions = exam.questions.take(3).toList();
    final difficultyLabel = formatMockDifficulty(exam.difficulty);
    final accessCopy = _resolveAccessCopy(exam);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.page),
      children: [
        Text(exam.title, style: context.pageTitle),
        const SizedBox(height: AppSpacing.section),
        Wrap(
          spacing: AppSpacing.item,
          runSpacing: AppSpacing.item,
          children: [
            if (exam.examTypeLabel.isNotEmpty)
              MockChip(label: exam.examTypeLabel, tone: MockChipTone.primary),
            if (exam.subjectLabel.isNotEmpty)
              MockChip(label: exam.subjectLabel, tone: MockChipTone.neutral),
            MockChip(label: formatMockMode(exam.mode), tone: MockChipTone.primary),
            if (difficultyLabel.isNotEmpty)
              MockChip(label: difficultyLabel, tone: MockChipTone.neutral),
            if (exam.examYear != null)
              MockChip(label: '${exam.examYear} paper', tone: MockChipTone.neutral),
          ],
        ),
        if (exam.recommendationReason?.isNotEmpty == true) ...[
          const SizedBox(height: AppSpacing.section),
          MockInlineNotice.info(message: exam.recommendationReason!),
        ],
        const SizedBox(height: AppSpacing.page),
        MockCard(
          elevated: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MockSectionTitle(title: 'Mock information'),
              const SizedBox(height: AppSpacing.section),
              Row(
                children: [
                  MockStatTile(
                    icon: LucideIcons.clock3,
                    label: 'Duration',
                    value: '${exam.durationMinutes} min',
                  ),
                  const SizedBox(width: AppSpacing.item),
                  MockStatTile(
                    icon: LucideIcons.layers,
                    label: 'Questions',
                    value: '${exam.displayQuestionCount}',
                  ),
                  const SizedBox(width: AppSpacing.item),
                  MockStatTile(
                    icon: LucideIcons.checkCircle2,
                    label: 'Marks',
                    value: '${exam.displayTotalMarks}',
                  ),
                ],
              ),
              if (bestScore != null) ...[
                const SizedBox(height: AppSpacing.section),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.section),
                Row(
                  children: [
                    MockScoreRing(percent: bestScore),
                    const SizedBox(width: AppSpacing.section),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your best score', style: context.cardTitle),
                          const SizedBox(height: 4),
                          Text(
                            '${bestScore.round()}% across ${pastAttempts.length} attempt${pastAttempts.length == 1 ? '' : 's'}',
                            style: context.bodySecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        _AccessNotice(copy: accessCopy),
        if (exam.description?.trim().isNotEmpty == true) ...[
          const SizedBox(height: AppSpacing.section),
          MockCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MockSectionTitle(title: 'About this exam'),
                const SizedBox(height: AppSpacing.item),
                MockRichContent(content: exam.description),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.section),
        _InstructionsSection(instructions: exam.instructions),
        const SizedBox(height: AppSpacing.section),
        _WhatToExpectSection(mode: exam.mode, examYear: exam.examYear),
        if (previewQuestions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.page),
          Text('Preview', style: context.label),
          const SizedBox(height: 4),
          Text('Sample questions from this mock', style: context.sectionTitle),
          const SizedBox(height: AppSpacing.section),
          ...previewQuestions.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.section),
                  child: _QuestionPreviewCard(
                    question: entry.value,
                    index: entry.key,
                  ),
                ),
              ),
        ],
        if (pastAttempts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.section),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const MockSectionTitle(title: 'Past attempts'),
              TextButton(
                onPressed: () => context.push('/exams/${exam.slug}/attempts'),
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.item),
          ...pastAttempts.take(3).map(
                (attempt) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.section),
                  child: ExamAttemptHistoryCard(attempt: attempt),
                ),
              ),
        ],
        const SizedBox(height: AppSpacing.page),
        MockPrimaryButton(
          label: exam.isLocked ? 'Unlock full access' : _startButtonLabel(exam),
          isLoading: _isStarting,
          onPressed: exam.isLocked ? () => context.push('/packages') : _start,
        ),
        const SizedBox(height: AppSpacing.item),
        MockSecondaryButton(
          label: exam.isLocked ? 'Browse packages' : 'Browse more mocks',
          onPressed: () => context.push(exam.isLocked ? '/packages' : '/exams'),
        ),
        const SizedBox(height: AppSpacing.section),
      ],
    );
  }
}

class _AccessCopy {
  const _AccessCopy({
    required this.heading,
    required this.body,
    required this.tone,
  });

  final String heading;
  final String body;
  final MockNoticeTone tone;
}

_AccessCopy _resolveAccessCopy(MockExam exam) {
  if (exam.isFreePractice && !exam.isLocked) {
    return const _AccessCopy(
      heading: 'Free practice',
      body: 'Free preview — no payment needed. Start anytime.',
      tone: MockNoticeTone.success,
    );
  }

  if (!exam.isLocked) {
    return const _AccessCopy(
      heading: 'Access active',
      body: 'Your package unlocks this mock. You can start right away.',
      tone: MockNoticeTone.success,
    );
  }

  return const _AccessCopy(
    heading: 'Full mock access needed',
    body: 'Full-length mocks and past papers need active access. Unlock a package to continue.',
    tone: MockNoticeTone.info,
  );
}

String _startButtonLabel(MockExam exam) {
  switch (exam.mode) {
    case 'FULL_MOCK':
    case 'PAST_PAPER':
      return 'Run mock exam';
    case 'TOPIC_DRILL':
      return 'Start topic drill';
    default:
      return 'Start practice';
  }
}

double? _resolveBestScore(MockExam exam, List<MockAttempt> attempts) {
  final scores = <double>[
    if (exam.percentScore != null) exam.percentScore!,
    ...attempts.map((attempt) => attempt.percentScore.toDouble()),
  ];
  if (scores.isEmpty) {
    return null;
  }
  return scores.reduce(math.max);
}

class _AccessNotice extends StatelessWidget {
  const _AccessNotice({required this.copy});

  final _AccessCopy copy;

  @override
  Widget build(BuildContext context) {
    final bodyColor = switch (copy.tone) {
      MockNoticeTone.success => AppColors.success,
      MockNoticeTone.error => AppColors.error,
      MockNoticeTone.info => context.appTextSecondary,
    };

    return MockCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.info,
            size: 18,
            color: copy.tone == MockNoticeTone.success ? AppColors.success : context.appTextSecondary,
          ),
          const SizedBox(width: AppSpacing.section),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(copy.heading, style: context.cardTitle),
                const SizedBox(height: 4),
                Text(
                  copy.body,
                  style: context.bodySecondary.copyWith(
                    color: bodyColor,
                    fontWeight: copy.tone == MockNoticeTone.success ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionsSection extends StatelessWidget {
  const _InstructionsSection({this.instructions});

  final String? instructions;

  @override
  Widget build(BuildContext context) {
    final body = instructions?.trim().isNotEmpty == true
        ? instructions!.trim()
        : 'Read all questions carefully and select the best answer. The exam timer starts immediately upon launching.';

    return MockCard(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.section),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Instructions', style: context.label),
              const SizedBox(height: AppSpacing.item),
              MockRichContent(content: body),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhatToExpectSection extends StatelessWidget {
  const _WhatToExpectSection({required this.mode, this.examYear});

  final String mode;
  final int? examYear;

  @override
  Widget build(BuildContext context) {
    final bullets = switch (mode) {
      'FULL_MOCK' => const [
        'Timed full-length mock under exam conditions.',
        'Timer starts as soon as you launch the session.',
        'Submit when finished — scores appear in My Scores.',
      ],
      'PAST_PAPER' => [
        if (examYear != null)
          'Questions drawn from the $examYear past-paper style bank.',
        'Practice under timed conditions like the real exam.',
        'Review explanations after you submit.',
      ],
      'TOPIC_DRILL' => const [
        'Focused drill on specific syllabus topics.',
        'Shorter sessions to sharpen weak areas quickly.',
        'Ideal for targeted revision between full mocks.',
      ],
      _ => const [
        'Free practice you can start anytime.',
        'Mix of questions to build confidence before full mocks.',
        'Sign in to save scores and track progress over time.',
      ],
    };

    return MockCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MockSectionTitle(title: 'What to expect'),
          const SizedBox(height: AppSpacing.item),
          ...bullets.map(
            (bullet) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.item),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.section),
                  Expanded(child: Text(bullet, style: context.bodySecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionPreviewCard extends StatelessWidget {
  const _QuestionPreviewCard({required this.question, required this.index});

  final MockQuestion question;
  final int index;

  @override
  Widget build(BuildContext context) {
    return MockCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Question ${index + 1}', style: context.label.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.item),
          MockRichContent(
            content: question.questionText,
            format: question.contentFormat,
            style: context.cardTitle.copyWith(fontSize: 15),
          ),
          if (question.options.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.section),
            ...List.generate(question.options.length, (optionIndex) {
              final optionLabel = String.fromCharCode(65 + optionIndex);
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.item),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.appNeutralSoft,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: context.appBorder),
                  ),
                  child: Text(
                    '$optionLabel. ${question.options[optionIndex]}',
                    style: context.caption.copyWith(color: context.appTextSecondary),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
