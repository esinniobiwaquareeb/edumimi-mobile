import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/utils/text_utils.dart';
import 'package:mock_mobile/core/widgets/mock_rich_content.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/mock/data/mock_portal_repository.dart';

class GuestPracticeDetailScreen extends ConsumerWidget {
  const GuestPracticeDetailScreen({super.key, required this.slug});

  final String slug;

  Future<void> _confirmStart(BuildContext context) async {
    final shouldStart = await MockConfirmDialog.show(
      context,
      title: 'Start practice?',
      message:
          'The timer starts as soon as you continue. Keep this screen open while you practise.',
      confirmLabel: 'Continue',
      cancelLabel: 'Not now',
      variant: MockConfirmDialogVariant.warning,
    );
    if (shouldStart && context.mounted) {
      context.push('/try/$slug/take');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examAsync = ref.watch(examDetailProvider(slug));
    return Scaffold(
      appBar: const MockDetailAppBar(title: 'Practice details'),
      body: examAsync.when(
        loading: () => const MockLoadingView(message: 'Loading practice…'),
        error: (error, _) => MockErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(examDetailProvider(slug)),
        ),
        data: (exam) => ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            Text(exam.title, style: context.pageTitle),
            const SizedBox(height: AppSpacing.item),
            Text(
              [
                exam.examTypeLabel,
                exam.subjectLabel,
              ].where((item) => item.isNotEmpty).join(' · '),
              style: context.pageSubtitle,
            ),
            const SizedBox(height: AppSpacing.page),
            MockCard(
              child: Row(
                children: [
                  Expanded(
                    child: _Info(
                      label: 'Questions',
                      value: '${exam.totalQuestions}',
                    ),
                  ),
                  Expanded(
                    child: _Info(
                      label: 'Duration',
                      value: '${exam.durationMinutes} min',
                    ),
                  ),
                  Expanded(
                    child: _Info(
                      label: 'Mode',
                      value: formatMockMode(exam.mode),
                    ),
                  ),
                ],
              ),
            ),
            if (exam.description?.trim().isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.section),
              MockCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('About this practice', style: context.cardTitle),
                    const SizedBox(height: AppSpacing.item),
                    MockRichContent(content: exam.description),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.page),
            MockPrimaryButton(
              label: 'Start practice',
              onPressed: () => _confirmStart(context),
            ),
            const SizedBox(height: AppSpacing.item),
            Text(
              'Create a free account after your practice to save progress and access more mocks.',
              textAlign: TextAlign.center,
              style: context.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: context.caption),
      const SizedBox(height: 4),
      Text(value, style: context.cardTitle),
    ],
  );
}
