import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state/pager_state_machine.dart';
import '../state/pager_cubit.dart';
import '../widgets/operator_display_widget.dart';
import '../widgets/waveform_animation_widget.dart';

/// 通话中页面 (State 2 - Asymmetric Layout)
class InCallPage extends StatefulWidget {
  final PagerCubit cubit;

  const InCallPage({super.key, required this.cubit});

  @override
  State<InCallPage> createState() => _InCallPageState();
}

class _InCallPageState extends State<InCallPage> {
  final GlobalKey _operatorDisplayKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return BlocBuilder<PagerCubit, PagerState>(
      bloc: widget.cubit,
      builder: (context, state) {
        if (state is! InCallState) return const SizedBox.shrink();

        return Stack(
          children: [
            _buildBackground(colorScheme),
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(state, colorScheme, theme),

                  // 主区域：左侧立绘，右侧纯接线员台词流
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- 左侧：接线员静态/半静态区 ---
                          _buildLeftProfile(state, colorScheme, theme),

                          const SizedBox(width: 20),

                          // --- 右侧：接线员台词流堆叠 ---
                          Expanded(
                            child: _buildOperatorSpeechStream(
                              state,
                              colorScheme,
                              theme,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 底部操作区（ASR 转写在这里以小字或状态形式体现）
                  _buildBottomArea(state, colorScheme, theme),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// 构建左侧立绘区域
  Widget _buildLeftProfile(
    InCallState state,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.3,
      child: Column(
        children: [
          const SizedBox(height: 10),
          // 立绘容器：深色圆角矩形，突出科技感
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: OperatorDisplayWidget(
                key: _operatorDisplayKey,
                imageUrl: state.operatorImageUrl,
                isAnimating: state.isTtsPlaying || state.isAsrActive,
                scale: 0.9,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '接线员',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          // 声纹移动至立绘正下方，高度收紧
          if (state.isTtsPlaying || state.isAsrActive)
            WaveformAnimationWidget(
              waveformData: state.waveformData,
              isActive: true,
              waveColor: colorScheme.primary,
              height: 40,
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  /// 构建右侧纯接线员台词流
  Widget _buildOperatorSpeechStream(
    InCallState state,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    // 获取所有台词：历史台词 + 当前正在播放的台词
    final allSpeechItems = [
      ...state.operatorSpeechHistory,
      if (state.currentTtsText.isNotEmpty) state.currentTtsText,
    ];

    return ShaderMask(
      shaderCallback: (Rect rect) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black, Colors.black],
          stops: [0.0, 0.2, 1.0], // 顶部 20% 区域淡出
        ).createShader(rect);
      },
      blendMode: BlendMode.dstIn,
      child: ListView(
        reverse: true, // 新台词在下方生成，旧台词向上推
        padding: const EdgeInsets.only(top: 80, bottom: 10),
        physics: const BouncingScrollPhysics(),
        children: [
          // 从最新到最旧显示所有台词
          ...allSpeechItems.reversed.map(
            (text) => _buildSpeechBubble(
              text,
              colorScheme,
              theme,
              isCurrent: text == state.currentTtsText,
            ),
          ),
        ],
      ),
    );
  }

  /// 台词气泡
  Widget _buildSpeechBubble(
    String text,
    ColorScheme colorScheme,
    ThemeData theme, {
    required bool isCurrent,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // 当前台词有背景，历史台词仅保留微弱边框或全透明
        color: isCurrent
            ? colorScheme.primaryContainer.withOpacity(0.4)
            : Colors.transparent,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
          topLeft: Radius.circular(4),
        ),
        border: Border.all(
          color: isCurrent
              ? colorScheme.primary.withOpacity(0.5)
              : colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.6,
          fontSize: 15,
          color: isCurrent
              ? colorScheme.onSurface
              : colorScheme.onSurfaceVariant.withOpacity(0.7),
          fontWeight: isCurrent ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
    );
  }

  /// 底部集成区
  Widget _buildBottomArea(
    InCallState state,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ASR 转写显示在按钮上方，作为用户反馈，但不进气泡流
          if (state.asrTranscript.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                "“ ${state.asrTranscript} ”",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: colorScheme.primary.withOpacity(0.7),
                ),
              ),
            ),

          // 核心操作按钮
          Row(
            children: [
              _buildActionButton(
                onTap: () => widget.cubit.cancelDialing(),
                icon: Icons.call_end,
                color: colorScheme.errorContainer,
                iconColor: colorScheme.onErrorContainer,
                flex: 1,
              ),
              const SizedBox(width: 16),
              _buildActionButton(
                onTap: () => widget.cubit.finishAsrRecording(),
                icon: state.isAsrActive ? Icons.mic : Icons.mic_none,
                color: state.isAsrActive
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                iconColor: state.isAsrActive
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
                label: state.isAsrActive ? "正在聆听" : "等待响应",
                flex: 2,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    required Color iconColor,
    String? label,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 24),
              if (label != null) ...[
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground(ColorScheme colorScheme) {
    return Container(color: colorScheme.surface);
  }

  Widget _buildTopBar(
    InCallState state,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'LINE ACTIVE',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.5,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text('ID: ${state.targetId}', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
