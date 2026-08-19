import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/offline/connectivity_service.dart';
import 'package:mock_mobile/core/offline/offline_sync_service.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
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
        const _StatusCard(
          icon: Icons.wifi_off_outlined,
          title: 'You are offline',
          message: 'Progress is saved on this device and will sync when you reconnect.',
          tone: AppColors.accent,
        ),
      );
    }

    if (pendingCount > 0) {
      children.add(
        _StatusCard(
          icon: Icons.cloud_upload_outlined,
          title: '$pendingCount submission${pendingCount == 1 ? '' : 's'} waiting to sync',
          message: 'Keep the app open when you are back online.',
          tone: AppColors.primary,
        ),
      );
    }

    if (savedSession != null) {
      children.add(
        MockCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Resume in-progress exam', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(savedSession.exam.title, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
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
          tone: AppColors.success,
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
          if (index > 0) const SizedBox(height: 12),
          children[index],
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.tone,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return MockCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tone),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
