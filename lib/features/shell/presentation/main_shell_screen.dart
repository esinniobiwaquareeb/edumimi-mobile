import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/theme/app_icons.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/auth/providers/auth_providers.dart';
import 'package:mock_mobile/features/payments/data/payment_repository.dart';

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
    final engagementAsync = ref.watch(engagementProvider);

    final engagement = engagementAsync.valueOrNull;
    final streakAtRisk = engagement?.streakAtRisk ?? false;
    final showNotificationBadge = streakAtRisk && !(engagement?.fcmNotificationsEnabled ?? false);

    return Scaffold(
      extendBody: true,
      appBar: MockAppHeader(
        userName: user?.firstName ?? user?.displayName,
        userInitials: user?.initials,
        avatarUrl: user?.avatarUrl,
        onProfileTap: () => context.push('/profile'),
        onCommunityTap: () => context.push('/community'),
        onNotificationsTap: () => context.push('/notifications'),
        showNotificationBadge: showNotificationBadge,
      ),
      body: navigationShell,
      bottomNavigationBar: MockGlassNavBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: _destinations,
      ),
    );
  }
}
