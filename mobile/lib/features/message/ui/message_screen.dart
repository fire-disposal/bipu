import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/design_system.dart';
import '../logic/message_provider.dart';
import 'message_list_screen.dart';
import 'service_subscription_screen.dart';

/// 主消息页面 - 整合所有消息功能入口
class MessageScreen extends HookConsumerWidget {
  const MessageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取未读消息统计
    final receivedMessages = ref.watch(
      receivedMessagesProvider.select((state) => state.messages),
    );
    final systemMessages = ref.watch(
      systemMessagesProvider.select((state) => state.messages),
    );
    final favoriteMessages = ref.watch(
      favoriteMessagesProvider.select((state) => state.messages),
    );

    // 计算未读消息数量（这里简单使用消息总数，实际应该根据已读状态）
    final receivedCount = receivedMessages.length;
    final systemCount = systemMessages.length;
    final favoriteCount = favoriteMessages.length;

    // 构建功能卡片
    Widget buildFeatureCard({
      required String title,
      required String description,
      required IconData icon,
      required Color color,
      required int count,
      required VoidCallback onTap,
    }) {
      return Card(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(AppSpacing.md),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onTap: onTap,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('消息'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: 实现全局消息搜索
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ServiceSubscriptionScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 欢迎标题
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '消息中心',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '查看和管理您的所有消息',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // 消息分类
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                '消息分类',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            buildFeatureCard(
              title: '收到的消息',
              description: '查看其他用户发送给您的消息',
              icon: Icons.inbox,
              color: Theme.of(context).colorScheme.primary,
              count: receivedCount,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MessageListScreen(
                      initialFilter: MessageFilter.received,
                    ),
                  ),
                );
              },
            ),
            buildFeatureCard(
              title: '发出的消息',
              description: '查看您发送给其他用户的消息',
              icon: Icons.send,
              color: Theme.of(context).colorScheme.secondary,
              count: 0, // 发出的消息没有未读概念
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MessageListScreen(
                      initialFilter: MessageFilter.sent,
                    ),
                  ),
                );
              },
            ),
            buildFeatureCard(
              title: '系统消息',
              description: '服务号推送和系统通知',
              icon: Icons.notifications,
              color: Colors.amber,
              count: systemCount,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MessageListScreen(
                      initialFilter: MessageFilter.system,
                    ),
                  ),
                );
              },
            ),
            buildFeatureCard(
              title: '收藏消息',
              description: '您收藏的重要消息',
              icon: Icons.star,
              color: Colors.amber,
              count: favoriteCount,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MessageListScreen(
                      initialFilter: MessageFilter.favorites,
                    ),
                  ),
                );
              },
            ),
            // 快捷功能
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                '快捷功能',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.settings,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      '服务号管理',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '管理订阅的服务号和推送设置',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
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
                              const ServiceSubscriptionScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.help_outline,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      '消息帮助',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '了解消息功能和使用方法',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onTap: () {
                      _showHelpDialog(context);
                    },
                  ),
                ],
              ),
            ),
            // 统计信息
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '消息统计',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          context,
                          '总消息数',
                          (receivedCount + systemCount).toString(),
                          Icons.message,
                          Theme.of(context).colorScheme.primary,
                        ),
                        _buildStatItem(
                          context,
                          '收藏数',
                          favoriteCount.toString(),
                          Icons.star,
                          Colors.amber,
                        ),
                        _buildStatItem(
                          context,
                          '服务号',
                          '5', // TODO: 从API获取服务号数量
                          Icons.notifications,
                          Theme.of(context).colorScheme.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  // 构建统计项
  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // 显示帮助对话框
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('消息功能帮助'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('消息分类说明', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                '• 收到的消息：其他用户发送给您的消息\n'
                '• 发出的消息：您发送给其他用户的消息\n'
                '• 系统消息：服务号推送和系统通知\n'
                '• 收藏消息：您标记为重要的消息',
              ),
              SizedBox(height: 16),
              Text('消息操作', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                '• 长按消息可进行收藏、删除等操作\n'
                '• 语音消息支持波形图导出和分享\n'
                '• 消息一旦发送无法撤回或编辑',
              ),
              SizedBox(height: 16),
              Text('服务号管理', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                '• 订阅您感兴趣的服务号\n'
                '• 自定义每个服务号的推送时间\n'
                '• 可随时启用或禁用推送',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
