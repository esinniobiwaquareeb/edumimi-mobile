import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/theme/app_icons.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/auth/providers/auth_providers.dart';
import 'package:mock_mobile/features/notifications/data/unread_counts_repository.dart';
import 'package:mock_mobile/shared/models/mock_unread_summary.dart';

class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    MockNavDestination(icon: AppIcons.dashboard, selectedIcon: AppIcons.dashboardSelected, label: 'Dashboard'),
    MockNavDestination(icon: AppIcons.practice, selectedIcon: AppIcons.practiceSelected, label: 'Practice'),
    MockNavDestination(icon: AppIcons.leaderboard, selectedIcon: AppIcons.leaderboardSelected, label: 'Top Students'),
    MockNavDestination(icon: AppIcons.results, selectedIcon: AppIcons.resultsSelected, label: 'My Scores'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final unreadAsync = ref.watch(unreadSummaryProvider);
    final unread = unreadAsync.valueOrNull ?? MockUnreadSummary.empty;

    return Scaffold(
      extendBody: true,
      appBar: MockAppHeader(
        userName: user?.firstName ?? user?.displayName,
        userInitials: user?.initials,
        avatarUrl: user?.avatarUrl,
        onProfileTap: () => context.push('/profile'),
        onCommunityTap: () => context.push('/community'),
        onNotificationsTap: () => context.push('/notifications'),
        communityBadgeCount: unread.communityUnread,
        notificationBadgeCount: unread.notificationUnread,
      ),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: navigationShell),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MockGlassNavBar.scrimHeight(context),
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0, 0.55, 1],
                    colors: [
                      Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0),
                      Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.72),
                      Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.94),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: MockGlassNavBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: navigationShell.goBranch,
              destinations: _destinations,
            ),
          ),
        ],
      ),
    );
  }
}
