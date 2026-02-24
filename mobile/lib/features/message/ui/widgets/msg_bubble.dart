import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:intl/intl.dart';

import '../../../../shared/models/message_model.dart';
import '../../../../core/theme/design_system.dart';

/// 消息气泡组件
///
/// 用于聊天对话框中显示单条消息
class MsgBubble extends HookWidget {
  final MessageResponse message;
  final bool isOwn;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  const MsgBubble({
    super.key,
    required this.message,
    required this.isOwn,
    this.onLongPress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('MM-dd HH:mm');

    final now = DateTime.now();
    final messageTime = message.createdAt;
    final isToday =
        messageTime.year == now.year &&
        messageTime.month == now.month &&
        messageTime.day == now.day;

    final timeText = isToday
        ? timeFormat.format(messageTime)
        : dateFormat.format(messageTime);

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.lg,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Row(
          mainAxisAlignment: isOwn
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 他人消息：头像在左侧
            if (!isOwn) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primary,
                child: Icon(
                  Icons.person,
                  size: 16,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],

            // 消息气泡
            Flexible(
              child: Column(
                crossAxisAlignment: isOwn
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isOwn
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(AppRadius.md),
                        topRight: const Radius.circular(AppRadius.md),
                        bottomLeft: Radius.circular(isOwn ? AppRadius.md : 2),
                        bottomRight: Radius.circular(isOwn ? 2 : AppRadius.md),
                      ),
                    ),
                    child: Text(
                      message.content,
                      style: TextStyle(
                        color: isOwn
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),

                  // 时间戳
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    timeText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // 自己消息：头像在右侧（可选）
            if (isOwn) ...[
              const SizedBox(width: AppSpacing.sm),
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primary,
                child: Icon(
                  Icons.person,
                  size: 16,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 消息状态指示器
class MessageStatusIndicator extends StatelessWidget {
  final bool isSending;
  final bool isSent;
  final bool isRead;

  const MessageStatusIndicator({
    super.key,
    required this.isSending,
    required this.isSent,
    this.isRead = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isSending) {
      return SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: theme.colorScheme.outline,
        ),
      );
    }

    if (isRead) {
      return Icon(Icons.done_all, size: 16, color: theme.colorScheme.primary);
    }

    if (isSent) {
      return Icon(Icons.done, size: 16, color: theme.colorScheme.outline);
    }

    return const SizedBox.shrink();
  }
}
