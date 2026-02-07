import 'package:flutter/material.dart';
import 'package:flutter_user/api/api.dart';
import 'package:flutter_user/models/message/message_response.dart';
import 'package:flutter_user/models/user/user_response.dart';
import 'package:flutter_user/models/message/message_request.dart';
import 'package:flutter_user/models/common/enums.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';

class ChatPage extends StatefulWidget {
  final int userId;

  const ChatPage({super.key, required this.userId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _api = bipupuApi;

  List<MessageResponse> _messages = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  UserResponse? _peerUser;
  final int _currentUserId = AuthService().currentUser?.id ?? 0;

  @override
  void initState() {
    super.initState();
    _loadPeerInfo();
    _loadMessages();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadPeerInfo() async {
    try {
      final user = await _api.adminGetUser(widget.userId);
      if (mounted) {
        setState(() {
          _peerUser = user;
        });
      }
    } catch (e) {
      debugPrint('Error loading peer info: $e');
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.getConversationMessages(
        widget.userId,
        page: 1,
        size: 20,
      );

      final items = response.items;
      items.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      setState(() {
        _messages = items;
        _currentPage = 1;
        _hasMore = items.length >= 20;
      });

      _scrollToBottom();
      _markMessagesAsRead(items);
    } catch (e) {
      debugPrint('Error loading chat: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markMessagesAsRead(List<MessageResponse> messages) async {
    for (var msg in messages) {
      if (msg.receiverId == _currentUserId && !msg.isRead) {
        try {
          await _api.markMessageAsRead(msg.id);
        } catch (e) {
          debugPrint('Error marking message as read: $e');
        }
      }
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final response = await _api.getConversationMessages(
        widget.userId,
        page: _currentPage + 1,
        size: 20,
      );

      if (response.items.isEmpty) {
        setState(() => _hasMore = false);
      } else {
        final newItems = response.items;
        newItems.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        setState(() {
          _messages.insertAll(0, newItems);
          _currentPage++;
          _hasMore = newItems.length >= 20;
        });
      }
    } catch (e) {
      debugPrint('Error loading more: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    final content = _textController.text;
    _textController.clear();

    try {
      final newMessage = await _api.sendMessage(
        MessageCreateRequest(
          title: 'Bipupu Chat',
          content: content,
          receiverId: widget.userId,
          messageType: MessageType.user,
          priority: 0,
        ),
      );

      setState(() {
        _messages.add(newMessage);
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('发送失�? $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Row(
          children: [
            Hero(
              tag: 'avatar_${widget.userId}',
              child: _buildAvatar(widget.userId, radius: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _peerUser?.nickname ??
                        _peerUser?.username ??
                        '用户 ${widget.userId}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '在线',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call_outlined), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => context.push('/user/detail/${widget.userId}'),
          ),
        ],
      ),
      body: _isLoading && _messages.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: _messages.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0 && _isLoadingMore) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      final msgIdx = _isLoadingMore ? index - 1 : index;
                      final msg = _messages[msgIdx];
                      final isMe = msg.senderId == _currentUserId;
                      final showTime =
                          msgIdx == 0 ||
                          msg.createdAt
                                  .difference(_messages[msgIdx - 1].createdAt)
                                  .inMinutes >
                              5;

                      return Column(
                        children: [
                          if (showTime)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                _formatMessageTime(msg.createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ),
                          _buildMessageBubble(msg, isMe),
                        ],
                      );
                    },
                  ),
                ),
                _buildTextComposer(),
              ],
            ),
    );
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final localTime = time.toLocal();
    if (now.difference(localTime).inDays == 0) {
      return DateFormat('HH:mm').format(localTime);
    }
    return DateFormat('MM-dd HH:mm').format(localTime);
  }

  Widget _buildAvatar(int userId, {double radius = 20}) {
    final user = userId == _currentUserId
        ? AuthService().currentUser
        : _peerUser;
    final avatarUrl = user?.avatarUrl;

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      backgroundImage: avatarUrl != null
          ? CachedNetworkImageProvider(
              avatarUrl.startsWith('http')
                  ? avatarUrl
                  : '${bipupuHttp.options.baseUrl}$avatarUrl',
            )
          : null,
      child: avatarUrl == null
          ? Text(
              (user?.nickname ?? user?.username ?? '?')
                  .substring(0, 1)
                  .toUpperCase(),
              style: TextStyle(fontSize: radius * 0.8),
            )
          : null,
    );
  }

  Widget _buildMessageBubble(MessageResponse msg, bool isMe) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDevice = msg.messageType == MessageType.device;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            _buildAvatar(msg.senderId, radius: 18),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? colorScheme.primary
                        : (isDevice
                              ? colorScheme.secondaryContainer
                              : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isDevice)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sensors,
                                size: 12,
                                color: isMe
                                    ? Colors.white70
                                    : colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '传唤信号',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe
                                      ? Colors.white70
                                      : colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        msg.content,
                        style: TextStyle(
                          color: isMe
                              ? Colors.white
                              : (isDevice
                                    ? colorScheme.onSecondaryContainer
                                    : Colors.black87),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            _buildAvatar(msg.senderId, radius: 18),
          ],
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {},
            color: Colors.grey[600],
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: '发送消�?..',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onSubmitted: _handleSubmitted,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _handleSubmitted(_textController.text),
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
