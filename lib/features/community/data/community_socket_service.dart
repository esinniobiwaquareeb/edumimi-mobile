import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mock_mobile/core/config/app_config.dart';
import 'package:mock_mobile/core/storage/auth_storage.dart';
import 'package:mock_mobile/shared/models/community.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

enum CommunityConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class CommunitySocketService {
  CommunitySocketService(this._authStorage);

  final AuthStorage _authStorage;
  io.Socket? _socket;
  final _messageController = StreamController<CommunityMessage>.broadcast();
  final _reactionController = StreamController<({String messageId, String roomId, Map<String, List<String>> reactions})>.broadcast();
  final _presenceController = StreamController<CommunityPresence>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _connectionStateController = StreamController<CommunityConnectionState>.broadcast();

  Stream<CommunityMessage> get messages => _messageController.stream;
  Stream<({String messageId, String roomId, Map<String, List<String>> reactions})> get reactions =>
      _reactionController.stream;
  Stream<CommunityPresence> get presence => _presenceController.stream;
  Stream<bool> get connection => _connectionController.stream;
  Stream<CommunityConnectionState> get connectionState => _connectionStateController.stream;

  CommunityConnectionState _state = CommunityConnectionState.disconnected;
  String? _activeRoomId;
  Timer? _reconnectTimer;
  var _reconnectAttempt = 0;
  var _shouldStayConnected = false;

  bool get isConnected => _socket?.connected ?? false;
  CommunityConnectionState get currentState => _state;

  Future<void> connect() async {
    if (_state == CommunityConnectionState.connected ||
        _state == CommunityConnectionState.connecting ||
        _state == CommunityConnectionState.reconnecting) {
      return;
    }

    final token = await _authStorage.readToken();
    if (token == null || token.isEmpty) {
      _setState(CommunityConnectionState.disconnected);
      return;
    }

    _shouldStayConnected = true;
    _setState(
      _reconnectAttempt > 0 ? CommunityConnectionState.reconnecting : CommunityConnectionState.connecting,
    );

    _socket?.dispose();
    _socket = io.io(
      '${AppConfig.apiBaseUrl}/mock-community',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .setAuth({'token': token})
          .build(),
    );

    _socket!
      ..onConnect((_) {
        _reconnectAttempt = 0;
        _reconnectTimer?.cancel();
        _setState(CommunityConnectionState.connected);
        if (_activeRoomId != null) {
          _socket?.emit('joinRoom', {'roomId': _activeRoomId});
        }
      })
      ..onDisconnect((_) {
        _setState(CommunityConnectionState.disconnected);
        _scheduleReconnect();
      })
      ..onConnectError((_) {
        _setState(CommunityConnectionState.error);
        _scheduleReconnect();
      })
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
    _shouldStayConnected = false;
    _reconnectTimer?.cancel();
    _reconnectAttempt = 0;
    _activeRoomId = null;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _setState(CommunityConnectionState.disconnected);
  }

  void joinRoom(String roomId) {
    _activeRoomId = roomId;
    _socket?.emit('joinRoom', {'roomId': roomId});
  }

  void leaveRoom(String roomId) {
    if (_activeRoomId == roomId) {
      _activeRoomId = null;
    }
    _socket?.emit('leaveRoom', {'roomId': roomId});
  }

  Future<void> retryConnection() async {
    _reconnectAttempt = 0;
    _reconnectTimer?.cancel();
    _socket?.dispose();
    _socket = null;
    _setState(CommunityConnectionState.disconnected);
    await connect();
    if (_activeRoomId != null) {
      joinRoom(_activeRoomId!);
    }
  }

  Future<CommunityMessage?> sendMessage({
    required String roomId,
    required String content,
    String? clientNonce,
  }) async {
    final socket = _socket;
    if (socket == null || !socket.connected) {
      throw StateError('Live chat is offline. Reconnecting — try again in a moment.');
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

  void _scheduleReconnect() {
    if (!_shouldStayConnected) {
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectAttempt++;
    final delaySeconds = min(pow(2, _reconnectAttempt).toInt(), 30);
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_shouldStayConnected) {
        return;
      }
      unawaited(connect());
    });
  }

  void _setState(CommunityConnectionState state) {
    _state = state;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(state);
    }
    if (!_connectionController.isClosed) {
      _connectionController.add(state == CommunityConnectionState.connected);
    }
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _reactionController.close();
    _presenceController.close();
    _connectionController.close();
    _connectionStateController.close();
  }
}

final communitySocketServiceProvider = Provider<CommunitySocketService>((ref) {
  final service = CommunitySocketService(ref.watch(authStorageProvider));
  ref.onDispose(service.dispose);
  return service;
});
