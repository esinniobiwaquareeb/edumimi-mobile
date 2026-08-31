import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/constants/mock_voice.dart';
import 'package:mock_mobile/core/theme/app_icons.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/core/widgets/mock_adaptive_layout.dart';
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
  int _page = 1;

  void _setPeriod(String value) {
    setState(() {
      _period = value;
      _page = 1;
    });
  }

  void _setExamTypeSlug(String? value) {
    setState(() {
      _examTypeSlug = value;
      _page = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final examTypesAsync = ref.watch(examTypesProvider);
    final leaderboardAsync = ref.watch(
      leaderboardProvider((
        period: _period,
        examTypeSlug: _examTypeSlug,
        page: _page,
      )),
    );
    final periodLabel = MockVoice.leaderboardPeriodLabel(_period);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MockContentWidth(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.page,
              AppSpacing.page,
              0,
            ),
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
                  onChanged: (value) => _setPeriod(value),
                  labelBuilder: (value) =>
                      MockVoice.leaderboardPeriodLabel(value),
                ),
                const SizedBox(height: AppSpacing.section),
                examTypesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (types) => DropdownButtonFormField<String?>(
                    value: _examTypeSlug,
                    decoration: const InputDecoration(labelText: 'Exam type'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All exam types'),
                      ),
                      ...types.map(
                        (type) => DropdownMenuItem<String?>(
                          value: type.slug,
                          child: Text(type.title),
                        ),
                      ),
                    ],
                    onChanged: _setExamTypeSlug,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        Expanded(
          child: leaderboardAsync.when(
            loading: () =>
                const MockLoadingView(message: 'Loading top students…'),
            error: (error, _) => MockErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(
                leaderboardProvider((
                  period: _period,
                  examTypeSlug: _examTypeSlug,
                  page: _page,
                )),
              ),
            ),
            data: (response) {
              final total = response.meta?.total ?? response.entries.length;
              if (total == 0) {
                return MockEmptyState(
                  title: 'No scores yet',
                  message:
                      'Be the first to submit a score for ${periodLabel.toLowerCase()}.',
                );
              }
              final showPodium = _page == 1;
              final podium = showPodium
                  ? response.entries.where((entry) => entry.rank <= 3).toList()
                  : const [];
              final rest = showPodium
                  ? response.entries.where((entry) => entry.rank > 3).toList()
                  : response.entries;
              final meta = response.meta;
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(
                  leaderboardProvider((
                    period: _period,
                    examTypeSlug: _examTypeSlug,
                    page: _page,
                  )),
                ),
                child: ListView(
                  padding: MockTabScrollPadding.list(context),
                  children: [
                    MockContentWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          MockCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  MockVoice.leaderboardPrizesTitle,
                                  style: context.cardTitle,
                                ),
                                const SizedBox(height: AppSpacing.item),
                                Text(
                                  MockVoice.leaderboardPrizesBody,
                                  style: context.bodySecondary,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.section),
                          if (podium.isNotEmpty) ...[
                            Text('Podium', style: context.label),
                            const SizedBox(height: AppSpacing.item),
                            ...podium.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.section,
                                ),
                                child: MockPodiumCard(
                                  rank: entry.rank,
                                  name: entry.displayName,
                                  score:
                                      '${entry.percentScore.toStringAsFixed(1)}%',
                                  subtitle: entry.examTitle,
                                ),
                              ),
                            ),
                          ],
                          if (rest.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.item),
                            Text(
                              showPodium ? 'Everyone else' : 'Rankings',
                              style: context.label,
                            ),
                            const SizedBox(height: AppSpacing.item),
                            ...rest.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.section,
                                ),
                                child: _LeaderboardMobileRow(entry: entry),
                              ),
                            ),
                          ],
                          if (meta != null && meta.totalPages > 1) ...[
                            const SizedBox(height: AppSpacing.item),
                            _LeaderboardPagination(
                              page: meta.page,
                              totalPages: meta.totalPages,
                              total: meta.total,
                              limit: meta.limit,
                              onPrevious: meta.page > 1
                                  ? () => setState(() => _page -= 1)
                                  : null,
                              onNext: meta.page < meta.totalPages
                                  ? () => setState(() => _page += 1)
                                  : null,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.section),
                          MockCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  MockVoice.leaderboardCtaTitle,
                                  style: context.cardTitle,
                                ),
                                const SizedBox(height: AppSpacing.item),
                                Text(
                                  MockVoice.leaderboardCtaBody,
                                  style: context.bodySecondary,
                                ),
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

class _LeaderboardPagination extends StatelessWidget {
  const _LeaderboardPagination({
    required this.page,
    required this.totalPages,
    required this.total,
    required this.limit,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final int total;
  final int limit;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final start = total == 0 ? 0 : ((page - 1) * limit) + 1;
    final end = total == 0 ? 0 : (page * limit > total ? total : page * limit);

    return MockCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $start to $end of $total',
              style: context.caption,
            ),
          ),
          Text('$page / $totalPages', style: context.label),
          const SizedBox(width: AppSpacing.item),
          IconButton(
            onPressed: onPrevious,
            icon: const MockLongArrowIcon(
              direction: MockLongArrowDirection.left,
              size: AppIcons.navSize,
              semanticLabel: 'Previous page',
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const MockLongArrowIcon(
              direction: MockLongArrowDirection.right,
              size: AppIcons.navSize,
              semanticLabel: 'Next page',
            ),
          ),
        ],
      ),
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
                    Text(
                      entry.examTitle,
                      style: context.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '${entry.percentScore.toStringAsFixed(1)}%',
                style: context.cardTitle,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.item),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                MockVoice.leaderboardTableWhen,
                style: context.caption.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(dateLabel, style: context.caption),
            ],
          ),
        ],
      ),
    );
  }
}
