import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/auth/providers/auth_providers.dart';

class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (user != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: MockCard(
                    child: Row(
                      children: [
                        MockUserAvatar(initials: user.initials),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w800)),
                              Text(user.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.lock_open_outlined),
                title: const Text('Unlock full access'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/packages');
                },
              ),
              ListTile(
                leading: const Icon(Icons.forum_outlined),
                title: const Text('Study Squad chat'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/community');
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('My profile'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/profile');
                },
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text('Log out', style: TextStyle(color: AppColors.error)),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authControllerProvider.notifier).logout();
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                children: [
                  TextSpan(text: 'mock'),
                  TextSpan(text: '.edumimi', style: TextStyle(color: AppColors.primary)),
                ],
              ),
            ),
            Text(
              'Part of Edumimi',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textDisabled,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Practice'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Top Students'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'My Scores'),
        ],
      ),
    );
  }
}
