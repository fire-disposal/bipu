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
                isAnimating: state.isTtsPlaying,
              ),
            ),
          ),
          if (state.isTtsPlaying)
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
  Widget _buildOperatorHistoryStream(
    InCallState state,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final history = [
      ...state.operatorSpeechHistory,
      if (state.currentTtsText.isNotEmpty) state.currentTtsText,
    ];

    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black],
        stops: [0.0, 0.2],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: ListView.builder(
        reverse: true,
        padding: const EdgeInsets.only(top: 40),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final text = history.reversed.toList()[index];
          final isCurrent = text == state.currentTtsText;
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

  Widget _buildMiniBubble(
    String text,
    ColorScheme colorScheme,
    ThemeData theme, {
    required bool isCurrent,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isCurrent
            ? colorScheme.primaryContainer.withOpacity(0.4)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? colorScheme.primary.withOpacity(0.2)
              : colorScheme.outlineVariant.withOpacity(0.1),
        ),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isCurrent
              ? colorScheme.onSurface
              : colorScheme.onSurfaceVariant,
          fontSize: 13,
        ),
      ),
    );
  }

  /// 3. 用户消息缓冲区 (中间下半部大区域)
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
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: state.asrTranscript.isEmpty
            ? Text(
                "请说话...",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline.withOpacity(0.5),
                ),
              )
            : SingleChildScrollView(
                child: Text(
                  state.asrTranscript,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
      ),
    );
  }

  /// 4. 底部操作区 (挂断 + 语音)
  Widget _buildBottomArea(
    InCallState state,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(
        children: [
          _buildCircleButton(
            onTap: () => widget.cubit.cancelDialing(),
            icon: Icons.call_end,
            bg: colorScheme.errorContainer,
            fg: colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: () => widget.cubit.finishAsrRecording(),
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 64,
                decoration: BoxDecoration(
                  color: state.isAsrActive
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: state.isAsrActive
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.4),
                            blurRadius: 12,
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        state.isAsrActive ? Icons.graphic_eq : Icons.mic,
                        color: state.isAsrActive
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        state.isAsrActive ? "正在聆听" : "等待响应",
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: state.isAsrActive
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
