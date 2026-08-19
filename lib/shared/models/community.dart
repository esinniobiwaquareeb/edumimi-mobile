import 'package:equatable/equatable.dart';

class CommunityRoom extends Equatable {
  const CommunityRoom({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    this.emoji,
    required this.type,
  });

  factory CommunityRoom.fromJson(Map<String, dynamic> json) {
    return CommunityRoom(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Room',
      description: json['description']?.toString(),
      emoji: json['emoji']?.toString(),
      type: json['type']?.toString() ?? 'GENERAL',
    );
  }

  final String id;
  final String slug;
  final String name;
  final String? description;
  final String? emoji;
  final String type;

  @override
  List<Object?> get props => [id, slug];
}

class CommunityMessage extends Equatable {
  const CommunityMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderDisplayName,
    required this.content,
    required this.createdAt,
    this.reactions = const {},
    this.isOwn = false,
    this.pending = false,
    this.clientNonce,
  });

  factory CommunityMessage.fromJson(Map<String, dynamic> json) {
    final reactionsRaw = json['reactions'];
    final reactions = <String, List<String>>{};
    if (reactionsRaw is Map) {
      reactionsRaw.forEach((key, value) {
        if (value is List) {
          reactions[key.toString()] = value.map((item) => item.toString()).toList();
        }
      });
    }

    return CommunityMessage(
      id: json['id']?.toString() ?? '',
      roomId: json['roomId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderDisplayName: json['senderDisplayName']?.toString() ?? 'Student',
      content: json['content']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      reactions: reactions,
      isOwn: json['isOwn'] == true,
      pending: json['pending'] == true,
      clientNonce: json['clientNonce']?.toString(),
    );
  }

  CommunityMessage copyWith({
    String? id,
    bool? pending,
    Map<String, List<String>>? reactions,
    bool? isOwn,
  }) {
    return CommunityMessage(
      id: id ?? this.id,
      roomId: roomId,
      senderId: senderId,
      senderDisplayName: senderDisplayName,
      content: content,
      createdAt: createdAt,
      reactions: reactions ?? this.reactions,
      isOwn: isOwn ?? this.isOwn,
      pending: pending ?? this.pending,
      clientNonce: clientNonce,
    );
  }

  final String id;
  final String roomId;
  final String senderId;
  final String senderDisplayName;
  final String content;
  final String createdAt;
  final Map<String, List<String>> reactions;
  final bool isOwn;
  final bool pending;
  final String? clientNonce;

  @override
  List<Object?> get props => [id, roomId, content, createdAt, pending];
}

class CommunityPresence extends Equatable {
  const CommunityPresence({
    required this.roomId,
    required this.onlineCount,
    required this.typingUsers,
  });

  factory CommunityPresence.fromJson(Map<String, dynamic> json) {
    final typing = json['typingUsers'];
    return CommunityPresence(
      roomId: json['roomId']?.toString() ?? '',
      onlineCount: json['onlineCount'] is num ? (json['onlineCount'] as num).toInt() : 0,
      typingUsers: typing is List ? typing.map((item) => item.toString()).toList() : const [],
    );
  }

  final String roomId;
  final int onlineCount;
  final List<String> typingUsers;

  @override
  List<Object?> get props => [roomId, onlineCount, typingUsers];
}

const communityReactions = ['🔥', '💯', '😂', '👀', '🙌', '❤️'];
