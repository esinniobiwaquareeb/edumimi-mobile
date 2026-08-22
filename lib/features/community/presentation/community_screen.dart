import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mock_mobile/core/network/api_exception.dart';
import 'package:mock_mobile/core/theme/theme_context.dart';
import 'package:mock_mobile/core/theme/app_icons.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/auth/providers/auth_providers.dart';
import 'package:mock_mobile/features/community/data/community_repository.dart';
import 'package:mock_mobile/features/community/data/community_socket_service.dart';
import 'package:mock_mobile/features/notifications/data/unread_counts_repository.dart';
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
  var _isLoadingMessages = false;
  CommunityPresence? _presence;
  CommunityConnectionState _connectionState = CommunityConnectionState.disconnected;
  StreamSubscription<CommunityMessage>? _messageSub;
  StreamSubscription<dynamic>? _reactionSub;
  StreamSubscription<CommunityPresence>? _presenceSub;
  StreamSubscription<CommunityConnectionState>? _connectionSub;
  Timer? _restPollTimer;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageSub?.cancel();
    _reactionSub?.cancel();
    _presenceSub?.cancel();
    _connectionSub?.cancel();
    _restPollTimer?.cancel();
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
    invalidateUnreadSummary(ref);
    ref.invalidate(communityRoomsProvider);

    _messageSub?.cancel();
    _reactionSub?.cancel();
    _presenceSub?.cancel();
    _connectionSub?.cancel();

    _connectionSub = socket.connectionState.listen((state) {
      if (!mounted) {
        return;
      }
      setState(() => _connectionState = state);
      if (state == CommunityConnectionState.connected) {
        socket.joinRoom(room.id);
        _restPollTimer?.cancel();
      } else if (state == CommunityConnectionState.disconnected ||
          state == CommunityConnectionState.error) {
        _startRestPolling(room.id);
      }
    });
    setState(() => _connectionState = socket.currentState);

    _messageSub = socket.messages.listen((message) {
      if (message.roomId != room.id) {
        invalidateUnreadSummary(ref);
        ref.invalidate(communityRoomsProvider);
        return;
      }
      if (!message.isOwn) {
        ref.read(communityRepositoryProvider).markRoomRead(room.id).then((_) {
          invalidateUnreadSummary(ref);
          ref.invalidate(communityRoomsProvider);
        });
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

    if (!socket.isConnected) {
      _startRestPolling(room.id);
    }
  }

  void _startRestPolling(String roomId) {
    _restPollTimer?.cancel();
    _restPollTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      final socket = ref.read(communitySocketServiceProvider);
      if (socket.isConnected || !mounted || _selectedRoom?.id != roomId) {
        return;
      }
      await _loadMessages(roomId);
    });
  }

  Future<void> _loadMessages(String roomId, {bool loadOlder = false}) async {
    if (_isLoadingMessages && !loadOlder) {
      return;
    }
    setState(() => _isLoadingMessages = true);
    try {
      final before = loadOlder && _messages.isNotEmpty ? _messages.first.id : null;
      final page = await ref.read(communityRepositoryProvider).fetchMessages(roomId, before: before);
      if (!mounted) {
        return;
      }
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
    } on ApiException catch (error) {
      if (mounted && _messages.isEmpty) {
        MockToast.error(context, error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMessages = false);
      }
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
      final socket = ref.read(communitySocketServiceProvider);
      if (!socket.isConnected) {
        await socket.retryConnection();
      }
      await socket.sendMessage(
        roomId: room.id,
        content: content,
        clientNonce: clientNonce,
      );
    } on ApiException catch (error) {
      _removeOptimisticMessage(clientNonce);
      if (mounted) {
        MockToast.error(context, error.message);
      }
    } catch (error) {
      _removeOptimisticMessage(clientNonce);
      if (mounted) {
        MockToast.error(context, 'Could not send message. Check your connection.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _removeOptimisticMessage(String clientNonce) {
    setState(() {
      _messages.removeWhere((item) => item.clientNonce == clientNonce);
    });
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

  Future<void> _retryConnection() async {
    final room = _selectedRoom;
    if (room == null) {
      return;
    }
    await ref.read(communitySocketServiceProvider).retryConnection();
    await ref.read(communityRepositoryProvider).joinRoom(room.id);
    await _loadMessages(room.id);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final roomsAsync = ref.watch(communityRoomsProvider);
    final isVerified = user?.mockProfile?.isVerified == true;

    if (!isVerified) {
      return Scaffold(
        appBar: const MockDetailAppBar(title: 'Study Squad'),
        body: const MockEmptyState(
          title: 'Verify your email first',
          message: 'Community chat is available after you verify your mock.edumimi account.',
        ),
      );
    }

    if (_selectedRoom == null) {
      return Scaffold(
        appBar: const MockDetailAppBar(title: 'Study Squad'),
        body: roomsAsync.when(
          loading: () => const MockLoadingView(message: 'Loading rooms…'),
          error: (error, _) => MockErrorView(
            message: error is ApiException ? error.message : 'Could not load chat rooms. Check your connection.',
            onRetry: () => ref.invalidate(communityRoomsProvider),
          ),
          data: (rooms) {
            if (rooms.isEmpty) {
              return const MockEmptyState(
                title: 'No study rooms yet',
                message: 'Chat rooms will appear here once your school sets them up. Pull down to refresh.',
              );
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(communityRoomsProvider),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.page),
                itemCount: rooms.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.section),
                itemBuilder: (context, index) {
                  final room = rooms[index];
                  return MockCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: context.appNeutralSoft,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: context.appBorder),
                        ),
                        child: Text(room.emoji ?? '💬', style: const TextStyle(fontSize: 22)),
                      ),
                      title: Text(room.name, style: context.cardTitle),
                      subtitle: Text(room.description ?? room.type, style: context.bodySecondary),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (room.unreadCount > 0) ...[
                            MockCountBadge(count: room.unreadCount),
                            const SizedBox(width: AppSpacing.item),
                          ],
                          MockLongArrowIcon(
                            direction: MockLongArrowDirection.right,
                            size: AppIcons.forwardSize,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
                          ),
                        ],
                      ),
                      onTap: () => _selectRoom(room),
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
    }

    final room = _selectedRoom!;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${room.emoji ?? '💬'} ${room.name}', style: context.cardTitle),
            if (_presence != null)
              Text(
                '${_presence!.onlineCount} online',
                style: context.caption,
              ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_connectionState == CommunityConnectionState.connected ? 0.5 : 36),
          child: Column(
            children: [
              if (_connectionState != CommunityConnectionState.connected)
                _ConnectionBanner(
                  state: _connectionState,
                  onRetry: _retryConnection,
                ),
              Container(height: 0.5, color: context.appBorder),
            ],
          ),
        ),
        leading: MockBackButton(
          onPressed: () {
            _restPollTimer?.cancel();
            ref.read(communitySocketServiceProvider).leaveRoom(room.id);
            setState(() => _selectedRoom = null);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingMessages && _messages.isEmpty
                ? const MockLoadingView(message: 'Loading messages…')
                : _messages.isEmpty
                    ? MockEmptyState(
                        title: 'No messages yet',
                        message: _connectionState == CommunityConnectionState.connected
                            ? 'Be the first to say hello in this room.'
                            : 'Message history loads over REST. Live chat reconnects automatically.',
                        actionLabel: _connectionState != CommunityConnectionState.connected ? 'Retry connection' : null,
                        onAction: _connectionState != CommunityConnectionState.connected ? _retryConnection : null,
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(AppSpacing.page),
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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: AppSpacing.item),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_presence!.typingUsers.take(2).join(', ')} typing…',
                  style: context.caption,
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                color: context.colors.surface,
                border: Border(top: BorderSide(color: context.appBorder)),
              ),
              padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.item, AppSpacing.page, AppSpacing.page),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: _connectionState == CommunityConnectionState.connected
                            ? 'Say something helpful…'
                            : 'Reconnecting to live chat…',
                      ),
                      onChanged: (value) {
                        if (_connectionState != CommunityConnectionState.connected) {
                          return;
                        }
                        ref.read(communitySocketServiceProvider).setTyping(
                              room.id,
                              user?.displayName ?? 'Student',
                              value.trim().isNotEmpty,
                            );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.item),
                  IconButton(
                    onPressed: (_isSending || _connectionState != CommunityConnectionState.connected) ? null : _sendMessage,
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

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.state, required this.onRetry});

  final CommunityConnectionState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      CommunityConnectionState.connecting => ('Connecting to live chat…', Colors.orange.shade700),
      CommunityConnectionState.reconnecting => ('Reconnecting… showing cached messages', Colors.orange.shade700),
      CommunityConnectionState.error => ('Live chat unavailable', Colors.red.shade700),
      CommunityConnectionState.disconnected => ('Offline — messages refresh every 20s', Colors.grey.shade700),
      CommunityConnectionState.connected => ('', Colors.transparent),
    };

    if (label.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      color: color.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text(label, style: context.caption.copyWith(color: color))),
            if (state == CommunityConnectionState.error || state == CommunityConnectionState.disconnected)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
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
    final theme = Theme.of(context);

    return Align(
      alignment: message.isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.section),
        padding: const EdgeInsets.all(AppSpacing.section),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        decoration: BoxDecoration(
          color: message.isOwn ? context.appNeutralSoft : context.colors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.senderDisplayName, style: context.caption.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.item),
            Text(message.content, style: context.body),
            const SizedBox(height: AppSpacing.item),
            Row(
              children: [
                Text(formattedTime, style: context.caption),
                if (message.pending) ...[
                  const SizedBox(width: AppSpacing.item),
                  Text('Sending…', style: context.caption),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.item),
            Wrap(
              spacing: 4,
              children: communityReactions
                  .map(
                    (emoji) => InkWell(
                      onTap: () => onReact(emoji),
                      child: Text(
                        '$emoji${message.reactions[emoji]?.isNotEmpty == true ? ' ${message.reactions[emoji]!.length}' : ''}',
                        style: context.bodySecondary.copyWith(fontSize: 14),
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
