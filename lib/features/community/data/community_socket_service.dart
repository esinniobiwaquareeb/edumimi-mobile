import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mock_mobile/core/config/app_config.dart';
import 'package:mock_mobile/core/storage/auth_storage.dart';
import 'package:mock_mobile/shared/models/community.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class CommunitySocketService {
  CommunitySocketService(this._authStorage);

  final AuthStorage _authStorage;
  io.Socket? _socket;
  final _messageController = StreamController<CommunityMessage>.broadcast();
  final _reactionController = StreamController<({String messageId, String roomId, Map<String, List<String>> reactions})>.broadcast();
  final _presenceController = StreamController<CommunityPresence>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<CommunityMessage> get messages => _messageController.stream;
  Stream<({String messageId, String roomId, Map<String, List<String>> reactions})> get reactions =>
      _reactionController.stream;
  Stream<CommunityPresence> get presence => _presenceController.stream;
  Stream<bool> get connection => _connectionController.stream;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket?.connected == true) {
      return;
    }

    final token = await _authStorage.readToken();
    if (token == null || token.isEmpty) {
      return;
    }

    _socket?.dispose();
    _socket = io.io(
      '${AppConfig.apiBaseUrl}/mock-community',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!
      ..onConnect((_) => _connectionController.add(true))
      ..onDisconnect((_) => _connectionController.add(false))
      ..on('newMessage', (data) {
        if (data is Map) {
          _messageController.add(CommunityMessage.fromJson(Map<String, dynamic>.from(data)));
        }
      })
      ..on('messageReaction', (data) {
        if (data is! Map) {
          return;
        }
        final map = Map<String, dynamic>.from(data);
        final reactionsRaw = map['reactions'];
        final reactions = <String, List<String>>{};
        if (reactionsRaw is Map) {
          reactionsRaw.forEach((key, value) {
            if (value is List) {
              reactions[key.toString()] = value.map((item) => item.toString()).toList();
            }
          });
        }
        _reactionController.add((
          messageId: map['messageId']?.toString() ?? '',
          roomId: map['roomId']?.toString() ?? '',
          reactions: reactions,
        ));
      })
      ..on('roomPresence', (data) {
        if (data is Map) {
          _presenceController.add(CommunityPresence.fromJson(Map<String, dynamic>.from(data)));
        }
      })
      ..connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connectionController.add(false);
  }

  void joinRoom(String roomId) {
    _socket?.emit('joinRoom', {'roomId': roomId});
  }

  void leaveRoom(String roomId) {
    _socket?.emit('leaveRoom', {'roomId': roomId});
  }

  Future<CommunityMessage?> sendMessage({
    required String roomId,
    required String content,
    String? clientNonce,
  }) async {
    final socket = _socket;
    if (socket == null || !socket.connected) {
      throw StateError('Chat socket is not connected');
    }

    final completer = Completer<CommunityMessage?>();
    socket.emitWithAck(
      'sendMessage',
      {
        'roomId': roomId,
        'content': content,
        if (clientNonce != null) 'clientNonce': clientNonce,
      },
      ack: (response) {
        if (response is Map && response['error'] != null) {
          completer.completeError(response['error'].toString());
          return;
        }
        if (response is Map) {
          completer.complete(CommunityMessage.fromJson(Map<String, dynamic>.from(response)));
          return;
        }
        completer.complete(null);
      },
    );
    return completer.future;
  }

  void setTyping(String roomId, String displayName, bool isTyping) {
    _socket?.emit('typing', {
      'roomId': roomId,
      'displayName': displayName,
      'isTyping': isTyping,
    });
  }

  void toggleReaction(String messageId, String emoji) {
    _socket?.emit('react', {'messageId': messageId, 'emoji': emoji});
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _reactionController.close();
    _presenceController.close();
    _connectionController.close();
  }
}

final communitySocketServiceProvider = Provider<CommunitySocketService>((ref) {
  final service = CommunitySocketService(ref.watch(authStorageProvider));
  ref.onDispose(service.dispose);
  return service;
});
