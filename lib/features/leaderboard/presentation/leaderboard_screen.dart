import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/constants/mock_voice.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/mock/data/mock_portal_repository.dart';
import 'package:mock_mobile/shared/models/mock_attempt.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  String _period = 'week';
  String? _examTypeSlug;

  @override
  Widget build(BuildContext context) {
    final examTypesAsync = ref.watch(examTypesProvider);
    final leaderboardAsync = ref.watch(leaderboardProvider((period: _period, examTypeSlug: _examTypeSlug)));
    final periodLabel = MockVoice.leaderboardPeriodLabel(_period);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.page, AppSpacing.page, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MockPageHeader(
                title: 'Top Students',
                subtitle: 'See who is leading $periodLabel.',
              ),
              const SizedBox(height: AppSpacing.page),
              MockSegmentedControl<String>(
                segments: const ['week', 'month', 'all'],
                selected: _period,
                onChanged: (value) => setState(() => _period = value),
                labelBuilder: (value) => MockVoice.leaderboardPeriodLabel(value),
              ),
              const SizedBox(height: AppSpacing.section),
              examTypesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (types) => DropdownButtonFormField<String?>(
                  value: _examTypeSlug,
                  decoration: const InputDecoration(labelText: 'Exam type'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('All exam types')),
                    ...types.map((type) => DropdownMenuItem<String?>(value: type.slug, child: Text(type.title))),
                  ],
                  onChanged: (value) => setState(() => _examTypeSlug = value),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        Expanded(
          child: leaderboardAsync.when(
            loading: () => const MockLoadingView(message: 'Loading top students…'),
            error: (error, _) => MockErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(leaderboardProvider((period: _period, examTypeSlug: _examTypeSlug))),
            ),
            data: (response) {
              if (response.entries.isEmpty) {
                return MockEmptyState(
                  title: 'No scores yet',
                  message: 'Be the first to submit a score for ${periodLabel.toLowerCase()}.',
                );
              }
              final podium = response.entries.take(3).toList();
              final rest = response.entries.skip(3).toList();
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(leaderboardProvider((period: _period, examTypeSlug: _examTypeSlug))),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.page,
                    AppSpacing.page,
                    AppSpacing.page + AppSpacing.glassNavClearance,
                  ),
                  children: [
                    MockCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(MockVoice.leaderboardPrizesTitle, style: context.cardTitle),
                          const SizedBox(height: AppSpacing.item),
                          Text(MockVoice.leaderboardPrizesBody, style: context.bodySecondary),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.section),
                    if (podium.isNotEmpty) ...[
                      Text('Podium', style: context.label),
                      const SizedBox(height: AppSpacing.item),
                      ...podium.map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.section),
                            child: MockPodiumCard(
                              rank: entry.rank,
                              name: entry.displayName,
                              score: '${entry.percentScore.toStringAsFixed(1)}%',
                              subtitle: entry.examTitle,
                            ),
                          )),
                    ],
                    if (rest.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.item),
                      Text('Everyone else', style: context.label),
                      const SizedBox(height: AppSpacing.item),
                      ...rest.map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.section),
                            child: _LeaderboardMobileRow(entry: entry),
                          )),
                    ],
                    const SizedBox(height: AppSpacing.section),
                    MockCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(MockVoice.leaderboardCtaTitle, style: context.cardTitle),
                          const SizedBox(height: AppSpacing.item),
                          Text(MockVoice.leaderboardCtaBody, style: context.bodySecondary),
                          const SizedBox(height: AppSpacing.section),
                          MockPrimaryButton(
                            label: MockVoice.leaderboardCtaButton,
                            onPressed: () => context.push('/packages'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LeaderboardMobileRow extends StatelessWidget {
  const _LeaderboardMobileRow({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final dateLabel = MockVoice.formatLeaderboardDate(entry.submittedAt);

    return MockCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                alignment: Alignment.center,
                child: Text('#${entry.rank}', style: context.label),
              ),
              const SizedBox(width: AppSpacing.section),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.displayName, style: context.cardTitle),
                    Text(entry.examTitle, style: context.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Text('${entry.percentScore.toStringAsFixed(1)}%', style: context.cardTitle),
            ],
          ),
          const SizedBox(height: AppSpacing.item),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(MockVoice.leaderboardTableWhen, style: context.caption.copyWith(fontWeight: FontWeight.w700)),
              Text(dateLabel, style: context.caption),
            ],
          ),
        ],
      ),
    );
  }
}
