import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mock_mobile/core/constants/api_paths.dart';
import 'package:mock_mobile/core/network/dio_client.dart';
import 'package:mock_mobile/shared/models/mock_notification.dart';

class NotificationsRepository {
  NotificationsRepository(this._dio);

  final Dio _dio;

  Future<List<MockNotification>> fetchNotifications({bool unreadOnly = false}) {
    return _dio.getData(
      ApiPaths.notifications,
      queryParameters: unreadOnly ? const {'unreadOnly': 'true'} : null,
      parser: (json) {
        if (json is! List) {
          return <MockNotification>[];
        }
        return json
            .whereType<Map<String, dynamic>>()
            .map(MockNotification.fromJson)
            .toList();
      },
    );
  }

  Future<void> markAsRead(String notificationId) {
    return _dio.patchData(
      ApiPaths.notificationRead(notificationId),
      data: const {},
      parser: (_) {},
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

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepository(ref.watch(dioProvider));
});

final notificationsProvider =
    FutureProvider.autoDispose<List<MockNotification>>((ref) {
      return ref.watch(notificationsRepositoryProvider).fetchNotifications();
    });

final unreadNotificationsProvider =
    FutureProvider.autoDispose<List<MockNotification>>((ref) {
      return ref
          .watch(notificationsRepositoryProvider)
          .fetchNotifications(unreadOnly: true);
    });

void invalidateNotifications(WidgetRef ref) {
  ref.invalidate(notificationsProvider);
  ref.invalidate(unreadNotificationsProvider);
}

void invalidateNotificationsFromRef(Ref ref) {
  ref.invalidate(notificationsProvider);
  ref.invalidate(unreadNotificationsProvider);
}
