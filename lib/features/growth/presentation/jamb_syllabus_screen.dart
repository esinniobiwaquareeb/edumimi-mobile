import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/mock/data/mock_portal_repository.dart';

class JambSyllabusScreen extends ConsumerWidget {
  const JambSyllabusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syllabusAsync = ref.watch(jambSyllabusProvider);

    return Scaffold(
      appBar: const MockDetailAppBar(title: 'JAMB syllabus & novels'),
      body: syllabusAsync.when(
        loading: () => const MockLoadingView(message: 'Loading JAMB module…'),
        error: (_, __) => MockErrorView(message: 'Could not load JAMB syllabus.', onRetry: () => ref.invalidate(jambSyllabusProvider)),
        data: (module) => ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            Text('Syllabus & recommended texts', style: context.pageTitle),
            const SizedBox(height: AppSpacing.item),
            Text(
              'Syllabus topics, compulsory novel, and practice sets linked to literature drills.',
              style: context.pageSubtitle,
            ),
            const SizedBox(height: AppSpacing.page),
            const MockSectionTitle(title: 'Recommended texts'),
            const SizedBox(height: AppSpacing.section),
            ...module.recommendedTexts.map(
              (text) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.section),
                child: MockCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(text.title, style: context.cardTitle),
                      if (text.author?.isNotEmpty == true)
                        Text(text.author!, style: context.caption),
                      if (text.summary?.isNotEmpty == true) ...[
                        const SizedBox(height: AppSpacing.item),
                        Text(text.summary!, style: context.bodySecondary),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const MockSectionTitle(title: 'Syllabus topics'),
            const SizedBox(height: AppSpacing.section),
            ...module.syllabusTopics.map(
              (topic) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.section),
                child: MockCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(topic.title, style: context.cardTitle),
                      if (topic.subjectName?.isNotEmpty == true)
                        Text(topic.subjectName!, style: context.caption),
                      if (topic.description?.isNotEmpty == true) ...[
                        const SizedBox(height: AppSpacing.item),
                        Text(topic.description!, style: context.bodySecondary),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const MockSectionTitle(title: 'Linked practice'),
            const SizedBox(height: AppSpacing.section),
            ...module.practiceExams.map(
              (exam) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.section),
                child: MockExamCard(
                  title: exam.title,
                  subtitle: exam.subjectName ?? 'JAMB',
                  meta: exam.mode ?? 'PRACTICE',
                  onTap: () => context.push('/exams/${exam.slug}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
