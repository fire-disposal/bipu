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

                  // --- 录音声纹特效条（等待用户输入时显示）---
                  if (state.isWaitingForUserInput)
                    _buildRecordingWaveformBar(state, colorScheme, theme),

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

  /// 1. 左侧立绘 (保持紧凑) - 优化视觉效果
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
          // ✅ 立绘容器：优化边框和阴影
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
              border: Border.all(
                color: themeColor.withOpacity(0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: themeColor.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: OperatorDisplayWidget(
                imageUrl: state.operatorImageUrl,
                isAnimating: state.waveformData.isNotEmpty,
              ),
            ),
          ),
          // ✅ 波形动画：改进样式
          if (state.waveformData.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: colorScheme.primary.withOpacity(0.06),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.15),
                  ),
                ),
                child: WaveformAnimationWidget(
                  waveformData: state.waveformData,
                  isActive: true,
                  height: 24,
                  waveColor: themeColor,
                ),
              ),
            ),
          // ✅ 接线员名称标签（新增）
          if (state.operator?.name != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: themeColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  state.operator!.name,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: themeColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
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

  /// ✅ 构建接线员台词气泡 - 优化视觉效果
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
        margin: EdgeInsets.only(
          bottom: isCurrent ? 16 : 12,
          left: isCurrent ? 0 : 4,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: isCurrent ? 14 : 12,
        ),
        decoration: BoxDecoration(
          // ✅ 当前气泡：渐变背景，增强视觉层级
          gradient: isCurrent
              ? LinearGradient(
                  colors: [
                    colorScheme.primaryContainer.withOpacity(0.6),
                    colorScheme.primaryContainer.withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: !isCurrent ? colorScheme.surfaceContainerLow : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrent
                ? colorScheme.primary.withOpacity(0.4)
                : colorScheme.outlineVariant.withOpacity(0.15),
            width: isCurrent ? 1.5 : 0.8,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
                fontSize: isCurrent ? 14 : 13,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                height: 1.5,
                letterSpacing: isCurrent ? 0.3 : 0,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            // ✅ 当前气泡添加时间戳
            if (isCurrent)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '刚刚',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 3. 用户消息缓冲区 (中间下半部大区域) - 优化视觉效果
  /// ✅ 显示用户当前的语音识别内容和状态
  Widget _buildUserMessageBuffer(
    InCallState state,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      width: double.infinity,
      height: 140, // 略微增加高度，提高易读性
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        // ✅ 优化背景：更强的视觉分离和深度感
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primary.withOpacity(0.08),
            colorScheme.primary.withOpacity(0.04),
            colorScheme.primary.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: state.isWaitingForUserInput
              ? colorScheme.primary.withOpacity(0.25)
              : colorScheme.outlineVariant.withOpacity(0.12),
          width: state.isWaitingForUserInput ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: state.isWaitingForUserInput
                ? colorScheme.primary.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            blurRadius: state.isWaitingForUserInput ? 12 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        ),
        child: state.asrTranscript.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ✅ 动画图标
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 600),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.8 + 0.2 * value,
                          child: Icon(
                            state.isWaitingForUserInput
                                ? Icons.mic
                                : Icons.hourglass_empty,
                            color: colorScheme.primary.withOpacity(
                              0.5 + 0.3 * value,
                            ),
                            size: 32,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.isWaitingForUserInput ? "请说话..." : "准备中...",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ✅ 标签
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '已识别',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary.withOpacity(0.6),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      // ✅ 主文本：更大、更粗、更清晰
                      Text(
                        state.asrTranscript,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          height: 1.6,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  /// 4. 底部操作区 (挂断 + 语音) - 优化视觉反馈
  /// ✅ 提供直观的交互反馈
  Widget _buildBottomArea(
    InCallState state,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Row(
        children: [
          // ✅ 挂断按钮 - 改进视觉反馈
          _buildCircleButton(
            onTap: () => widget.cubit.cancelDialing(),
            icon: Icons.call_end,
            bg: colorScheme.errorContainer,
            fg: colorScheme.onErrorContainer,
            shadow: true,
          ),
          const SizedBox(width: 14),
          // ✅ 语音识别状态按钮 - 优化渐变和动画
          Expanded(
            child: InkWell(
              onTap: state.isSilenceDetected
                  ? () => widget.cubit.finishAsrRecording()
                  : null,
              borderRadius: BorderRadius.circular(28),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                height: 70,
                decoration: BoxDecoration(
                  gradient: state.asrTranscript.isNotEmpty
                      ? LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.primary.withOpacity(0.75),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: state.asrTranscript.isEmpty
                      ? colorScheme.surfaceContainerHighest
                      : null,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: state.asrTranscript.isNotEmpty
                          ? colorScheme.primary.withOpacity(0.35)
                          : Colors.black.withOpacity(0.08),
                      blurRadius: state.asrTranscript.isNotEmpty ? 16 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✅ 动画图标
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child: Icon(
                          key: ValueKey(state.asrTranscript.isNotEmpty),
                          state.asrTranscript.isNotEmpty
                              ? Icons.graphic_eq
                              : Icons.mic,
                          color: state.asrTranscript.isNotEmpty
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // ✅ 优化文本样式
                      Expanded(
                        child: Text(
                          state.asrTranscript.isNotEmpty
                              ? state.isSilenceDetected
                                    ? "完成"
                                    : "聆听中"
                              : state.isWaitingForUserInput
                              ? "等待输入"
                              : "准备中",
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: state.asrTranscript.isNotEmpty
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  /// ✅ 录音状态声纹特效条（新增）
  Widget _buildRecordingWaveformBar(
    InCallState state,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final isRecording = state.isWaitingForUserInput;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      height: 40,
      decoration: BoxDecoration(
        color: isRecording
            ? colorScheme.primary.withOpacity(0.06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: state.waveformData.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: WaveformAnimationWidget(
                waveformData: state.waveformData,
                isActive: true,
                height: 40,
                waveColor: colorScheme.primary,
              ),
            )
          : isRecording
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                7,
                (i) => _buildIdlePulseBar(colorScheme.primary, i * 120),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  /// ✅ 静态等待脉冲条
  Widget _buildIdlePulseBar(Color color, int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600 + delayMs % 400),
      curve: Curves.easeInOut,
      builder: (context, value, _) {
        return Container(
          width: 3,
          height: 10 + 20 * value,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.3 + 0.4 * value),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
      onEnd: () => setState(() {}), // 触发重建实现循环动画
    );
  }

  /// ✅ 圆形按钮 - 支持阴影
  Widget _buildCircleButton({
    required VoidCallback onTap,
    required IconData icon,
    required Color bg,
    required Color fg,
    bool shadow = false,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          boxShadow: shadow
              ? [
                  BoxShadow(
                    color: bg.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Icon(icon, color: fg, size: 30),
      ),
    );
  }

  Widget _buildTopBar(
    InCallState state,
    ColorScheme colorScheme,
    ThemeData theme,
    Color themeColor,
  ) {
    final operatorName = state.operator?.name ?? 'BIPUPU 接线员';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // ✅ 状态指示器脉冲点
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: themeColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: themeColor.withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // ✅ 接线员名称（新增）
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  operatorName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: themeColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'LINE ACTIVE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: themeColor.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          // ✅ 优化ID显示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'ID: ${state.targetId}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
