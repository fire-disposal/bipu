import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/design_system.dart';
import '../../../shared/models/message_model.dart';
import '../../../shared/widgets/waveform_image_exporter.dart';
import '../logic/message_provider.dart';
import '../logic/message_controller.dart';

/// 消息详情页面
class MessageDetailScreen extends HookConsumerWidget {
  final int messageId;

  const MessageDetailScreen({super.key, required this.messageId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageAsync = ref.watch(messageDetailProvider(messageId));
    final isFavorite = useState<bool>(false);
    final isExporting = useState<bool>(false);
    final exportPath = useState<String?>(null);

    // 获取消息控制器
    final messageController = ref.read(
      messageControllerProvider(MessageFilter.received),
    );

    // 构建消息头部信息
    Widget buildMessageHeader(MessageResponse message) {
      final isSystem = MessageController.isSystemMessage(message);
      final isVoice = MessageController.isVoiceMessage(message);
      final currentUserId = ''; // TODO: 从用户状态获取当前用户ID

      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSystem
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSystem
                        ? Icons.notifications
                        : isVoice
                        ? Icons.mic
                        : Icons.message,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        MessageController.getMessageTitle(
                          message,
                          currentUserId,
                        ),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        MessageController.formatMessageTime(message.createdAt),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFavorite.value ? Icons.star : Icons.star_border,
                    color: isFavorite.value
                        ? Colors.amber
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    if (isFavorite.value) {
                      messageController.removeFavorite(message.id);
                    } else {
                      messageController.addFavorite(message.id);
                    }
                    isFavorite.value = !isFavorite.value;
                  },
                ),
              ],
            ),
            if (isVoice) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(
                    Icons.volume_up,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '语音消息',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            if (isSystem) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '系统消息',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    }

    // 构建消息内容
    Widget buildMessageContent(MessageResponse message) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '消息内容',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: SelectableText(
                message.content,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      );
    }

    // 构建波形可视化
    Widget buildWaveformVisualization(MessageResponse message) {
      if (message.waveform == null || message.waveform!.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '声纹波形',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () async {
                        isExporting.value = true;
                        try {
                          final path = await WaveformImageExporter.saveToFile(
                            message.waveform,
                            fileName: 'waveform_${message.id}',
                            width: 800,
                            height: 240,
                            color: Theme.of(context).colorScheme.primary,
                            backgroundColor: Colors.white,
                          );
                          exportPath.value = path;

                          if (path != null) {
                            // TODO: 实现分享功能
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('波形图已保存到: $path')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('导出失败: $e'),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                            ),
                          );
                        } finally {
                          isExporting.value = false;
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () async {
                        isExporting.value = true;
                        try {
                          final bytes = await WaveformImageExporter.exportToPng(
                            message.waveform,
                            width: 800,
                            height: 240,
                            color: Theme.of(context).colorScheme.primary,
                            backgroundColor: Colors.white,
                          );

                          if (bytes != null) {
                            // TODO: 实现下载功能
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('波形图已生成')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('生成失败: $e'),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                            ),
                          );
                        } finally {
                          isExporting.value = false;
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  if (isExporting.value)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    WaveformImagePreview(
                      waveform: message.waveform,
                      width: MediaQuery.of(context).size.width - 64,
                      height: 200,
                      color: Theme.of(context).colorScheme.primary,
                      backgroundColor: Colors.transparent,
                    ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '音频振幅包络可视化',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 构建消息元数据
    Widget buildMessageMetadata(MessageResponse message) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '消息详情',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildMetadataRow(context, '消息ID', message.id.toString()),
                  _buildMetadataRow(context, '发送者', message.senderBipupuId),
                  _buildMetadataRow(context, '接收者', message.receiverBipupuId),
                  _buildMetadataRow(context, '消息类型', message.messageType),
                  _buildMetadataRow(
                    context,
                    '创建时间',
                    DateFormat('yyyy-MM-dd HH:mm:ss').format(message.createdAt),
                  ),
                  if (message.pattern != null && message.pattern!.isNotEmpty)
                    _buildMetadataRow(
                      context,
                      '模式数据',
                      '${message.pattern!.length} 项',
                    ),
                  if (message.waveform != null)
                    _buildMetadataRow(
                      context,
                      '波形数据',
                      '${message.waveform!.length} 个采样点',
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 构建操作按钮
    Widget buildActionButtons(MessageResponse message) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: ShadButton(
                onPressed: () {
                  // TODO: 实现回复功能
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.reply, size: 16),
                    SizedBox(width: 8),
                    Text('回复'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ShadButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
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
                            messageController.deleteMessage(message.id);
                            Navigator.pop(context);
                          },
                          child: const Text('删除'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline, size: 16),
                    SizedBox(width: 8),
                    Text('删除'),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('消息详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showMoreOptions(context, messageAsync.value);
            },
          ),
        ],
      ),
      body: messageAsync.when(
        data: (message) {
          if (message == null) {
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
                  Text('消息不存在', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '无法找到指定的消息',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ShadButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('返回'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildMessageHeader(message),
                buildMessageContent(message),
                if (MessageController.isVoiceMessage(message))
                  buildWaveformVisualization(message),
                buildMessageMetadata(message),
                buildActionButtons(message),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
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
                '$error',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShadButton(
                    onPressed: () =>
                        ref.refresh(messageDetailProvider(messageId)),
                    child: const Text('重试'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  ShadButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('返回'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建元数据行
  Widget _buildMetadataRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: SelectableText(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  // 显示更多选项
  void _showMoreOptions(BuildContext context, MessageResponse? message) {
    if (message == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('复制消息内容'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 实现复制功能
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('分享消息'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 实现分享功能
                },
              ),
              if (MessageController.isVoiceMessage(message))
                ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text('导出波形图片'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: 触发波形导出
                  },
                ),
              ListTile(
                leading: const Icon(Icons.report),
                title: const Text('举报消息'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 实现举报功能
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
}
