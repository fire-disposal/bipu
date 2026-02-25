import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 消息页面
class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 页面标题
            Text(
              '消息',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '查看和管理您的消息',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 24),

            // 消息分类
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildMessageCategory(
                    context,
                    label: '全部',
                    icon: Icons.all_inbox,
                    isActive: true,
                  ),
                  const SizedBox(width: 8),
                  _buildMessageCategory(
                    context,
                    label: '未读',
                    icon: Icons.mark_email_unread,
                    isActive: false,
                  ),
                  const SizedBox(width: 8),
                  _buildMessageCategory(
                    context,
                    label: '已读',
                    icon: Icons.mark_email_read,
                    isActive: false,
                  ),
                  const SizedBox(width: 8),
                  _buildMessageCategory(
                    context,
                    label: '系统',
                    icon: Icons.notifications,
                    isActive: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 消息列表
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '最近消息',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        GestureDetector(
                          onTap: () {
                            Get.snackbar('提示', '查看全部消息功能开发中');
                          },
                          child: Text(
                            '查看全部',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(5, (index) {
                      final messages = [
                        {
                          'title': '系统通知',
                          'content': '欢迎使用Bipupu宇宙传讯系统',
                          'time': '刚刚',
                          'unread': true,
                          'type': 'system',
                          'icon': Icons.notifications,
                        },
                        {
                          'title': '用户A',
                          'content': '您好，我有一个问题想咨询',
                          'time': '5分钟前',
                          'unread': true,
                          'type': 'user',
                          'icon': Icons.person,
                        },
                        {
                          'title': '传呼提醒',
                          'content': '您有一个新的传呼请求',
                          'time': '1小时前',
                          'unread': false,
                          'type': 'pager',
                          'icon': Icons.call,
                        },
                        {
                          'title': '系统更新',
                          'content': '系统已升级到最新版本',
                          'time': '昨天',
                          'unread': false,
                          'type': 'system',
                          'icon': Icons.update,
                        },
                        {
                          'title': '用户B',
                          'content': '谢谢您的帮助！',
                          'time': '2天前',
                          'unread': false,
                          'type': 'user',
                          'icon': Icons.person,
                        },
                      ];

                      final message = messages[index];

                      return Container(
                        margin: EdgeInsets.only(bottom: index < 4 ? 12 : 0),
                        child: Row(
                          children: [
                            // 消息图标
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                message['icon'] as IconData,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // 消息内容
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        message['title'] as String,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      if (message['unread'] as bool)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            left: 8,
                                          ),
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    message['content'] as String,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            // 时间和操作
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  message['time'] as String,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                IconButton(
                                  icon: Icon(
                                    Icons.more_vert,
                                    size: 20,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () {
                                    _showMessageOptions(context, message);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 空状态提示
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无更多消息',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '当您收到新消息时，会在这里显示',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () {
                      Get.snackbar('提示', '刷新消息功能开发中');
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, size: 16),
                        SizedBox(width: 8),
                        Text('刷新消息'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 消息设置
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.settings_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '消息设置',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '消息通知',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Switch(
                          value: true,
                          onChanged: (value) {
                            Get.snackbar('提示', '消息通知设置已更新');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '声音提醒',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Switch(
                          value: false,
                          onChanged: (value) {
                            Get.snackbar('提示', '声音提醒设置已更新');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '振动提醒',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Switch(
                          value: true,
                          onChanged: (value) {
                            Get.snackbar('提示', '振动提醒设置已更新');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                        Get.snackbar('提示', '更多消息设置功能开发中');
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.settings, size: 16),
                          SizedBox(width: 8),
                          Text('更多设置'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // 构建消息分类按钮
  Widget _buildMessageCategory(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isActive
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isActive
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // 显示消息选项
  void _showMessageOptions(BuildContext context, Map<String, dynamic> message) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '消息选项',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Divider(height: 1, color: Theme.of(context).colorScheme.outline),
              ListTile(
                leading: Icon(
                  Icons.mark_email_read,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text('标记为已读'),
                onTap: () {
                  Navigator.pop(context);
                  Get.snackbar('提示', '已标记为已读');
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text('删除消息'),
                onTap: () {
                  Navigator.pop(context);
                  Get.snackbar('提示', '消息已删除');
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.reply,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text('回复'),
                onTap: () {
                  Navigator.pop(context);
                  Get.snackbar('提示', '回复功能开发中');
                },
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('取消'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
