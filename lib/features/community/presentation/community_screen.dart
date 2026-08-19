import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mock_mobile/core/network/api_exception.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/auth/providers/auth_providers.dart';
import 'package:mock_mobile/features/community/data/community_repository.dart';
import 'package:mock_mobile/features/community/data/community_socket_service.dart';
import 'package:mock_mobile/shared/models/community.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  CommunityRoom? _selectedRoom;
  final _messages = <CommunityMessage>[];
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  var _isSending = false;
  var _hasMore = false;
  CommunityPresence? _presence;
  StreamSubscription<CommunityMessage>? _messageSub;
  StreamSubscription<dynamic>? _reactionSub;
  StreamSubscription<CommunityPresence>? _presenceSub;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageSub?.cancel();
    _reactionSub?.cancel();
    _presenceSub?.cancel();
    super.dispose();
  }

  Future<void> _selectRoom(CommunityRoom room) async {
    setState(() {
      _selectedRoom = room;
      _messages.clear();
      _hasMore = false;
      _presence = null;
    });

    final socket = ref.read(communitySocketServiceProvider);
    await socket.connect();
    socket.joinRoom(room.id);
    await ref.read(communityRepositoryProvider).joinRoom(room.id);
    await _loadMessages(room.id);
    await ref.read(communityRepositoryProvider).markRoomRead(room.id);

    _messageSub?.cancel();
    _reactionSub?.cancel();
    _presenceSub?.cancel();

    _messageSub = socket.messages.listen((message) {
      if (message.roomId != room.id) {
        return;
      }
      setState(() {
        final existingIndex = _messages.indexWhere(
          (item) => item.clientNonce != null && item.clientNonce == message.clientNonce,
        );
        if (existingIndex >= 0) {
          _messages[existingIndex] = message;
        } else if (!_messages.any((item) => item.id == message.id)) {
          _messages.add(message);
        }
      });
      _scrollToBottom();
    });

    _reactionSub = socket.reactions.listen((payload) {
      if (payload.roomId != room.id) {
        return;
      }
      setState(() {
        final index = _messages.indexWhere((item) => item.id == payload.messageId);
        if (index >= 0) {
          _messages[index] = _messages[index].copyWith(reactions: payload.reactions);
        }
      });
    });

    _presenceSub = socket.presence.listen((presence) {
      if (presence.roomId != room.id) {
        return;
      }
      setState(() => _presence = presence);
    });
  }

  Future<void> _loadMessages(String roomId, {bool loadOlder = false}) async {
    final before = loadOlder && _messages.isNotEmpty ? _messages.first.id : null;
    final page = await ref.read(communityRepositoryProvider).fetchMessages(roomId, before: before);
    setState(() {
      _hasMore = page.hasMore;
      if (loadOlder) {
        _messages.insertAll(0, page.messages);
      } else {
        _messages
          ..clear()
          ..addAll(page.messages);
      }
    });
    if (!loadOlder) {
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    final room = _selectedRoom;
    final content = _messageController.text.trim();
    if (room == null || content.isEmpty || _isSending) {
      return;
    }

    final user = ref.read(authControllerProvider).user;
    final clientNonce = DateTime.now().microsecondsSinceEpoch.toString();
    final optimistic = CommunityMessage(
      id: clientNonce,
      roomId: room.id,
      senderId: user?.id ?? '',
      senderDisplayName: user?.displayName ?? 'You',
      content: content,
      createdAt: DateTime.now().toIso8601String(),
      isOwn: true,
      pending: true,
      clientNonce: clientNonce,
    );

    setState(() {
      _isSending = true;
      _messages.add(optimistic);
      _messageController.clear();
    });
    _scrollToBottom();

    try {
      await ref.read(communitySocketServiceProvider).sendMessage(
            roomId: room.id,
            content: content,
            clientNonce: clientNonce,
          );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final roomsAsync = ref.watch(communityRoomsProvider);
    final isVerified = user?.mockProfile?.isVerified == true;

    if (!isVerified) {
      return Scaffold(
        appBar: AppBar(title: const Text('Study Squad')),
        body: const MockEmptyState(
          title: 'Verify your email first',
          message: 'Community chat is available after you verify your mock.edumimi account.',
        ),
      );
    }

    if (_selectedRoom == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Study Squad')),
        body: roomsAsync.when(
          loading: () => const MockLoadingView(message: 'Loading rooms…'),
          error: (error, _) => MockErrorView(message: error.toString(), onRetry: () => ref.invalidate(communityRoomsProvider)),
          data: (rooms) => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final room = rooms[index];
              return MockCard(
                child: ListTile(
                  leading: Text(room.emoji ?? '💬', style: const TextStyle(fontSize: 24)),
                  title: Text(room.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(room.description ?? room.type, style: const TextStyle(color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectRoom(room),
                ),
              );
            },
          ),
        ),
      );
    }

    final room = _selectedRoom!;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${room.emoji ?? '💬'} ${room.name}'),
            if (_presence != null)
              Text(
                '${_presence!.onlineCount} online',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(communitySocketServiceProvider).leaveRoom(room.id);
            setState(() => _selectedRoom = null);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (_hasMore && index == 0) {
                  return TextButton(
                    onPressed: () => _loadMessages(room.id, loadOlder: true),
                    child: const Text('Load older messages'),
                  );
                }
                final messageIndex = _hasMore ? index - 1 : index;
                final message = _messages[messageIndex];
                return _MessageBubble(
                  message: message,
                  onReact: (emoji) => ref.read(communitySocketServiceProvider).toggleReaction(message.id, emoji),
                );
              },
            ),
          ),
          if (_presence != null && _presence!.typingUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_presence!.typingUsers.take(2).join(', ')} typing…',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(hintText: 'Say something helpful…'),
                      onChanged: (value) {
                        ref.read(communitySocketServiceProvider).setTyping(
                              room.id,
                              user?.displayName ?? 'Student',
                              value.trim().isNotEmpty,
                            );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.onReact});

  final CommunityMessage message;
  final ValueChanged<String> onReact;

  @override
  Widget build(BuildContext context) {
    final time = DateTime.tryParse(message.createdAt);
    final formattedTime = time == null ? '' : DateFormat.jm().format(time.toLocal());

    return Align(
      alignment: message.isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        decoration: BoxDecoration(
          color: message.isOwn ? AppColors.primarySoft : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.senderDisplayName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            const SizedBox(height: 4),
            Text(message.content),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(formattedTime, style: const TextStyle(color: AppColors.textDisabled, fontSize: 11)),
                if (message.pending) ...[
                  const SizedBox(width: 8),
                  const Text('Sending…', style: TextStyle(color: AppColors.textDisabled, fontSize: 11)),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              children: communityReactions
                  .map(
                    (emoji) => InkWell(
                      onTap: () => onReact(emoji),
                      child: Text(
                        '$emoji${message.reactions[emoji]?.isNotEmpty == true ? ' ${message.reactions[emoji]!.length}' : ''}',
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
