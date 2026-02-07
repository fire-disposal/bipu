import 'package:flutter/material.dart';
import 'package:flutter_user/api/api.dart';
import 'package:flutter_user/models/message/message_response.dart';
import 'package:flutter_user/models/common/enums.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/services/auth_service.dart';

class ConversationListPage extends StatefulWidget {
  const ConversationListPage({super.key});

  @override
  State<ConversationListPage> createState() => _ConversationListPageState();
}

class _ConversationListPageState extends State<ConversationListPage>
    with SingleTickerProviderStateMixin {
  final ApiService _api = bipupuApi;
  List<MessageResponse> _receivedMessages = [];
  List<MessageResponse> _sentMessages = [];
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMessages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (AuthService().isGuest) return;

    setState(() => _isLoading = true);
    try {
      // 并发请求两个接口
      final results = await Future.wait([
        _api.getReceivedMessages(page: 1, size: 50),
        _api.getSentMessages(page: 1, size: 50),
      ]);

      setState(() {
        _receivedMessages = _groupMessages(results[0], bySender: true);
        _sentMessages = _groupMessages(results[1], bySender: false);
      });
    } catch (e) {
      debugPrint('Error loading messages: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<MessageResponse> _groupMessages(
    List<MessageResponse> messages, {
    required bool bySender,
  }) {
    final Map<int, MessageResponse> conversations = {};
    for (var msg in messages) {
      final targetId = bySender ? msg.senderId : msg.receiverId;
      if (!conversations.containsKey(targetId)) {
        conversations[targetId] = msg;
      }
    }
    return conversations.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    if (AuthService().isGuest) {
      return _buildGuestView();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '消息列表',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: '收到消息'),
            Tab(text: '已发消息'),
          ],
        ),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RefreshIndicator(
            onRefresh: _loadMessages,
            child: _buildMessageList(_receivedMessages, isReceived: true),
          ),
          RefreshIndicator(
            onRefresh: _loadMessages,
            child: _buildMessageList(_sentMessages, isReceived: false),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/contacts');
        },
        label: const Text('新消息'),
        icon: const Icon(Icons.edit_outlined),
      ),
    );
  }

  Widget _buildMessageList(
    List<MessageResponse> messages, {
    required bool isReceived,
  }) {
    if (_isLoading && messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isReceived ? Icons.inbox_outlined : Icons.send_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无${isReceived ? '收到的' : '发送的'}消息',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length,
      separatorBuilder: (_, __) => const Divider(indent: 72, height: 1),
      itemBuilder: (context, index) {
        final message = messages[index];
        final targetId = isReceived ? message.senderId : message.receiverId;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Hero(
            tag: 'avatar_$targetId',
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                'U',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  '用户 $targetId',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                _formatTime(message.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                if (message.messageType == MessageType.device)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.sensors,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                Expanded(
                  child: Text(
                    message.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                if (isReceived && !message.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
          onTap: () {
            context.push('/chat/$targetId');
          },
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(time);
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(time);
    } else {
      return DateFormat('MM/dd').format(time);
    }
  }

  Widget _buildGuestView() {
    return Scaffold(
      appBar: AppBar(title: const Text('消息 (访客)')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('访客模式 - 暂不可使用在线翻译'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/bluetooth'),
              child: const Text('前往蓝牙聊天'),
            ),
          ],
        ),
      ),
    );
  }
}
