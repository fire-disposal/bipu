import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/theme/design_system.dart';
import '../../../shared/models/message_model.dart';
import '../logic/message_provider.dart';
import '../logic/message_controller.dart';
import 'message_detail_screen.dart';
import 'service_subscription_simple_screen.dart';
import '../../blocks/ui/blocks_screen.dart';

/// 消息列表页面
class MessageListScreen extends HookConsumerWidget {
  final MessageFilter initialFilter;

  const MessageListScreen({
    super.key,
    this.initialFilter = MessageFilter.received,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = useState<MessageFilter>(initialFilter);

    final scrollController = useScrollController();

    // 获取消息列表状态
    final messageState = ref.watch(
      getMessageListProvider(selectedFilter.value),
    );
    final messageController = ref.read(
      messageControllerProvider(selectedFilter.value),
    );

    // 监听滚动到底部加载更多
    useEffect(() {
      void onScroll() {
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200) {
          if (messageState.hasMore &&
              messageState.status != MessageStatus.loading &&
              messageState.status != MessageStatus.loadingMore) {
            messageController.loadMore();
          }
        }
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController, messageState]);

    // 初始化加载
    useEffect(() {
      if (messageState.status == MessageStatus.initial) {
        messageController.loadMessages();
      }
      return null;
    }, []);

    // 构建筛选标签
    Widget buildFilterChip(MessageFilter filter, String label) {
      final isSelected = selectedFilter.value == filter;
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              selectedFilter.value = filter;
            }
          },
        ),
      );
    }

    // 构建消息项
    Widget buildMessageItem(MessageResponse message, int index) {
      final isSystem = MessageController.isSystemMessage(message);
      final isVoice = MessageController.isVoiceMessage(message);
      final currentUserId = ''; // TODO: 从用户状态获取当前用户ID

      return Card(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSystem
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isSystem
                  ? Icons.notifications
                  : isVoice
                  ? Icons.mic
                  : Icons.message,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 20,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  MessageController.getMessageTitle(message, currentUserId),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                MessageController.formatMessageTime(message.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                message.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (isVoice) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.volume_up,
                      size: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '语音消息',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    MessageDetailScreen(messageId: message.id),
              ),
            );
          },
          onLongPress: () {
            _showMessageActions(context, message, messageController);
          },
        ),
      );
    }

    // 构建空状态
    Widget buildEmptyState() {
      String title;
      String description;
      IconData icon;

      switch (selectedFilter.value) {
        case MessageFilter.received:
          title = '暂无收到的消息';
          description = '收到的消息将在这里显示';
          icon = Icons.inbox;
          break;
        case MessageFilter.sent:
          title = '暂无发出的消息';
          description = '发出的消息将在这里显示';
          icon = Icons.send;
          break;
        case MessageFilter.system:
          title = '暂无系统消息';
          description = '系统通知将在这里显示';
          icon = Icons.notifications;
          break;
        case MessageFilter.favorites:
          title = '暂无收藏消息';
          description = '收藏的消息将在这里显示';
          icon = Icons.star;
          break;
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // 构建错误状态
    Widget buildErrorState() {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('加载失败', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              messageState.error ?? '未知错误',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ShadButton(
              onPressed: () => messageController.refresh(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    // 构建加载状态
    Widget buildLoadingState() {
      return const Center(child: CircularProgressIndicator());
    }

    // 构建内容
    Widget buildContent() {
      switch (messageState.status) {
        case MessageStatus.initial:
        case MessageStatus.loading:
          return buildLoadingState();
        case MessageStatus.error:
          return buildErrorState();
        case MessageStatus.loaded:
        case MessageStatus.loadingMore:
          if (messageState.messages.isEmpty) {
            return buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => messageController.refresh(),
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount:
                  messageState.messages.length + (messageState.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < messageState.messages.length) {
                  return buildMessageItem(messageState.messages[index], index);
                } else {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
              },
            ),
          );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('消息'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: 实现消息搜索
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showMoreOptions(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 筛选标签栏
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  buildFilterChip(MessageFilter.received, '收到的消息'),
                  buildFilterChip(MessageFilter.sent, '发出的消息'),
                  buildFilterChip(MessageFilter.system, '系统消息'),
                  buildFilterChip(MessageFilter.favorites, '收藏'),
                ],
              ),
            ),
          ),
          // 消息列表
          Expanded(child: buildContent()),
        ],
      ),
    );
  }

  // 显示消息操作菜单
  void _showMessageActions(
    BuildContext context,
    MessageResponse message,
    MessageController controller,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.star_border),
                title: const Text('收藏消息'),
                onTap: () {
                  Navigator.pop(context);
                  controller.addFavorite(message.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('删除消息'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, message, controller);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('复制内容'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 实现复制功能
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('取消'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  // 显示删除确认对话框
  void _showDeleteConfirmation(
    BuildContext context,
    MessageResponse message,
    MessageController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除消息'),
          content: const Text('确定要删除这条消息吗？删除后无法恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                controller.deleteMessage(message.id);
              },
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  // 显示更多选项
  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('服务号管理'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ServiceSubscriptionSimpleScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('黑名单管理'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BlocksScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('通知设置'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 跳转到通知设置
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('消息帮助'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 显示消息帮助
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
