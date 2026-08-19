import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mock_mobile/core/offline/connectivity_service.dart';
import 'package:mock_mobile/core/offline/exam_session_store.dart';
import 'package:mock_mobile/core/offline/offline_practice_cache.dart';
import 'package:mock_mobile/core/offline/pending_submit_queue.dart';
import 'package:mock_mobile/features/mock/data/mock_portal_repository.dart';

class OfflineSyncResult {
  const OfflineSyncResult({required this.syncedCount, required this.failedCount});

  final int syncedCount;
  final int failedCount;

  bool get hasWork => syncedCount > 0 || failedCount > 0;
}

class OfflineSyncService {
  OfflineSyncService({
    required PendingSubmitQueue pendingQueue,
    required ConnectivityService connectivity,
  })  : _pendingQueue = pendingQueue,
        _connectivity = connectivity;

  final PendingSubmitQueue _pendingQueue;
  final ConnectivityService _connectivity;

  Future<OfflineSyncResult> syncPendingSubmits(MockPortalRepository repository) async {
    final status = await _connectivity.currentStatus();
    if (!status.isOnline) {
      return const OfflineSyncResult(syncedCount: 0, failedCount: 0);
    }

    final pending = _pendingQueue.listPending();
    var synced = 0;
    var failed = 0;

    for (final item in pending) {
      try {
        await repository.submitAttempt(
          attemptId: item.attemptId,
          answers: item.answers,
          durationSeconds: item.durationSeconds,
        );
        await _pendingQueue.remove(item.id);
        synced++;
      } catch (_) {
        failed++;
        break;
      }
    }

    return OfflineSyncResult(syncedCount: synced, failedCount: failed);
  }
}

final offlinePracticeCacheProvider = Provider<OfflinePracticeCache>((ref) {
  return OfflinePracticeCache();
});

final examSessionStoreProvider = Provider<ExamSessionStore>((ref) {
  return ExamSessionStore();
});

final pendingSubmitQueueProvider = Provider<PendingSubmitQueue>((ref) {
  return PendingSubmitQueue();
});

final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  return OfflineSyncService(
    pendingQueue: ref.watch(pendingSubmitQueueProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
});

final pendingSubmitCountProvider = Provider<int>((ref) {
  return ref.watch(pendingSubmitQueueProvider).count;
});

final savedExamSessionProvider = Provider<SavedExamSession?>((ref) {
  return ref.watch(examSessionStoreProvider).getActiveSession();
});

final offlineSubjectsProvider = Provider<List<OfflineSubjectCache>>((ref) {
  return ref.watch(offlinePracticeCacheProvider).listSubjects();
});
