import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/constants/mock_voice.dart';
import 'package:mock_mobile/core/network/api_exception.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/utils/text_utils.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/core/widgets/mock_adaptive_layout.dart';
import 'package:mock_mobile/core/widgets/offline_status_banner.dart';
import 'package:mock_mobile/features/auth/providers/auth_providers.dart';
import 'package:mock_mobile/features/mock/data/mock_portal_repository.dart';
import 'package:mock_mobile/features/payments/data/payment_repository.dart';
import 'package:mock_mobile/shared/models/mock_attempt.dart';
import 'package:mock_mobile/shared/models/mock_exam.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _startAdaptiveDrill(
    BuildContext context,
    WidgetRef ref,
    List<MockWeakTopic> weakTopics,
  ) async {
    final exams = await ref.read(examsCatalogProvider(null).future);
    MockExam? practiceBank;
    for (final exam in exams) {
      if (exam.mode == 'PRACTICE' || exam.mode == 'TOPIC_DRILL') {
        practiceBank = exam;
        break;
      }
    }
    practiceBank ??= exams.isNotEmpty ? exams.first : null;
    if (practiceBank == null) {
      if (context.mounted) {
        MockToast.info(
          context,
          'No practice bank available for an adaptive drill right now',
        );
      }
      return;
    }
    try {
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      final response = await ref
          .read(mockPortalRepositoryProvider)
          .startExam(
            practiceBank.slug,
            sessionId: sessionId,
            adaptive: true,
            focusTopics: weakTopics
                .map((topic) => topic.topic)
                .where((topic) => topic.isNotEmpty)
                .take(5)
                .toList(),
          );
      if (context.mounted) {
        context.push(
          '/exams/${practiceBank.slug}/take?attemptId=${Uri.encodeComponent(response.attemptId)}&sessionId=${Uri.encodeComponent(sessionId)}',
        );
      }
    } on ApiException catch (error) {
      if (context.mounted) {
        MockToast.error(context, error.message);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(examFeedProvider);
    final insightsAsync = ref.watch(studyInsightsProvider);
    final engagementAsync = ref.watch(engagementProvider);
    final attemptsAsync = ref.watch(attemptsProvider);
    final purchasesAsync = ref.watch(myPurchasesProvider);
    final user = ref.watch(authControllerProvider).user;
    final attempts = attemptsAsync.valueOrNull ?? const <MockAttempt>[];
    final submittedAttempts = attempts
        .where((attempt) => attempt.status == 'SUBMITTED')
        .length;
    MockAttempt? inProgressAttempt;
    for (final attempt in attempts) {
      if (attempt.isInProgress && attempt.exam != null) {
        inProgressAttempt = attempt;
        break;
      }
    }
    final purchases = purchasesAsync.valueOrNull ?? const [];
    final hasActivePurchases = purchases.any((purchase) => purchase.isActive);
    final feedExams = feedAsync.valueOrNull?.recommended ?? const <MockExam>[];
    final showUnlockUpsell =
        !hasActivePurchases && (submittedAttempts >= 1 || feedExams.isNotEmpty);
    final streakDays = engagementAsync.valueOrNull?.practiceStreakDays ?? 0;
    final onboardingCompleted = user?.mockProfile?.onboardingCompleted == true;
    final isWide = MockAdaptiveLayout.isWide(context);

    final progressCard = insightsAsync.when(
      loading: () =>
          const MockCard(child: MockLoadingView(message: 'Loading insights…')),
      error: (_, __) => const SizedBox.shrink(),
      data: (insights) => MockCard(
        elevated: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your progress', style: context.sectionTitle),
            const SizedBox(height: AppSpacing.section),
            Row(
              children: [
                MockStatTile(
                  label: 'Streak',
                  value: '$streakDays days',
                  icon: Icons.local_fire_department_outlined,
                  subtitle: streakDays > 0 ? 'Keep it going' : 'Start today',
                ),
                const SizedBox(width: AppSpacing.section),
                MockStatTile(
                  label: 'Attempts',
                  value: '$submittedAttempts',
                  icon: Icons.check_circle_outline_rounded,
                  subtitle: 'Submitted',
                ),
              ],
            ),
            if (insights.weakTopics.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.page),
              const MockSectionTitle(title: 'Improve in these areas'),
              const SizedBox(height: AppSpacing.item),
              Wrap(
                spacing: AppSpacing.item,
                runSpacing: AppSpacing.item,
                children: insights.weakTopics
                    .take(3)
                    .map((topic) => MockWeakTopicChip(topic: topic))
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.section),
              SizedBox(
                width: isWide ? 260 : double.infinity,
                child: MockSecondaryButton(
                  label: 'Practice weak topics',
                  onPressed: () =>
                      _startAdaptiveDrill(context, ref, insights.weakTopics),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    final quickActionsCard = MockCard(
      child: isWide
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Quick actions', style: context.sectionTitle),
                const SizedBox(height: AppSpacing.section),
                MockSecondaryButton(
                  label: 'Browse packages',
                  onPressed: () => context.push('/packages'),
                ),
                const SizedBox(height: AppSpacing.item),
                MockSecondaryButton(
                  label: 'Post-UTME packs',
                  onPressed: () => context.push('/post-utme'),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: MockSecondaryButton(
                    label: 'Browse packages',
                    onPressed: () => context.push('/packages'),
                  ),
                ),
                const SizedBox(width: AppSpacing.item),
                Expanded(
                  child: MockSecondaryButton(
                    label: 'Post-UTME packs',
                    onPressed: () => context.push('/post-utme'),
                  ),
                ),
              ],
            ),
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(examFeedProvider);
        ref.invalidate(studyInsightsProvider);
        ref.invalidate(engagementProvider);
        ref.invalidate(attemptsProvider);
        ref.invalidate(myPurchasesProvider);
      },
      child: ListView(
        padding: MockTabScrollPadding.list(context),
        children: [
          MockContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const MockPageHeader(
                  title: 'Dashboard',
                  subtitle: 'Pick up where you left off.',
                ),
                const SizedBox(height: AppSpacing.page),
                const OfflineStatusBanner(),
                const SizedBox(height: AppSpacing.section),
                if (!onboardingCompleted)
                  MockCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Finish setup first', style: context.sectionTitle),
                        const SizedBox(height: AppSpacing.item),
                        Text(
                          'Pick your exam and subjects so we can recommend the right practice.',
                          style: context.bodySecondary,
                        ),
                        const SizedBox(height: AppSpacing.section),
                        MockPrimaryButton(
                          label: 'Complete setup',
                          onPressed: () => context.go('/onboarding/interests'),
                        ),
                      ],
                    ),
                  ),
                if (!onboardingCompleted)
                  const SizedBox(height: AppSpacing.section),
                if (inProgressAttempt?.exam != null) ...[
                  MockCard(
                    elevated: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          MockVoice.continueAttemptLabel,
                          style: context.caption.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.item),
                        Text(
                          inProgressAttempt!.exam!.title,
                          style: context.sectionTitle,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            inProgressAttempt.exam!.subjectLabel,
                            inProgressAttempt.exam!.examTypeLabel,
                          ].where((part) => part.isNotEmpty).join(' · '),
                          style: context.bodySecondary,
                        ),
                        const SizedBox(height: AppSpacing.section),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: isWide ? 260 : double.infinity,
                            child: MockPrimaryButton(
                              label: MockVoice.continueAttemptCta,
                              onPressed: () => context.push(
                                '/exams/${inProgressAttempt!.exam!.slug}/take',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.section),
                ],
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: progressCard),
                      const SizedBox(width: AppSpacing.section),
                      SizedBox(
                        width: 300,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            quickActionsCard,
                            if (showUnlockUpsell) ...[
                              const SizedBox(height: AppSpacing.section),
                              _UnlockUpsellCard(
                                onTap: () => context.push('/packages'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  progressCard,
                  const SizedBox(height: AppSpacing.page),
                  quickActionsCard,
                  if (showUnlockUpsell) ...[
                    const SizedBox(height: AppSpacing.page),
                    _UnlockUpsellCard(onTap: () => context.push('/packages')),
                  ],
                ],
                const SizedBox(height: AppSpacing.page),
                feedAsync.when(
                  loading: () =>
                      const MockLoadingView(message: 'Loading practice…'),
                  error: (error, _) => MockErrorView(
                    message: error.toString(),
                    onRetry: () => ref.invalidate(examFeedProvider),
                  ),
                  data: (feed) {
                    final exams = feed.recommended.isNotEmpty
                        ? feed.recommended
                        : feed.all.take(5).toList();
                    if (exams.isEmpty) {
                      return MockEmptyState(
                        title: 'No practice ready yet',
                        message: 'Browse exams and start your first drill.',
                        actionLabel: 'Browse practice',
                        onAction: () => context.go('/exams'),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MockSectionTitle(title: 'Recommended for you'),
                        const SizedBox(height: AppSpacing.section),
                        if (isWide)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final itemWidth =
                                  (constraints.maxWidth - AppSpacing.section) /
                                  2;
                              return Wrap(
                                spacing: AppSpacing.section,
                                runSpacing: AppSpacing.section,
                                children: exams
                                    .map(
                                      (exam) => SizedBox(
                                        width: itemWidth,
                                        child: _ExamListTile(exam: exam),
                                      ),
                                    )
                                    .toList(),
                              );
                            },
                          )
                        else
                          ...exams.map(
                            (exam) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.section,
                              ),
                              child: _ExamListTile(exam: exam),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlockUpsellCard extends StatelessWidget {
  const _UnlockUpsellCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MockCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            MockVoice.unlockUpsellTitle,
            style: context.caption.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.item),
          Text(MockVoice.unlockUpsellBody, style: context.bodySecondary),
          const SizedBox(height: AppSpacing.section),
          MockPrimaryButton(label: MockVoice.unlockUpsellCta, onPressed: onTap),
        ],
      ),
    );
  }
}

class _ExamListTile extends StatelessWidget {
  const _ExamListTile({required this.exam});

  final MockExam exam;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      exam.examTypeLabel,
      exam.subjectLabel,
    ].where((part) => part.isNotEmpty).join(' · ');
    return MockExamCard(
      title: exam.title,
      subtitle: subtitle,
      meta:
          '${formatMockMode(exam.mode)} · ${exam.totalQuestions} questions · ${exam.durationMinutes} min',
      reason: exam.recommendationReason,
      locked: exam.isLocked,
      onTap: () => context.push('/exams/${exam.slug}'),
    );
  }
}
