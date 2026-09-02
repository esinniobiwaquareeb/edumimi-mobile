import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mock_mobile/core/config/app_config.dart';
import 'package:mock_mobile/core/network/api_exception.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/utils/mock_date_time.dart';
import 'package:mock_mobile/core/theme/theme_context.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/core/widgets/mock_adaptive_layout.dart';
import 'package:mock_mobile/features/notifications/data/notifications_repository.dart';
import 'package:mock_mobile/features/notifications/data/unread_counts_repository.dart';
import 'package:mock_mobile/features/notifications/notifications_push_actions.dart';
import 'package:mock_mobile/features/payments/data/payment_repository.dart';
import 'package:mock_mobile/features/push/data/push_notification_service.dart';
import 'package:mock_mobile/shared/models/mock_notification.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  var _isUpdatingPush = false;
  var _isPreviewingLocal = false;
  bool? _pushEnabledOverride;
  var _isMarkingAll = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _markAllAsRead() async {
    setState(() => _isMarkingAll = true);
    try {
      await ref.read(notificationsRepositoryProvider).markAllAsRead();
      invalidateNotifications(ref);
      invalidateUnreadSummary(ref);
    } finally {
      if (mounted) {
        setState(() => _isMarkingAll = false);
      }
    }
  }

  Future<void> _togglePushNotifications(bool enabled) async {
    setState(() {
      _isUpdatingPush = true;
      _pushEnabledOverride = enabled;
    });
    try {
      await toggleMockPushNotifications(
        ref: ref,
        context: context,
        enabled: enabled,
      );
      invalidateUnreadSummary(ref);
      if (mounted) {
        setState(() => _pushEnabledOverride = null);
      }
    } on ApiException {
      if (mounted) {
        setState(() => _pushEnabledOverride = null);
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingPush = false);
      }
    }
  }

  Future<void> _previewLocalReminder() async {
    setState(() => _isPreviewingLocal = true);
    try {
      final success = await ref
          .read(pushNotificationServiceProvider)
          .previewLocalStreakReminder();
      if (!success && mounted) {
        MockToast.info(
          context,
          'Allow notifications in system settings to preview reminders.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPreviewingLocal = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        ref.watch(unreadSummaryProvider).valueOrNull?.notificationUnread ?? 0;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const MockBackButton(),
        title: Text('Notifications', style: context.cardTitle),
        actions: [
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.item),
              child: TextButton(
                onPressed: _isMarkingAll ? null : _markAllAsRead,
                child: Text(
                  _isMarkingAll ? 'Marking…' : 'Mark all read',
                  style: context.label.copyWith(
                    color: _isMarkingAll
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
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
            pushEnabledOverride: _pushEnabledOverride,
            onTogglePush: _togglePushNotifications,
            onPreviewLocal: _previewLocalReminder,
          ),
        ],
      ),
    );
  }
}

class _ActivityNotificationsTab extends ConsumerStatefulWidget {
  const _ActivityNotificationsTab();

  @override
  ConsumerState<_ActivityNotificationsTab> createState() =>
      _ActivityNotificationsTabState();
}

class _ActivityNotificationsTabState
    extends ConsumerState<_ActivityNotificationsTab> {
  Future<void> _refreshNotifications() async {
    invalidateUnreadSummary(ref);
    ref.invalidate(notificationsProvider);
    await ref.read(notificationsProvider.future);
  }

  Future<void> _openNotification(MockNotification item) async {
    if (!item.isRead) {
      await ref.read(notificationsRepositoryProvider).markAsRead(item.id);
      invalidateNotifications(ref);
      invalidateUnreadSummary(ref);
    }

    final route = item.route;
    if (route != null && route.isNotEmpty && mounted) {
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return notificationsAsync.when(
      loading: () => const MockLoadingView(message: 'Loading notifications…'),
      error: (error, _) => MockErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(notificationsProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const MockEmptyState(
            title: 'No notifications yet',
            message:
                'Payments, package unlocks, and submitted scores will show up here.',
          );
        }

        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshNotifications,
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.page),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.section),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _NotificationCard(
                      item: item,
                      onTap: () => _openNotification(item),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final MockNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.category) {
      MockNotificationCategory.purchase => LucideIcons.receipt,
      MockNotificationCategory.attempt => LucideIcons.barChart3,
      MockNotificationCategory.referral => LucideIcons.gift,
      MockNotificationCategory.system => LucideIcons.bell,
    };
    final timestamp = MockDateTime.compactDateTime(
      item.createdAt,
      fallback: 'Recently',
    );

    return MockContentWidth(
      child: MockCard(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          onTap: onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.isRead
                      ? context.appNeutralSoft
                      : context.appPrimarySoft,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: context.cardTitle.copyWith(
                              fontWeight: item.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(item.message, style: context.bodySecondary),
                    const SizedBox(height: AppSpacing.item),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(timestamp, style: context.caption),
                        if (item.route != null)
                          MockLongArrowIcon(
                            direction: MockLongArrowDirection.right,
                            size: 18,
                            color: context.appTextDisabled,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PushNotificationsTab extends ConsumerWidget {
  const _PushNotificationsTab({
    required this.isUpdatingPush,
    required this.isPreviewingLocal,
    required this.pushEnabledOverride,
    required this.onTogglePush,
    required this.onPreviewLocal,
  });

  final bool isUpdatingPush;
  final bool isPreviewingLocal;
  final bool? pushEnabledOverride;
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
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.orange.shade800,
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.item),
                    Expanded(
                      child: Text(
                        'Push not configured',
                        style: context.sectionTitle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.item),
                Text(
                  'Add Firebase config files and rebuild to enable remote streak reminders.',
                  style: context.bodySecondary,
                ),
                const SizedBox(height: AppSpacing.section),
                MockSecondaryButton(
                  label: isPreviewingLocal
                      ? 'Sending preview…'
                      : 'Preview local reminder',
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
          loading: () => const MockCard(
            child: MockLoadingView(message: 'Loading push settings…'),
          ),
          error: (error, _) => MockCard(
            child: MockErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(engagementProvider),
            ),
          ),
          data: (engagement) {
            final pushEnabled =
                pushEnabledOverride ?? engagement.fcmNotificationsEnabled;
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
                            color: engagement.streakAtRisk
                                ? const Color(0xFFD97706)
                                : AppColors.primary,
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
                    title: Text(
                      'Daily streak reminders',
                      style: context.cardTitle,
                    ),
                    subtitle: Text(
                      firebaseConfigured
                          ? 'Get a push notification if you have an active streak but have not practiced today.'
                          : 'Configure Firebase to enable remote push.',
                      style: context.caption,
                    ),
                    value: firebaseConfigured && pushEnabled,
                    onChanged: (!isUpdatingPush && firebaseConfigured)
                        ? onTogglePush
                        : null,
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
