import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/mock/data/mock_portal_repository.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attemptsAsync = ref.watch(attemptsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Scores', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              SizedBox(height: 6),
              Text('Your progress and submitted attempts.', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
        Expanded(
          child: attemptsAsync.when(
            loading: () => const MockLoadingView(message: 'Loading results…'),
            error: (error, _) => MockErrorView(message: error.toString(), onRetry: () => ref.invalidate(attemptsProvider)),
            data: (attempts) {
              if (attempts.isEmpty) {
                return const MockEmptyState(
                  title: 'No attempts yet',
                  message: 'Your scores will show up here after your first practice.',
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(attemptsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: attempts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final attempt = attempts[index];
                    return MockCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(attempt.exam?.title ?? 'Mock exam', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(
                            attempt.exam?.examType?.title ?? 'General',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          _ResultRow(label: 'Status', value: attempt.status.replaceAll('_', ' '), valueColor: attempt.isSubmitted ? AppColors.success : AppColors.textSecondary),
                          _ResultRow(label: 'Score', value: '${attempt.score}/${attempt.totalPossibleScore}'),
                          _ResultRow(label: 'Percent', value: '${attempt.percentScore}%', valueColor: AppColors.primary),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value, this.valueColor});

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
