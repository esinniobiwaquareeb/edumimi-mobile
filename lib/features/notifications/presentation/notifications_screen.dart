import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mock_mobile/core/config/app_config.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/theme/theme_context.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/mock/data/mock_portal_repository.dart';
import 'package:mock_mobile/features/notifications/data/unread_counts_repository.dart';
import 'package:mock_mobile/features/notifications/notifications_push_actions.dart';
import 'package:mock_mobile/features/notifications/utils/app_activity_notifications.dart';
import 'package:mock_mobile/features/payments/data/payment_repository.dart';
import 'package:mock_mobile/features/push/data/push_notification_service.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  var _isUpdatingPush = false;
  var _isPreviewingLocal = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _markActivityRead());
  }

  Future<void> _markActivityRead() async {
    try {
      await ref.read(unreadCountsRepositoryProvider).markActivityRead();
      invalidateUnreadSummary(ref);
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _togglePushNotifications(bool enabled) async {
    setState(() => _isUpdatingPush = true);
    try {
      await toggleMockPushNotifications(ref: ref, context: context, enabled: enabled);
      invalidateUnreadSummary(ref);
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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const MockBackButton(),
        title: Text('Notifications', style: context.cardTitle),
        bottom: MockFilledTabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Activity'),
            Tab(text: 'Push'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _ActivityNotificationsTab(),
          _PushNotificationsTab(
            isUpdatingPush: _isUpdatingPush,
            isPreviewingLocal: _isPreviewingLocal,
            onTogglePush: _togglePushNotifications,
            onPreviewLocal: _previewLocalReminder,
          ),
        ],
      ),
    );
  }
}

class _ActivityNotificationsTab extends ConsumerWidget {
  const _ActivityNotificationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasesAsync = ref.watch(myPurchasesProvider);
    final attemptsAsync = ref.watch(attemptsProvider);

    return purchasesAsync.when(
      loading: () => const MockLoadingView(message: 'Loading activity…'),
      error: (error, _) => MockErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(myPurchasesProvider),
      ),
      data: (purchases) => attemptsAsync.when(
        loading: () => const MockLoadingView(message: 'Loading activity…'),
        error: (error, _) => MockErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(attemptsProvider),
        ),
        data: (attempts) {
          final items = buildAppActivityNotifications(
            purchases: purchases,
            attempts: attempts,
          );

          if (items.isEmpty) {
            return const MockEmptyState(
              title: 'No activity yet',
              message: 'Payments, package unlocks, and submitted scores will show up here.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myPurchasesProvider);
              ref.invalidate(attemptsProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.page),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.section),
              itemBuilder: (context, index) {
                final item = items[index];
                return _ActivityNotificationCard(item: item);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ActivityNotificationCard extends StatelessWidget {
  const _ActivityNotificationCard({required this.item});

  final AppActivityNotification item;

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.kind) {
      AppActivityNotificationKind.purchase => LucideIcons.receipt,
      AppActivityNotificationKind.attempt => LucideIcons.barChart3,
    };
    final timestamp = item.timestamp.millisecondsSinceEpoch > 0
        ? DateFormat('d MMM · HH:mm').format(item.timestamp.toLocal())
        : 'Recently';

    return MockCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: item.route == null ? null : () => context.push(item.route!),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.appPrimarySoft,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: context.appBorder),
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.section),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: context.cardTitle),
                  const SizedBox(height: 4),
                  Text(item.message, style: context.bodySecondary),
                  const SizedBox(height: AppSpacing.item),
                  Text(timestamp, style: context.caption),
                ],
              ),
            ),
            if (item.route != null)
              MockLongArrowIcon(
                direction: MockLongArrowDirection.right,
                size: 18,
                color: context.appTextDisabled,
              ),
          ],
        ),
      ),
    );
  }
}

class _PushNotificationsTab extends ConsumerWidget {
  const _PushNotificationsTab({
    required this.isUpdatingPush,
    required this.isPreviewingLocal,
    required this.onTogglePush,
    required this.onPreviewLocal,
  });

  final bool isUpdatingPush;
  final bool isPreviewingLocal;
  final ValueChanged<bool> onTogglePush;
  final VoidCallback onPreviewLocal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engagementAsync = ref.watch(engagementProvider);
    final firebaseConfigured = AppConfig.isFirebaseConfigured;

    return ListView(
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
                  'Add Firebase config files and rebuild to enable remote streak reminders.',
                  style: context.bodySecondary,
                ),
                const SizedBox(height: AppSpacing.section),
                MockSecondaryButton(
                  label: isPreviewingLocal ? 'Sending preview…' : 'Preview local reminder',
                  onPressed: isPreviewingLocal ? null : onPreviewLocal,
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
              Text('Device push settings', style: context.sectionTitle),
              const SizedBox(height: 4),
              Text(
                'Streak reminders are sent to this phone when you have an active streak but have not practiced today.',
                style: context.bodySecondary,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.page),
        engagementAsync.when(
          loading: () => const MockCard(child: MockLoadingView(message: 'Loading push settings…')),
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
                          : 'Configure Firebase to enable remote push.',
                      style: context.caption,
                    ),
                    value: firebaseConfigured && engagement.fcmNotificationsEnabled,
                    onChanged: (!isUpdatingPush && firebaseConfigured) ? onTogglePush : null,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
