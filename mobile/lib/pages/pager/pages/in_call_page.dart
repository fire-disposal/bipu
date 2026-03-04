import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state/pager_state_machine.dart';
import '../state/pager_cubit.dart';
import '../widgets/operator_display_widget.dart';
import '../widgets/waveform_animation_widget.dart';

class InCallPage extends StatefulWidget {
  final PagerCubit cubit;
  const InCallPage({super.key, required this.cubit});

  @override
  State<InCallPage> createState() => _InCallPageState();
}

class _InCallPageState extends State<InCallPage> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PagerCubit, PagerState>(
      bloc: widget.cubit,
      builder: (context, state) {
        if (state is! InCallState) return const SizedBox.shrink();

        // 使用接线员的配置主题色
        final operator = state.operator;
        final themeColor =
            operator?.themeColor ?? Theme.of(context).colorScheme.primary;

        // 创建基于接线员主题色的 ColorScheme
        final colorScheme = ColorScheme.fromSeed(
          seedColor: themeColor,
          brightness: Theme.of(context).brightness,
        );
        final theme = Theme.of(context);

        return Stack(
          children: [
            Container(color: colorScheme.surface),
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(state, colorScheme, theme, themeColor),

                  // --- 中间核心区：立绘与历史气泡并列 ---
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLeftProfile(
                            state,
                            colorScheme,
                            theme,
                            themeColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildOperatorHistoryStream(
                              state,
                              colorScheme,
                              theme,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- 用户消息显示缓冲区：占据中间下半部 ---
                  _buildUserMessageBuffer(state, colorScheme, theme),

                  // --- 底部操作区 ---
                  _buildBottomArea(state, colorScheme, theme),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// 1. 左侧立绘 (保持紧凑)
  Widget _buildLeftProfile(
    InCallState state,
    ColorScheme colorScheme,
    ThemeData theme,
    Color themeColor,
  ) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.32,
      child: Column(
        children: [
          Container(
            height: 180, // 高度略微收缩，为下方缓冲区留空间
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              border: Border.all(color: themeColor.withOpacity(0.2)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: OperatorDisplayWidget(
                imageUrl: state.operatorImageUrl,
                isAnimating: state.waveformData.isNotEmpty,
              ),
            ),
          ),
          if (state.waveformData.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: WaveformAnimationWidget(
                waveformData: state.waveformData,
                isActive: true,
                height: 20,
              ),
            ),
        ],
      ),
    );
  }

  /// 2. 右侧对话历史流 (移至立绘右边)
  /// ✅ 显示接线员的所有台词历史
  Widget _buildOperatorHistoryStream(
    InCallState state,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    // ✅ 修复：使用状态中的实际历史台词
    final history = state.operatorSpeechHistory;

    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black],
        stops: [0.0, 0.2],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: history.isEmpty
          ? Center(
              child: Text(
                '准备就绪...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline.withOpacity(0.5),
                ),
              ),
            )
          : ListView.builder(
              reverse: true,
              padding: const EdgeInsets.only(top: 40),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final text = history.reversed.toList()[index];
                final isCurrent = index == 0; // 最新的是当前的
                return _buildMiniBubble(
                  text,
                  colorScheme,
                  theme,
                  isCurrent: isCurrent,
                );
              },
            ),
    );
  }

  /// ✅ 构建接线员台词气泡
  Widget _buildMiniBubble(
    String text,
    ColorScheme colorScheme,
    ThemeData theme, {
    required bool isCurrent,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.5, 0),
        end: Offset.zero,
      ).animate(AlwaysStoppedAnimation<double>(1.0)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrent
              ? colorScheme.primaryContainer.withOpacity(0.5)
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent
                ? colorScheme.primary.withOpacity(0.3)
                : colorScheme.outlineVariant.withOpacity(0.1),
            width: isCurrent ? 1.5 : 0.5,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface,
            fontSize: 13,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
            height: 1.4,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// 3. 用户消息缓冲区 (中间下半部大区域)
  /// ✅ 显示用户当前的语音识别内容和状态
  Widget _buildUserMessageBuffer(
    InCallState state,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      width: double.infinity,
      height: 120, // 固定高度的大缓冲区
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        // 淡淡的渐变背景，暗示这是实时采集区
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            colorScheme.primary.withOpacity(0.05),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: state.isWaitingForUserInput
              ? colorScheme.primary.withOpacity(0.2)
              : colorScheme.outlineVariant.withOpacity(0.1),
          width: state.isWaitingForUserInput ? 1.5 : 0.5,
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        ),
        child: state.asrTranscript.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      state.isWaitingForUserInput
                          ? Icons.mic
                          : Icons.hourglass_empty,
                      color: colorScheme.outline.withOpacity(0.5),
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.isWaitingForUserInput ? "请说话..." : "准备中...",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.outline.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    state.asrTranscript,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  /// 4. 底部操作区 (挂断 + 语音)
  /// ✅ 提供直观的交互反馈
  Widget _buildBottomArea(
    InCallState state,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(
        children: [
          // 挂断按钮
          _buildCircleButton(
            onTap: () => widget.cubit.cancelDialing(),
            icon: Icons.call_end,
            bg: colorScheme.errorContainer,
            fg: colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 16),
          // 语音识别状态按钮
          Expanded(
            child: InkWell(
              onTap: state.isSilenceDetected
                  ? () => widget.cubit.finishAsrRecording()
                  : null,
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 64,
                decoration: BoxDecoration(
                  gradient: state.asrTranscript.isNotEmpty
                      ? LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.primary.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: state.asrTranscript.isEmpty
                      ? colorScheme.surfaceContainerHighest
                      : null,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: state.asrTranscript.isNotEmpty
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        state.asrTranscript.isNotEmpty
                            ? Icons.graphic_eq
                            : Icons.mic,
                        color: state.asrTranscript.isNotEmpty
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        state.asrTranscript.isNotEmpty
                            ? state.isSilenceDetected
                                  ? "已完成"
                                  : "正在聆听"
                            : state.isWaitingForUserInput
                            ? "等待输入"
                            : "准备中",
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: state.asrTranscript.isNotEmpty
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required VoidCallback onTap,
    required IconData icon,
    required Color bg,
    required Color fg,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: fg, size: 28),
      ),
    );
  }

  Widget _buildTopBar(
    InCallState state,
    ColorScheme colorScheme,
    ThemeData theme,
    Color themeColor,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: Row(
        children: [
          CircleAvatar(radius: 4, backgroundColor: themeColor),
          const SizedBox(width: 8),
          Text(
            'LINE ACTIVE',
            style: theme.textTheme.labelSmall?.copyWith(
              color: themeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text('ID: ${state.targetId}', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
