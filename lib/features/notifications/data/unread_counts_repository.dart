import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mock_mobile/core/constants/api_paths.dart';
import 'package:mock_mobile/core/network/dio_client.dart';
import 'package:mock_mobile/shared/models/mock_unread_summary.dart';

class UnreadCountsRepository {
  UnreadCountsRepository(this._dio);

  final Dio _dio;

  Future<MockUnreadSummary> fetchSummary() {
    return _dio.getData(
      ApiPaths.unreadSummary,
      parser: (json) => MockUnreadSummary.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> markAllAsRead() {
    return _dio.postData(
      ApiPaths.notificationsMarkAllRead,
      data: const {},
      parser: (_) {},
    );
  }
}

final unreadCountsRepositoryProvider = Provider<UnreadCountsRepository>((ref) {
  return UnreadCountsRepository(ref.watch(dioProvider));
});

final unreadSummaryProvider = FutureProvider<MockUnreadSummary>((ref) {
  final keepAliveLink = ref.keepAlive();
  final timer = Timer.periodic(const Duration(seconds: 30), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() {
    timer.cancel();
    keepAliveLink.close();
  });
  return ref.watch(unreadCountsRepositoryProvider).fetchSummary();
});

void invalidateUnreadSummary(WidgetRef ref) {
  ref.invalidate(unreadSummaryProvider);
}

void invalidateUnreadSummaryFromRef(Ref ref) {
  ref.invalidate(unreadSummaryProvider);
}
