import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/config/app_config.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
import 'package:mock_mobile/core/theme/theme_context.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/payments/data/payment_repository.dart';
import 'package:mock_mobile/features/push/data/push_notification_service.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  var _isUpdatingPush = false;
  var _isPreviewingLocal = false;

  Future<void> _togglePushNotifications(bool enabled) async {
    setState(() => _isUpdatingPush = true);
    try {
      final service = ref.read(pushNotificationServiceProvider);
      if (enabled) {
        final router = GoRouter.of(context);
        final success = await service.initialize(router);
        if (!success && mounted) {
          MockToast.info(context, 'Push notifications are not available on this device yet.');
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

  Future<void> _previewLocalReminder() async {
    setState(() => _isPreviewingLocal = true);
    try {
      final success = await ref.read(pushNotificationServiceProvider).previewLocalStreakReminder();
      if (!success && mounted) {
        MockToast.info(context, 'Allow notifications in system settings to preview reminders.');
      }
    } finally {
      if (mounted) {
        setState(() => _isPreviewingLocal = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final engagementAsync = ref.watch(engagementProvider);
    final firebaseConfigured = AppConfig.isFirebaseConfigured;

    return Scaffold(
      appBar: const MockDetailAppBar(title: 'Notifications'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          if (!firebaseConfigured) ...[
            MockCard(
              elevated: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.orange.shade800, size: 22),
                      const SizedBox(width: AppSpacing.item),
                      Expanded(child: Text('Push not configured', style: context.sectionTitle)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.item),
                  Text(
                    'Firebase is not enabled in this build. Remote streak reminders require dart-defines and platform config files.',
                    style: context.bodySecondary,
                  ),
                  const SizedBox(height: AppSpacing.section),
                  Text('To enable FCM push:', style: context.cardTitle.copyWith(fontSize: 14)),
                  const SizedBox(height: AppSpacing.item),
                  Text(
                    '1. Create a Firebase project and add Android + iOS apps\n'
                    '2. Replace android/app/google-services.json\n'
                    '3. Add ios/Runner/GoogleService-Info.plist from Firebase Console\n'
                    '4. Rebuild with FIREBASE_PROJECT_ID, FIREBASE_API_KEY, FIREBASE_APP_ID, and FIREBASE_MESSAGING_SENDER_ID dart-defines\n\n'
                    'See README.md → Firebase setup for full steps.',
                    style: context.caption,
                  ),
                  const SizedBox(height: AppSpacing.section),
                  MockSecondaryButton(
                    label: _isPreviewingLocal ? 'Sending preview…' : 'Preview local reminder',
                    onPressed: _isPreviewingLocal ? null : _previewLocalReminder,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.page),
          ],
          MockCard(
            elevated: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.appPrimarySoft,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: context.appBorder),
                      ),
                      child: const Icon(Icons.notifications_none_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.section),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Practice reminders', style: context.sectionTitle),
                          const SizedBox(height: 4),
                          Text(
                            'Stay on track with daily streak nudges — not a full message inbox yet.',
                            style: context.bodySecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.page),
          engagementAsync.when(
            loading: () => const MockCard(child: MockLoadingView(message: 'Loading reminders…')),
            error: (_, __) => const SizedBox.shrink(),
            data: (engagement) {
              final streakLabel = engagement.practiceStreakDays > 0
                  ? '${engagement.practiceStreakDays}-day streak active'
                  : 'No active streak yet';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MockCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MockSectionTitle(title: 'Your streak'),
                        const SizedBox(height: AppSpacing.item),
                        Text(
                          engagement.streakAtRisk
                              ? 'Your streak is on the line — practice today to keep it alive.'
                              : engagement.practiceStreakDays > 0
                                  ? 'Complete one practice today to extend your streak.'
                                  : 'Complete one practice today to start a streak.',
                          style: context.bodySecondary,
                        ),
                        const SizedBox(height: AppSpacing.section),
                        Row(
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: 18,
                              color: engagement.streakAtRisk ? const Color(0xFFD97706) : AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(streakLabel, style: context.cardTitle),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.page),
                  MockCard(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Daily streak reminders', style: context.cardTitle),
                      subtitle: Text(
                        firebaseConfigured
                            ? 'Get a push notification if you have an active streak but have not practiced today.'
                            : 'Configure Firebase (see notice above) to enable remote push.',
                        style: context.caption,
                      ),
                      value: firebaseConfigured && engagement.fcmNotificationsEnabled,
                      onChanged: (!_isUpdatingPush && firebaseConfigured) ? _togglePushNotifications : null,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.page),
          MockSecondaryButton(
            label: 'Open profile settings',
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
    );
  }
}
