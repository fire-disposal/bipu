import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state/pager_state_machine.dart';
import '../state/pager_cubit.dart';
import '../widgets/waveform_animation_widget.dart';

/// 发送与结束页面 (State 3)
/// 显示"发送"按钮，发送消息后播放成功 TTS，显示"挂断"按钮
class FinalizePage extends StatefulWidget {
  final PagerCubit cubit;

  const FinalizePage({super.key, required this.cubit});

  @override
  State<FinalizePage> createState() => _FinalizePageState();
}

class _FinalizePageState extends State<FinalizePage> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return BlocBuilder<PagerCubit, PagerState>(
      bloc: widget.cubit,
      builder: (context, state) {
        if (state is! FinalizeState) {
          return const SizedBox.shrink();
        }

        return Stack(
          children: [
            // 背景
            _buildBackground(colorScheme),

            // 主内容
            SafeArea(
              child: Column(
                children: [
                  // 顶部信息栏
                  _buildTopBar(state, colorScheme, theme),

                  // 中间内容区
                  Expanded(
                    child: _buildCenterContent(state, colorScheme, theme),
                  ),

                  // 底部按钮区
                  _buildBottomButtons(state, colorScheme, theme),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// 构建背景
  Widget _buildBackground(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.secondaryContainer,
            colorScheme.tertiaryContainer,
          ],
        ),
      ),
    );
  }

  /// 构建顶部信息栏
  Widget _buildTopBar(
    FinalizeState state,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '消息准备',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '目标 ID: ${state.targetId}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (state.sendSuccess)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.onSecondaryContainer,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '已发送',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 构建中间内容区
  Widget _buildCenterContent(
    FinalizeState state,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // 消息内容显示
            _buildMessageDisplay(state, colorScheme, theme),
            const SizedBox(height: 24),

            // 发送状态
            if (!state.sendSuccess)
              _buildPreSendStatus(state, colorScheme, theme),

            // 发送成功状态
            if (state.sendSuccess)
              _buildPostSendStatus(state, colorScheme, theme),

            const SizedBox(height: 24),

            // 错误提示
            if (state.sendErrorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.error),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.sendErrorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// 构建消息显示
  Widget _buildMessageDisplay(
    FinalizeState state,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    if (state.isEditing) {
      return _buildMessageEditingArea(state, colorScheme, theme);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '消息内容',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              // 编辑按钮
              if (!state.sendSuccess)
                GestureDetector(
                  onTap: () => widget.cubit.startEditingMessage(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: colorScheme.primary),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit,
                          size: 12,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '编辑',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              state.messageContent,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '字数：${state.messageContent.length}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          // 表情符号警告
          if (state.textProcessingResult?.hasEmoji ?? false) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.tertiary),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    size: 16,
                    color: colorScheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '检测到${state.textProcessingResult!.detectedEmojis.length}个表情符号，已自动移除',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建消息编辑区域
  Widget _buildMessageEditingArea(
    FinalizeState state,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '编辑消息',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () => widget.cubit.cancelEditingMessage(),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            maxLines: 4,
            minLines: 3,
            controller: TextEditingController(text: state.messageContent),
            onChanged: (value) => widget.cubit.updateEditingMessage(value),
            decoration: InputDecoration(
              hintText: '输入消息内容...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: colorScheme.surface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '字数：${state.messageContent.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => widget.cubit.cancelEditingMessage(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colorScheme.primary),
                      ),
                      child: Text(
                        '取消',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => widget.cubit.finishEditingMessage(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '确认',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 表情符号检测警告
          if (state.textProcessingResult?.hasEmoji ?? false) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.tertiary),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_emotions,
                    size: 16,
                    color: colorScheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '检测到表情符号，将被自动移除',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建发送前状态
  Widget _buildPreSendStatus(
    FinalizeState state,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.primary),
          ),
          child: Column(
            children: [
              Icon(
                Icons.info_outline,
                color: colorScheme.onPrimaryContainer,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                '消息已准备就绪',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '点击下方"发送"按钮确认发送',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建发送后状态
  Widget _buildPostSendStatus(
    FinalizeState state,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Column(
      children: [
        // 成功动画
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.secondary),
          ),
          child: Column(
            children: [
              Icon(
                Icons.check_circle,
                color: colorScheme.onSecondaryContainer,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                '消息已发送',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '接线员已收到您的消息',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // TTS 播放状态
        if (state.isPlayingSuccessTts) ...[
          WaveformAnimationWidget(
            isActive: true,
            waveColor: colorScheme.secondary,
            height: 80,
          ),
          const SizedBox(height: 12),
          Text(
            '播放成功提示音...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ],
    );
  }

  /// 构建底部按钮区
  Widget _buildBottomButtons(
    FinalizeState state,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 发送按钮（发送前显示）
          if (!state.sendSuccess)
            GestureDetector(
              onTap: state.isSending ? null : () => widget.cubit.sendMessage(),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: state.isSending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.send,
                              color: colorScheme.onPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '发送',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

          // 挂断按钮（发送后显示）
          if (state.sendSuccess && state.showHangupButton) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => widget.cubit.hangup(),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: colorScheme.errorContainer,
                  border: Border.all(color: colorScheme.error),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.call_end,
                      color: colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '挂断',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // 返回按钮
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => widget.cubit.cancelDialing(),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.surfaceContainerHighest,
                border: Border.all(color: colorScheme.outline),
              ),
              child: Center(
                child: Text(
                  '返回',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
