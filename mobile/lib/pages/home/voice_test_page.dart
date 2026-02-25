import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/components/ui_components.dart';

/// 语音测试页面
class VoiceTestPage extends StatelessWidget {
  const VoiceTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return UIPageContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题区域
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.mic,
                        color: theme.colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '语音测试',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.foreground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '测试语音录制与播放功能',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 录音状态卡片
            UICard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '录音状态',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.foreground,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '麦克风就绪',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.foreground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击下方按钮开始录音',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 录音控制区域
            _buildRecordingControls(context),

            const SizedBox(height: 32),

            // 录音列表标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '录音记录',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.foreground,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 录音列表
            _buildRecordingList(context),

            const SizedBox(height: 32),

            // 使用说明
            UICard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '使用说明',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.foreground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionItem(
                    context,
                    icon: Icons.mic,
                    text: '长按录音按钮开始录音',
                  ),
                  _buildInstructionItem(
                    context,
                    icon: Icons.stop,
                    text: '松开按钮停止录音',
                  ),
                  _buildInstructionItem(
                    context,
                    icon: Icons.play_arrow,
                    text: '点击播放按钮试听录音',
                  ),
                  _buildInstructionItem(
                    context,
                    icon: Icons.delete,
                    text: '长按录音记录可删除',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建录音控制区域
  Widget _buildRecordingControls(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 录音按钮
          GestureDetector(
            onLongPressStart: (_) {
              Get.snackbar('录音', '开始录音...');
            },
            onLongPressEnd: (_) {
              Get.snackbar('录音', '录音结束');
            },
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.mic, color: Colors.white, size: 48),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '长按录音',
            style: TextStyle(fontSize: 16, color: theme.colorScheme.foreground),
          ),
          const SizedBox(height: 8),
          Text(
            '最长可录制60秒',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建录音列表
  Widget _buildRecordingList(BuildContext context) {
    final theme = ShadTheme.of(context);

    // 模拟录音数据
    final recordings = [
      {'name': '录音 1', 'duration': '00:15', 'date': '2024-01-15'},
      {'name': '测试录音', 'duration': '00:30', 'date': '2024-01-14'},
      {'name': '语音消息', 'duration': '00:45', 'date': '2024-01-13'},
    ];

    if (recordings.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.muted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.audiotrack,
              color: theme.colorScheme.mutedForeground,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              '暂无录音',
              style: TextStyle(
                color: theme.colorScheme.mutedForeground,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击上方按钮开始录音',
              style: TextStyle(
                color: theme.colorScheme.mutedForeground,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: recordings.map((recording) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: UICard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.audiotrack,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recording['name']!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.foreground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              recording['duration']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            recording['date']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Get.snackbar('播放', '播放 ${recording['name']}');
                      },
                      icon: Icon(
                        Icons.play_arrow,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Get.snackbar('删除', '删除 ${recording['name']}');
                      },
                      icon: Icon(
                        Icons.delete,
                        color: theme.colorScheme.destructive,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 构建说明项
  Widget _buildInstructionItem(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final theme = ShadTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
