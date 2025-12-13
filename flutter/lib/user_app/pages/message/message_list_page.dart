import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/constants.dart';

class MessageListPage extends StatefulWidget {
  const MessageListPage({super.key});

  @override
  State<MessageListPage> createState() => _MessageListPageState();
}

class _MessageListPageState extends State<MessageListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // TODO: Logger.logUserAction('进入消息列表页面'); 需补充 logger 方法实现或移除
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('消息'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: 实现搜索功能
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('搜索功能开发中')));
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'export':
                  context.push('/export-print');
                  break;
                case 'settings':
                  // TODO: 跳转到消息设置
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('导出消息'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('消息设置'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            setState(() {
              _selectedTab = index;
            });
          },
          tabs: const [
            Tab(text: '已发送'),
            Tab(text: '已接收'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_SentMessagesTab(), _ReceivedMessagesTab()],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        context.push('/voice-input');
      },
      icon: const Icon(Icons.mic),
      label: Text(_selectedTab == 0 ? '发送消息' : '回复消息'),
    );
  }
}

class _SentMessagesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sentMessages = [
      MessageInfo(
        id: '1',
        content: '今天天气真好，希望你那边也是晴天',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isFavorite: true,
        recipient: '小明',
      ),
      MessageInfo(
        id: '2',
        content: '记得按时吃饭，不要太忙了',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isFavorite: false,
        recipient: '小红',
      ),
      MessageInfo(
        id: '3',
        content: '今晚的月亮很圆，想起了我们一起看月亮的那个晚上',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        isFavorite: true,
        recipient: '小李',
      ),
    ];

    if (sentMessages.isEmpty) {
      return _buildEmptyState(
        context,
        '暂无发送的消息',
        '点击右下角按钮开始发送您的第一条消息',
        Icons.send_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sentMessages.length,
      itemBuilder: (context, index) {
        final message = sentMessages[index];
        return _MessageItem(
          message: message,
          onTap: () => _handleMessageTap(context, message),
        );
      },
    );
  }
}

class _ReceivedMessagesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final receivedMessages = [
      MessageInfo(
        id: '4',
        content: '谢谢你的关心，我这边一切都好',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isFavorite: false,
        sender: '小明',
      ),
      MessageInfo(
        id: '5',
        content: '今天工作很忙，但是想到你就觉得很有动力',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isFavorite: true,
        sender: '小红',
      ),
      MessageInfo(
        id: '6',
        content: '看到你的消息很开心，保持联系',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        isFavorite: false,
        sender: '小李',
      ),
    ];

    if (receivedMessages.isEmpty) {
      return _buildEmptyState(
        context,
        '暂无接收的消息',
        '当有人给您发送消息时，会显示在这里',
        Icons.inbox_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: receivedMessages.length,
      itemBuilder: (context, index) {
        final message = receivedMessages[index];
        return _MessageItem(
          message: message,
          onTap: () => _handleMessageTap(context, message),
        );
      },
    );
  }
}

Widget _buildEmptyState(
  BuildContext context,
  String title,
  String subtitle,
  IconData icon,
) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 64,
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withAlpha((255 * 0.5).round()),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

void _handleMessageTap(BuildContext context, MessageInfo message) {
  // TODO: Logger.logUserAction('查看消息详情'); 需补充 logger 方法实现或移除
  context.push('/message-detail', extra: message);
}

class MessageInfo {
  final String id;
  final String content;
  final DateTime timestamp;
  final bool isFavorite;
  final String? sender;
  final String? recipient;

  const MessageInfo({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.isFavorite,
    this.sender,
    this.recipient,
  });

  String get displayName => sender ?? recipient ?? '未知';
}

class _MessageItem extends StatelessWidget {
  final MessageInfo message;
  final VoidCallback onTap;

  const _MessageItem({required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      message.sender != null ? Icons.inbox : Icons.send,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.displayName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTimestamp(message.timestamp),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (message.isFavorite)
                    Icon(
                      Icons.star,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message.content,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      message.isFavorite ? Icons.star : Icons.star_border,
                      color: message.isFavorite
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    onPressed: () {
                      // TODO: 切换收藏状态
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message.isFavorite ? '取消收藏' : '已收藏'),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    onPressed: () {
                      // TODO: 删除消息
                      _showDeleteDialog(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除消息'),
        content: const Text('确定要删除这条消息吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 执行删除操作
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('消息已删除')));
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
