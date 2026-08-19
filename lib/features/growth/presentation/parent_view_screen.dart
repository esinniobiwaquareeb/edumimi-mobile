import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/mock/data/mock_portal_repository.dart';
import 'package:mock_mobile/shared/models/mock_attempt.dart';

class ParentViewScreen extends ConsumerWidget {
  const ParentViewScreen({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewAsync = ref.watch(parentViewProvider(token));

    return Scaffold(
      appBar: const MockDetailAppBar(title: 'Parent / coach view'),
      body: viewAsync.when(
        loading: () => const MockLoadingView(message: 'Loading progress…'),
        error: (_, __) => const MockEmptyState(
          title: 'Parent link not found',
          message: 'This link may have expired or the student disabled sharing.',
        ),
        data: (view) => ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            MockCard(
              elevated: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${view.studentFirstName}'s progress", style: context.pageTitle.copyWith(fontSize: 22)),
                  const SizedBox(height: AppSpacing.item),
                  Text('Read-only snapshot — no login required.', style: context.bodySecondary),
                  if (view.examCountdown?.isNotEmpty == true) ...[
                    const SizedBox(height: AppSpacing.section),
                    MockMetaRow(label: 'Exam countdown', value: view.examCountdown!),
                  ],
                ],
              ),
            ),
            if (view.weakTopics.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.page),
              const MockSectionTitle(title: 'Weak topics'),
              const SizedBox(height: AppSpacing.section),
              Wrap(
                spacing: AppSpacing.item,
                runSpacing: AppSpacing.item,
                children: view.weakTopics
                    .map((topic) => MockWeakTopicChip(
                          topic: MockWeakTopic(topic: topic, percent: 0, questionCount: 0, correctCount: 0),
                        ))
                    .toList(),
              ),
            ],
            if (view.recentAttempts.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.page),
              const MockSectionTitle(title: 'Recent attempts'),
              const SizedBox(height: AppSpacing.section),
              ...view.recentAttempts.map(
                (attempt) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.section),
                  child: MockCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(attempt.examTitle, style: context.cardTitle),
                              if (attempt.subjectName?.isNotEmpty == true)
                                Text(attempt.subjectName!, style: context.caption),
                            ],
                          ),
                        ),
                        Text('${attempt.percentScore.round()}%', style: context.sectionTitle),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
