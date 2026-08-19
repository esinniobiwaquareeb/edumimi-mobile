import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/mock/data/mock_portal_repository.dart';

class PostUtmePacksScreen extends ConsumerWidget {
  const PostUtmePacksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packsAsync = ref.watch(postUtmePacksProvider);
    final currency = NumberFormat.simpleCurrency(name: 'NGN', decimalDigits: 0);

    return Scaffold(
      appBar: const MockDetailAppBar(title: 'Post-UTME packs'),
      body: packsAsync.when(
        loading: () => const MockLoadingView(message: 'Loading packs…'),
        error: (_, __) => MockErrorView(message: 'Could not load post-UTME packs.', onRetry: () => ref.invalidate(postUtmePacksProvider)),
        data: (packs) {
          if (packs.isEmpty) {
            return const MockEmptyState(title: 'No packs yet', message: 'Check back soon for university screening packs.');
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.page),
            children: [
              Text('University screening packs', style: context.pageTitle),
              const SizedBox(height: AppSpacing.item),
              Text(
                'Past-style post-UTME practice for OAU, UNILAG, UI, UNN, and more.',
                style: context.pageSubtitle,
              ),
              const SizedBox(height: AppSpacing.page),
              ...packs.map(
                (pack) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.section),
                  child: MockExamCard(
                    title: pack.title,
                    subtitle: pack.universityName,
                    meta: [
                      if (pack.listPrice != null) currency.format(pack.listPrice),
                      '${pack.practiceExamCount} practice exams',
                    ].where((part) => part.isNotEmpty).join(' · '),
                    onTap: () => context.push('/post-utme/${pack.slug}'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PostUtmePackDetailScreen extends ConsumerWidget {
  const PostUtmePackDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(postUtmePackDetailProvider(slug));

    return Scaffold(
      appBar: const MockDetailAppBar(title: 'Post-UTME pack'),
      body: detailAsync.when(
        loading: () => const MockLoadingView(message: 'Loading pack…'),
        error: (_, __) => MockErrorView(message: 'Could not load this pack.', onRetry: () => ref.invalidate(postUtmePackDetailProvider(slug))),
        data: (detail) => ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            Text(detail.pack.title, style: context.pageTitle),
            const SizedBox(height: AppSpacing.item),
            Text(detail.pack.universityName, style: context.pageSubtitle),
            if (detail.pack.summary?.isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.section),
              Text(detail.pack.summary!, style: context.bodySecondary),
            ],
            const SizedBox(height: AppSpacing.page),
            const MockSectionTitle(title: 'Practice exams'),
            const SizedBox(height: AppSpacing.section),
            if (detail.practiceExams.isEmpty)
              Text(
                'Practice sets for this pack are coming soon.',
                style: context.bodySecondary,
              )
            else
              ...detail.practiceExams.map(
                (exam) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.section),
                  child: MockExamCard(
                    title: exam.title,
                    subtitle: exam.subjectLabel,
                    meta: exam.mode,
                    locked: exam.isLocked,
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
