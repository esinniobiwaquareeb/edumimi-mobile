import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/offline/connectivity_service.dart';
import 'package:mock_mobile/core/offline/offline_sync_service.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';

class OfflineStatusBanner extends ConsumerWidget {
  const OfflineStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityStatusProvider).valueOrNull;
    final pendingCount = ref.watch(pendingSubmitCountProvider);
    final savedSession = ref.watch(savedExamSessionProvider);
    final offlineSubjects = ref.watch(offlineSubjectsProvider);

    final children = <Widget>[];

    if (connectivity != null && !connectivity.isOnline) {
      children.add(
        _StatusCard(
          icon: Icons.wifi_off_outlined,
          title: 'You are offline',
          message: 'Progress is saved on this device and will sync when you reconnect.',
        ),
      );
    }

    if (pendingCount > 0) {
      children.add(
        _StatusCard(
          icon: Icons.cloud_upload_outlined,
          title: '$pendingCount submission${pendingCount == 1 ? '' : 's'} waiting to sync',
          message: 'Keep the app open when you are back online.',
        ),
      );
    }

    if (savedSession != null) {
      children.add(
        MockCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resume in-progress exam', style: context.sectionTitle),
              const SizedBox(height: 4),
              Text(savedSession.exam.title, style: context.bodySecondary),
              const SizedBox(height: AppSpacing.section),
              MockPrimaryButton(
                label: 'Continue exam',
                onPressed: () => context.push('/exams/${savedSession.slug}/take'),
              ),
            ],
          ),
        ),
      );
    }

    if (offlineSubjects.isNotEmpty) {
      final totalQuestions = offlineSubjects.fold<int>(0, (sum, subject) => sum + subject.questions.length);
      children.add(
        _StatusCard(
          icon: Icons.download_done_outlined,
          title: '${offlineSubjects.length} subject${offlineSubjects.length == 1 ? '' : 's'} cached offline',
          message: '$totalQuestions questions saved for practice without a connection.',
        ),
      );
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.section),
          children[index],
        ],
        const SizedBox(height: AppSpacing.page),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return MockCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
          const SizedBox(width: AppSpacing.section),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.cardTitle),
                const SizedBox(height: 4),
                Text(message, style: context.bodySecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
