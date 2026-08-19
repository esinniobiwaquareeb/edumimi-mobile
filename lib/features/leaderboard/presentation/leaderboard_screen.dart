import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Top Students', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('See who is leading this period.', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              MockSegmentedControl<String>(
                segments: const ['week', 'month', 'all'],
                selected: _period,
                onChanged: (value) => setState(() => _period = value),
                labelBuilder: (value) => switch (value) {
                  'month' => 'Month',
                  'all' => 'All',
                  _ => 'Week',
                },
              ),
              const SizedBox(height: 12),
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
        Expanded(
          child: leaderboardAsync.when(
            loading: () => const MockLoadingView(message: 'Loading top students…'),
            error: (error, _) => MockErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(leaderboardProvider((period: _period, examTypeSlug: _examTypeSlug))),
            ),
            data: (response) {
              if (response.entries.isEmpty) {
                return const MockEmptyState(
                  title: 'No scores yet',
                  message: 'Be the first to submit a score this period.',
                );
              }
              final podium = response.entries.take(3).toList();
              final rest = response.entries.skip(3).toList();
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(leaderboardProvider((period: _period, examTypeSlug: _examTypeSlug))),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...podium.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: MockCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('#${entry.rank}', style: const TextStyle(color: AppColors.textDisabled, fontWeight: FontWeight.w700)),
                                Text(entry.displayName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                                const SizedBox(height: 4),
                                Text('${entry.percentScore.toStringAsFixed(1)}% · ${entry.examTitle}', style: const TextStyle(color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        )),
                    ...rest.map((entry) => _LeaderboardMobileRow(entry: entry)),
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
    final dateLabel = entry.submittedAt.isNotEmpty
        ? DateFormat.yMMMd().format(DateTime.parse(entry.submittedAt))
        : '—';

    return MockCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.displayName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          if (entry.subjectName != null) Text(entry.subjectName!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Text(entry.examTitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 10),
          _Row(label: 'Rank', value: '#${entry.rank}'),
          _Row(label: 'Score', value: '${entry.percentScore.toStringAsFixed(1)}%', valueColor: AppColors.success),
          _Row(label: 'When', value: dateLabel),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textDisabled)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: valueColor ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}
