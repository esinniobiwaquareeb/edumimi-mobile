import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mock_mobile/core/theme/app_icons.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/theme_context.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/shared/models/mock_attempt.dart';

class ExamAttemptHistoryCard extends StatelessWidget {
  const ExamAttemptHistoryCard({super.key, required this.attempt});

  final MockAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final submittedLabel = attempt.submittedAt == null
        ? 'Submitted'
        : DateFormat.yMMMd().format(DateTime.parse(attempt.submittedAt!).toLocal());

    return MockCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: () => context.push('/results/${attempt.id}'),
        child: Row(
          children: [
            MockScoreRing(percent: attempt.percentScore),
            const SizedBox(width: AppSpacing.section),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MockMetaRow(
                    label: 'Score',
                    value: '${attempt.score}/${attempt.totalPossibleScore}',
                    emphasis: true,
                  ),
                  MockMetaRow(label: 'Percent', value: '${attempt.percentScore}%'),
                  MockMetaRow(label: 'Submitted', value: submittedLabel),
                ],
              ),
            ),
            MockLongArrowIcon(
              direction: MockLongArrowDirection.right,
              size: AppIcons.forwardSize,
              color: context.appTextDisabled,
            ),
          ],
        ),
      ),
    );
  }
}
