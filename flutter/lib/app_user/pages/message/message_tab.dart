import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../state/user_state.dart';
import '../../state/message_cubit.dart';

/// 消息中心 (C) - ListView.separated 消息分类列表
class MessageTab extends StatelessWidget {
  const MessageTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MessageCubit, MessageState>(
      builder: (context, state) {
        if (state is MessageLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is MessageError) {
          return Scaffold(
            appBar: AppBar(title: const Text('消息中心'), centerTitle: true),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('加载失败: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<MessageCubit>().refreshMessages(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is MessageLoaded) {
          return _buildMessageList(context, state);
        }

        return const Scaffold(body: Center(child: Text('未知状态')));
      },
    );
  }

  Widget _buildMessageList(BuildContext context, MessageLoaded state) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '消息中心',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<MessageCubit>().refreshMessages(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 显示统计信息
          _MessageStats(cubit: context.read<MessageCubit>()),
          // 消息分类列表
          Expanded(
            child: ListView.separated(
              itemCount: state.categories.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final category = state.categories[index];
                return _MessageCategoryItem(
                  category: category,
                  onTap: () => _handleCategoryTap(context, category),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleCategoryTap(BuildContext context, MessageCategory category) {
    final cubit = context.read<MessageCubit>();

    switch (category.id) {
      case 'received':
        // 导航到收到的消息列表
        _showMessageList(
          context,
          '收到的消息',
          cubit.state is MessageLoaded
              ? (cubit.state as MessageLoaded).receivedMessages
              : [],
        );
        break;
      case 'sent':
        // 导航到发出的消息列表
        _showMessageList(
          context,
          '发出的消息',
          cubit.state is MessageLoaded
              ? (cubit.state as MessageLoaded).sentMessages
              : [],
        );
        break;
      case 'subscription':
        // 导航到订阅消息列表
        _showMessageList(
          context,
          '订阅消息',
          cubit.state is MessageLoaded
              ? (cubit.state as MessageLoaded).subscriptionMessages
              : [],
        );
        break;
      case 'management':
        // 导航到消息管理页面
        _showMessageManagement(context);
        break;
    }
  }

  void _showMessageList(
    BuildContext context,
    String title,
    List<dynamic> messages,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(title), centerTitle: true),
          body: messages.isEmpty
              ? const Center(child: Text('暂无消息'))
              : ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _MessageItem(
                      message: message,
                      onTap: () => _handleMessageTap(context, message),
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _showMessageManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('消息管理'), centerTitle: true),
          body: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.filter_list),
                title: const Text('消息筛选'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showMessageFilter(context),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('清空消息'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showClearMessagesDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('消息设置'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showMessageSettings(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageFilter(BuildContext context) {
    // 实现消息筛选功能
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('消息筛选功能开发中')));
  }

  void _showClearMessagesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空消息'),
        content: const Text('确定要清空所有消息吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // 实现清空消息功能
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('消息已清空')));
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showMessageSettings(BuildContext context) {
    // 实现消息设置功能
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('消息设置功能开发中')));
  }

  void _handleMessageTap(BuildContext context, dynamic message) {
    // 标记消息为已读
    context.read<MessageCubit>().markMessageAsRead(message.id);

    // 显示消息详情
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('内容: ${message.content}'),
              const SizedBox(height: 8),
              Text('时间: ${_formatTime(message.timestamp)}'),
              if (message.sender != null) Text('发送者: ${message.sender}'),
              if (message.recipient != null) Text('接收者: ${message.recipient}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () {
              context.read<MessageCubit>().toggleMessageFavorite(message.id);
              Navigator.pop(context);
            },
            child: Text(message.isFavorite ? '取消收藏' : '收藏'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
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
}

/// 消息统计组件
class _MessageStats extends StatelessWidget {
  final MessageCubit cubit;

  const _MessageStats({required this.cubit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.email,
            label: '未读',
            count: cubit.getUnreadCount(),
            color: Colors.red,
          ),
          _StatItem(
            icon: Icons.favorite,
            label: '收藏',
            count: cubit.getFavoriteCount(),
            color: Colors.pink,
          ),
          _StatItem(
            icon: Icons.send,
            label: '已发送',
            count: cubit.state is MessageLoaded
                ? (cubit.state as MessageLoaded).sentMessages.length
                : 0,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }
}

/// 统计项组件
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
        ),
      ],
    );
  }
}

/// 消息分类项组件
class _MessageCategoryItem extends StatelessWidget {
  final MessageCategory category;
  final VoidCallback onTap;

  const _MessageCategoryItem({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue[50],
            child: Icon(category.icon, color: Colors.blue[700]),
          ),
          if (category.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
      title: Text(category.title),
      subtitle: category.unreadCount > 0
          ? Text(
              '${category.unreadCount} 条未读',
              style: const TextStyle(color: Colors.red),
            )
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// 消息项组件
class _MessageItem extends StatelessWidget {
  final dynamic message;
  final VoidCallback onTap;

  const _MessageItem({required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: message.isRead ? Colors.grey[300] : Colors.blue[100],
        child: Icon(
          _getMessageIcon(message.type),
          color: message.isRead ? Colors.grey[600] : Colors.blue[700],
        ),
      ),
      title: Text(
        message.title,
        style: TextStyle(
          fontWeight: message.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Text(
        message.content,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatTime(message.timestamp),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (message.isFavorite)
            const Icon(Icons.favorite, color: Colors.pink, size: 16),
        ],
      ),
      onTap: onTap,
    );
  }

  IconData _getMessageIcon(dynamic type) {
    switch (type) {
      case dynamic:
        return Icons.mark_email_unread;
      case dynamic:
        return Icons.send;
      case dynamic:
        return Icons.subscriptions;
      case dynamic:
        return Icons.settings;
      default:
        return Icons.email;
    }
  }

  String _formatTime(DateTime timestamp) {
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
}
