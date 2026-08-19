import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/config/app_config.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/auth/providers/auth_providers.dart';
import 'package:mock_mobile/features/payments/data/payment_repository.dart';
import 'package:mock_mobile/features/push/data/push_notification_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  var _isUpdatingPush = false;

  Future<void> _togglePushNotifications(bool enabled) async {
    setState(() => _isUpdatingPush = true);
    try {
      final service = ref.read(pushNotificationServiceProvider);
      if (enabled) {
        final router = GoRouter.of(context);
        final success = await service.initialize(router);
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Push notifications are not available on this device yet.')),
          );
        }
      } else {
        await service.disable();
      }
      ref.invalidate(engagementProvider);
    } finally {
      if (mounted) {
        setState(() => _isUpdatingPush = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final engagementAsync = ref.watch(engagementProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My profile')),
      body: user == null
          ? const MockLoadingView()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                MockCard(
                  child: Row(
                    children: [
                      MockUserAvatar(initials: user.initials, size: 56),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                            Text(user.email, style: const TextStyle(color: AppColors.textSecondary)),
                            if (user.mockProfile?.isVerified == true)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: MockChip(label: 'Verified', tone: MockChipTone.success),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                MockCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Exam setup', style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(
                        user.mockProfile?.interests?.primaryExamTypeSlug?.toUpperCase() ?? 'Not set yet',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      if (user.mockProfile?.interests?.targetScore != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Target score: ${user.mockProfile!.interests!.targetScore}',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                MockCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Premium access', style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      const Text(
                        'Unlock full timed mocks and premium practice packs.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      MockPrimaryButton(
                        label: 'Browse packages',
                        onPressed: () => context.push('/packages'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                engagementAsync.when(
                  loading: () => const MockCard(child: MockLoadingView(message: 'Loading settings…')),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (engagement) => MockCard(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Daily streak reminders'),
                      subtitle: Text(
                        AppConfig.isFirebaseConfigured
                            ? '${engagement.practiceStreakDays}-day streak · push ${engagement.fcmNotificationsEnabled ? 'on' : 'off'}'
                            : 'Configure Firebase dart-defines to enable mobile push.',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      value: engagement.fcmNotificationsEnabled,
                      onChanged: (!_isUpdatingPush && AppConfig.isFirebaseConfigured)
                          ? _togglePushNotifications
                          : null,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
