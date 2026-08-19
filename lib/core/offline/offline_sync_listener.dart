import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mock_mobile/core/offline/connectivity_service.dart';
import 'package:mock_mobile/core/offline/offline_sync_service.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/mock/data/mock_portal_repository.dart';

class OfflineSyncListener extends ConsumerStatefulWidget {
  const OfflineSyncListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<OfflineSyncListener> createState() => _OfflineSyncListenerState();
}

class _OfflineSyncListenerState extends ConsumerState<OfflineSyncListener> {
  var _didInitialSync = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_syncPending(showFeedback: false));
    });
  }

  Future<void> _syncPending({required bool showFeedback}) async {
    final result = await ref.read(offlineSyncServiceProvider).syncPendingSubmits(
          ref.read(mockPortalRepositoryProvider),
        );
    if (!mounted || !showFeedback || !result.hasWork) {
      return;
    }
    if (result.syncedCount > 0) {
      ref.invalidate(attemptsProvider);
      MockToast.success(
        context,
        'Synced ${result.syncedCount} offline submission${result.syncedCount == 1 ? '' : 's'}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<ConnectivityStatus>>(connectivityStatusProvider, (previous, next) {
      final wasOnline = previous?.valueOrNull?.isOnline ?? false;
      final isOnline = next.valueOrNull?.isOnline ?? false;
      if (!_didInitialSync) {
        _didInitialSync = true;
        return;
      }
      if (!wasOnline && isOnline) {
        unawaited(_syncPending(showFeedback: true));
      }
    });

    return widget.child;
  }
}
