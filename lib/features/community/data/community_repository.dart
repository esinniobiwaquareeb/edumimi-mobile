import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mock_mobile/core/constants/api_paths.dart';
import 'package:mock_mobile/core/network/dio_client.dart';
import 'package:mock_mobile/shared/models/community.dart';

class CommunityRepository {
  CommunityRepository(this._dio);

  final Dio _dio;

  Future<List<CommunityRoom>> fetchRooms() {
    return _dio.getData(
      ApiPaths.communityRooms,
      parser: (json) {
        if (json is! List) {
          return <CommunityRoom>[];
        }
        return json.whereType<Map<String, dynamic>>().map(CommunityRoom.fromJson).toList();
      },
    );
  }

  Future<({List<CommunityMessage> messages, bool hasMore})> fetchMessages(
    String roomId, {
    String? before,
    int limit = 30,
  }) {
    return _dio.getData(
      ApiPaths.communityMessages(roomId),
      queryParameters: {
        'limit': limit.toString(),
        if (before != null && before.isNotEmpty) 'before': before,
      },
      parser: (json) {
        final map = json as Map<String, dynamic>? ?? {};
        final messagesRaw = map['messages'];
        final messages = messagesRaw is List
            ? messagesRaw.whereType<Map<String, dynamic>>().map(CommunityMessage.fromJson).toList()
            : <CommunityMessage>[];
        return (messages: messages, hasMore: map['hasMore'] == true);
      },
    );
  }

  Future<void> joinRoom(String roomId) {
    return _dio.postData(ApiPaths.communityJoin(roomId), data: const {}, parser: (_) {});
  }

  Future<void> markRoomRead(String roomId) {
    return _dio.postData(ApiPaths.communityRead(roomId), data: const {}, parser: (_) {});
  }

  Future<void> reportMessage(String messageId, String reason) {
    return _dio.postData(
      ApiPaths.communityReport(messageId),
      data: {'reason': reason},
      parser: (_) {},
    );
  }

  Future<String> updateDisplayName(String displayName) {
    return _dio.patchData(
      ApiPaths.communityDisplayName,
      data: {'displayName': displayName},
      parser: (json) => (json as Map<String, dynamic>? ?? {})['displayName']?.toString() ?? displayName,
    );
  }
}

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(ref.watch(dioProvider));
});

final communityRoomsProvider = FutureProvider.autoDispose<List<CommunityRoom>>((ref) {
  return ref.watch(communityRepositoryProvider).fetchRooms();
});
