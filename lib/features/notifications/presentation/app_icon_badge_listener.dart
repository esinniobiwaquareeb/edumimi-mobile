import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mock_mobile/features/auth/providers/auth_providers.dart';
import 'package:mock_mobile/features/notifications/data/app_icon_badge_service.dart';
import 'package:mock_mobile/features/notifications/data/unread_counts_repository.dart';
import 'package:mock_mobile/shared/models/mock_unread_summary.dart';

/// Watches unread counts and updates the home screen app icon badge.
class AppIconBadgeListener extends ConsumerStatefulWidget {
  const AppIconBadgeListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppIconBadgeListener> createState() => _AppIconBadgeListenerState();
}

class _AppIconBadgeListenerState extends ConsumerState<AppIconBadgeListener> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && ref.read(authControllerProvider).isAuthenticated) {
      invalidateUnreadSummary(ref);
    }
  }

  void _applyBadge(MockUnreadSummary summary) {
    AppIconBadgeService.sync(summary.appIconBadgeCount);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (!next.isAuthenticated) {
        AppIconBadgeService.clear();
        return;
      }
      invalidateUnreadSummary(ref);
    });

    ref.listen<AsyncValue<MockUnreadSummary>>(unreadSummaryProvider, (previous, next) {
      if (!auth.isAuthenticated) {
        AppIconBadgeService.clear();
        return;
      }

      next.when(
        data: _applyBadge,
        error: (_, __) => AppIconBadgeService.clear(),
        loading: () {},
      );
    });

    if (auth.isAuthenticated) {
      final unreadAsync = ref.watch(unreadSummaryProvider);
      unreadAsync.whenData(_applyBadge);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppIconBadgeService.clear();
      });
    }

    return widget.child;
  }
}
