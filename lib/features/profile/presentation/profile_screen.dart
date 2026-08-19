import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/auth/providers/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;

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
                      const SizedBox(height: 4),
                      if (user.mockProfile?.interests?.targetScore != null)
                        Text('Target score: ${user.mockProfile!.interests!.targetScore}', style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
