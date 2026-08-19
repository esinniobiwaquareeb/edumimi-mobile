import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
import 'package:mock_mobile/core/theme/theme_context.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/widgets/mock_rich_content.dart';
import 'package:mock_mobile/core/utils/share_utils.dart';
import 'package:mock_mobile/core/widgets/mock_share_button.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/auth/providers/auth_providers.dart';
import 'package:mock_mobile/features/mock/data/mock_portal_repository.dart';
import 'package:mock_mobile/features/payments/data/payment_repository.dart';
import 'package:mock_mobile/shared/models/mock_attempt.dart';
import 'package:mock_mobile/shared/models/mock_exam.dart';

class ResultDetailScreen extends ConsumerWidget {
  const ResultDetailScreen({super.key, required this.attemptId});

  final String attemptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attemptAsync = ref.watch(attemptDetailProvider(attemptId));

    return Scaffold(
      appBar: const MockDetailAppBar(title: 'Result breakdown'),
      body: attemptAsync.when(
        loading: () => const MockLoadingView(message: 'Loading result…'),
        error: (error, _) => MockErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(attemptDetailProvider(attemptId)),
        ),
        data: (attempt) => _ResultDetailBody(attempt: attempt),
      ),
    );
  }
}

class _ResultDetailBody extends ConsumerStatefulWidget {
  const _ResultDetailBody({required this.attempt});

  final MockAttempt attempt;

  @override
  ConsumerState<_ResultDetailBody> createState() => _ResultDetailBodyState();
}

class _ResultDetailBodyState extends ConsumerState<_ResultDetailBody> {
  var _showAllQuestions = false;

  @override
  Widget build(BuildContext context) {
    final attempt = widget.attempt;
    final exam = attempt.exam;
    final engagement = ref.watch(engagementProvider).valueOrNull;
    final user = ref.watch(authControllerProvider).user;
    final isPreview = isPreviewAttempt(attempt);
    final challengerName = user?.firstName ?? 'I';
    final questions = [...(exam?.questions ?? const <MockQuestion>[])]
      ..sort((left, right) => left.position.compareTo(right.position));
    final unlockedQuestions = questions.where((question) => !question.isLocked).toList();
    final visibleQuestions = _showAllQuestions ? unlockedQuestions : unlockedQuestions.take(5).toList();
    final durationLabel = attempt.durationSeconds != null && attempt.durationSeconds! > 0
        ? '${(attempt.durationSeconds! / 60).ceil()} mins'
        : '${exam?.durationMinutes ?? 0} mins';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.page),
      children: [
        Text(exam?.title ?? 'Mock exam', style: context.pageTitle),
        if (exam?.examType?.title != null) ...[
          const SizedBox(height: AppSpacing.item),
          Text(exam!.examType!.title, style: context.bodySecondary),
        ],
        const SizedBox(height: AppSpacing.page),
        MockCard(
          elevated: true,
          child: Row(
            children: [
              MockScoreRing(percent: attempt.percentScore),
              const SizedBox(width: AppSpacing.page),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MockMetaRow(label: 'Score', value: '${attempt.score}/${attempt.totalPossibleScore}'),
                    MockMetaRow(label: 'Percent', value: '${attempt.percentScore}%'),
                    MockMetaRow(label: 'Duration', value: durationLabel),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.page),
        MockCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Share your result', style: context.sectionTitle),
              const SizedBox(height: AppSpacing.item),
              Text(
                attempt.percentScore >= 70
                    ? 'Strong attempt — share it with friends or challenge them to beat your score.'
                    : 'Invite friends to practice together or challenge them to take the same mock.',
                style: context.bodySecondary,
              ),
              const SizedBox(height: AppSpacing.section),
              MockShareScoreButton(
                examTitle: exam?.title ?? 'Mock Exam',
                percentScore: attempt.percentScore,
                isPreview: isPreview,
                includeLeaderboard: !isPreview,
                referralLink: engagement?.referralLink,
              ),
              const SizedBox(height: AppSpacing.item),
              MockChallengeShareButton(
                attemptId: attempt.id,
                examTitle: exam?.title ?? 'Mock Exam',
                percentScore: attempt.percentScore,
                challengerName: challengerName,
              ),
            ],
          ),
        ),
        if (attempt.remediationSuggestions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.section),
          const MockSectionTitle(title: 'What to practice next'),
          const SizedBox(height: AppSpacing.section),
          ...attempt.remediationSuggestions.map(
            (suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.section),
              child: MockCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MockChip(label: 'Needs work · ${suggestion.percent}%', tone: MockChipTone.neutral),
                    const SizedBox(height: 8),
                    Text(suggestion.topic, style: context.cardTitle),
                    const SizedBox(height: 4),
                    Text(
                      '${suggestion.correctCount} of ${suggestion.questionCount} correct',
                      style: context.caption,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        if (attempt.topicStats.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.section),
          const MockSectionTitle(title: 'Topic breakdown'),
          const SizedBox(height: AppSpacing.section),
          ...attempt.topicStats.map((stat) => _TopicStatCard(stat: stat)),
        ],
        const SizedBox(height: AppSpacing.section),
        const MockSectionTitle(title: 'Answer review'),
        const SizedBox(height: AppSpacing.section),
        ...visibleQuestions.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value;
          return _QuestionReviewCard(
            question: question,
            index: index,
            selectedAnswer: attempt.answers[question.id],
          );
        }),
        if (unlockedQuestions.length > 5) ...[
          const SizedBox(height: AppSpacing.section),
          MockSecondaryButton(
            label: _showAllQuestions
                ? 'Show fewer questions'
                : 'Show all ${unlockedQuestions.length} questions',
            onPressed: () => setState(() => _showAllQuestions = !_showAllQuestions),
          ),
        ],
        if (exam?.slug.isNotEmpty ?? false) ...[
          const SizedBox(height: AppSpacing.page),
          MockPrimaryButton(
            label: 'Retake mock',
            onPressed: () => context.push('/exams/${exam!.slug}'),
          ),
        ],
      ],
    );
  }
}

class _TopicStatCard extends StatelessWidget {
  const _TopicStatCard({required this.stat});

  final MockTopicStat stat;

  @override
  Widget build(BuildContext context) {
    final isMastered = stat.percent >= 75;
    final isReviewNeeded = stat.percent < 60;
    final foreground = isReviewNeeded
        ? AppColors.error
        : isMastered
            ? AppColors.success
            : AppColors.warning;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.section),
      child: MockCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MockChip(
              label: isReviewNeeded
                  ? 'Needs practice'
                  : isMastered
                      ? 'Mastered'
                      : 'Progressing',
              tone: isMastered ? MockChipTone.success : MockChipTone.neutral,
            ),
            const SizedBox(height: 8),
            Text(stat.topic, style: context.cardTitle),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${stat.percent}% score', style: context.body.copyWith(color: foreground)),
                Text('${stat.correct}/${stat.total} correct', style: context.caption),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: stat.percent / 100,
                minHeight: 6,
                backgroundColor: context.appNeutralSoft,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionReviewCard extends StatelessWidget {
  const _QuestionReviewCard({
    required this.question,
    required this.index,
    required this.selectedAnswer,
  });

  final MockQuestion question;
  final int index;
  final int? selectedAnswer;

  @override
  Widget build(BuildContext context) {
    final correctIndex = question.correctOptionIndex;
    final isCorrect = selectedAnswer != null && correctIndex != null && selectedAnswer == correctIndex;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.section),
      child: MockCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text('Question ${index + 1}', style: context.label),
                ),
                MockChip(
                  label: isCorrect ? 'Correct' : 'Incorrect',
                  tone: isCorrect ? MockChipTone.success : MockChipTone.neutral,
                ),
              ],
            ),
            if (question.hasQuestionGroup) ...[
              const SizedBox(height: AppSpacing.section),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.section),
                decoration: BoxDecoration(
                  color: context.appWarningSoft,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: context.appBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (question.questionGroupTitle?.isNotEmpty ?? false)
                      Text(question.questionGroupTitle!, style: context.caption),
                    if (question.questionGroupText?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 6),
                      MockRichContent(content: question.questionGroupText, format: question.contentFormat),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.section),
            MockRichContent(
              content: question.questionText,
              format: question.contentFormat,
              style: context.cardTitle.copyWith(fontSize: 15),
            ),
            const SizedBox(height: AppSpacing.section),
            ...List.generate(question.options.length, (optionIndex) {
              final isSelected = selectedAnswer == optionIndex;
              final isRight = correctIndex == optionIndex;
              Color background;
              Color borderColor;
              if (isSelected && isRight) {
                background = context.appSuccessSoft;
                borderColor = AppColors.success;
              } else if (isSelected) {
                background = context.appErrorSoft;
                borderColor = AppColors.error;
              } else if (isRight) {
                background = context.appSuccessSoft;
                borderColor = AppColors.success;
              } else {
                background = context.appNeutralSoft;
                borderColor = context.appBorder;
              }

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(AppSpacing.section),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${String.fromCharCode(65 + optionIndex)}.', style: context.body.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MockRichContent(
                        content: question.options[optionIndex],
                        format: question.contentFormat,
                        inline: true,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (question.explanation?.isNotEmpty ?? false) ...[
              const SizedBox(height: AppSpacing.section),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.section),
                decoration: BoxDecoration(
                  color: context.appPrimarySoft,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Explanation', style: context.caption.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    MockRichContent(content: question.explanation, format: question.contentFormat),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
