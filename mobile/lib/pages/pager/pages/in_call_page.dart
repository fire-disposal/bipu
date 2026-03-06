import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state/pager_state_machine.dart';
import '../state/pager_cubit.dart';
import '../widgets/operator_display_widget.dart';
import '../widgets/waveform_animation_widget.dart';

// ──────────────────────────────────────────────────────────────────────────────
//  InCallPage — 接通后的统一交互页面
//
//  布局结构：
//    TopBar（固定：接线员名 + 信号图标）
//    OperatorPresenceSection（Expanded：立绘 + 台词历史气泡流）
//    PhasePanel（固定高度容器：随 InCallPhase 切换面板，AnimatedSwitcher 过渡）
//
//  面板列表：
//    GreetingPanel       - 接线员问候中
//    EnterTargetPanel    - 数字键盘输入目标 ID
//    InputMessagePanel   - 语音录入消息
//    ReviewPanel         - 确认/编辑消息文本
//    SendingPanel        - 发送进行中
//    SuccessPanel        - 发送成功 + 继续/挂断
// ──────────────────────────────────────────────────────────────────────────────

class InCallPage extends StatelessWidget {
  final PagerCubit cubit;
  const InCallPage({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PagerCubit, PagerState>(
      bloc: cubit,
      // 波形动效已彻底改为纯程序动画（WaveformAnimationWidget），与音频数据无关，
      // 此处仅过滤不影响 UI 的字段变化，避免不必要重建
      buildWhen: (prev, next) {
        if (prev.runtimeType != next.runtimeType) return true;
        if (prev is! ConnectedState || next is! ConnectedState) return true;
        final p = prev;
        final n = next;
        return p.phase != n.phase ||
            p.operator != n.operator ||
            p.targetId != n.targetId ||
            p.isRecording != n.isRecording ||
            p.isConfirming != n.isConfirming ||
            p.isSending != n.isSending ||
            p.errorMessage != n.errorMessage ||
            p.operatorSpeechHistory != n.operatorSpeechHistory ||
            p.operatorCurrentSpeech != n.operatorCurrentSpeech ||
            p.sentHistory != n.sentHistory;
      },
      builder: (context, state) {
        if (state is! ConnectedState) return const SizedBox.shrink();
        return _ConnectedView(state: state, cubit: cubit);
      },
    );
  }
}

// ─────────────────────────────────────────────────────
//  顶层视图
// ─────────────────────────────────────────────────────

class _ConnectedView extends StatelessWidget {
  final ConnectedState state;
  final PagerCubit cubit;
  const _ConnectedView({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final themeColor = state.operator.themeColor;

    return Scaffold(
      backgroundColor: cs.surface,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // ① 顶部状态栏
            _TopBar(state: state, cubit: cubit, themeColor: themeColor),

            // ② 接线员区域（立绘 + 台词流）— 占据剩余空间
            Expanded(
              child: RepaintBoundary(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _OperatorPresenceSection(
                    state: state,
                    theme: theme,
                    themeColor: themeColor,
                  ),
                ),
              ),
            ),

            // ③ 相位面板容器（圆角卡片，随阶段切换内容）
            _PhasePanelContainer(
              state: state,
              cubit: cubit,
              themeColor: themeColor,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Top Bar
// ─────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final ConnectedState state;
  final PagerCubit cubit;
  final Color themeColor;
  const _TopBar({
    required this.state,
    required this.cubit,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withOpacity(0.12),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 脉冲指示点
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
          // 接线员名 + 状态文字
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.operator.name,
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
                    fontSize: 9,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          // 快捷挂断按钮（始终可见）
          TextButton.icon(
            onPressed: () => cubit.hangup(),
            icon: Icon(Icons.call_end_rounded, size: 16, color: cs.error),
            label: Text(
              '挂断',
              style: TextStyle(
                color: cs.error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              backgroundColor: cs.errorContainer.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  接线员存在区（立绘 + 台词历史）
// ─────────────────────────────────────────────────────

class _OperatorPresenceSection extends StatelessWidget {
  final ConnectedState state;
  final ThemeData theme;
  final Color themeColor;
  const _OperatorPresenceSection({
    required this.state,
    required this.theme,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    // showWaveform 由 isRecording 控制显隐；具体波形数据由 ValueListenableBuilder 独立驱动
    final showWaveform = state.isRecording;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 左栏：立绘卡（固定尺寸，避免被拉长）
        SizedBox(
          width: 104,
          child: Column(
            children: [
              // 立绘容器：固定高度，使用 AspectRatio 保持比例
              SizedBox(
                height: 104,
                width: 104,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: themeColor.withOpacity(0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: themeColor.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: OperatorDisplayWidget(
                      imageUrl: state.operator.portraitUrl,
                      isAnimating: showWaveform,
                    ),
                  ),
                ),
              ),
              // 波形条：纯程序动画，isActive=true 时自动播放，与音频数据无关
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: showWaveform ? 34 : 0,
                margin: EdgeInsets.only(top: showWaveform ? 6 : 0),
                child: showWaveform
                    ? Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: cs.primary.withOpacity(0.06),
                          border: Border.all(
                            color: cs.primary.withOpacity(0.15),
                          ),
                        ),
                        child: WaveformAnimationWidget(
                          isActive: true,
                          height: 34,
                          waveColor: themeColor,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // 右栏：台词气泡流
        Expanded(
          child: _SpeechHistoryStream(
            history: state.operatorSpeechHistory,
            theme: theme,
            themeColor: themeColor,
          ),
        ),
      ],
    );
  }
}

/// 台词历史气泡流（ShaderMask 渐变淡入）
class _SpeechHistoryStream extends StatelessWidget {
  final List<String> history;
  final ThemeData theme;
  final Color themeColor;
  const _SpeechHistoryStream({
    required this.history,
    required this.theme,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    if (history.isEmpty) {
      return Center(
        child: Text(
          '等待接线员...',
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.outline.withOpacity(0.4),
          ),
        ),
      );
    }
    // 预先计算一次，避免 itemBuilder 中 O(n²) 的 reversed.toList()[index]
    final reversedHistory = history.reversed.toList();
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black],
        stops: [0.0, 0.18],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: ListView.builder(
        reverse: true,
        padding: const EdgeInsets.only(top: 32, bottom: 4),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final text = reversedHistory[index];
          final isCurrent = index == 0;
          if (isCurrent) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: themeColor.withOpacity(0.28),
                  width: 1.5,
                ),
              ),
              child: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              ),
            );
          }
          return Container(
            margin: const EdgeInsets.only(bottom: 10, left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cs.outlineVariant.withOpacity(0.18),
                width: 0.8,
              ),
            ),
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  相位面板容器（AnimatedSwitcher 切换）
// ─────────────────────────────────────────────────────

class _PhasePanelContainer extends StatelessWidget {
  final ConnectedState state;
  final PagerCubit cubit;
  final Color themeColor;
  const _PhasePanelContainer({
    required this.state,
    required this.cubit,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          ),
        ),
        child: _buildPanel(context),
      ),
    );
  }

  Widget _buildPanel(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    switch (state.phase) {
      case InCallPhase.greeting:
        return _GreetingPanel(
          key: const ValueKey('greeting'),
          cubit: cubit,
          cs: cs,
          theme: theme,
        );
      case InCallPhase.enteringTarget:
        return _EnterTargetPanel(
          key: const ValueKey('enterTarget'),
          state: state,
          cubit: cubit,
          cs: cs,
          theme: theme,
          themeColor: themeColor,
        );
      case InCallPhase.inputtingMessage:
        return _InputMessagePanel(
          key: const ValueKey('inputMsg'),
          state: state,
          cubit: cubit,
          cs: cs,
          theme: theme,
          themeColor: themeColor,
        );
      case InCallPhase.reviewing:
        return _ReviewPanel(
          key: const ValueKey('review'),
          state: state,
          cubit: cubit,
          cs: cs,
          theme: theme,
          themeColor: themeColor,
        );
      case InCallPhase.sending:
        return _SendingPanel(
          key: const ValueKey('sending'),
          cs: cs,
          theme: theme,
        );
      case InCallPhase.sentSuccess:
        return _SuccessPanel(
          key: const ValueKey('success'),
          state: state,
          cubit: cubit,
          cs: cs,
          theme: theme,
          themeColor: themeColor,
        );
    }
  }
}

// ─────────────────────────────────────────────────────
//  Panel 1: 问候中（带骨架屏）
// ─────────────────────────────────────────────────────

class _GreetingPanel extends StatelessWidget {
  final PagerCubit cubit;
  final ColorScheme cs;
  final ThemeData theme;
  const _GreetingPanel({
    super.key,
    required this.cubit,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 骨架屏加载指示器
          _buildLoadingSkeleton(cs, theme),
          const SizedBox(height: 20),
          _HangupButton(cubit: cubit, cs: cs, theme: theme),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton(ColorScheme cs, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 加载动画 + 文字
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '接线员上线中，请稍候...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 骨架屏：模拟面板内容
        _SkeletonLine(width: double.infinity, height: 50, cs: cs),
        const SizedBox(height: 8),
        _SkeletonLine(width: double.infinity, height: 36, cs: cs),
      ],
    );
  }
}

/// 骨架屏占位行
class _SkeletonLine extends StatelessWidget {
  final double? width;
  final double height;
  final ColorScheme cs;

  const _SkeletonLine({this.width, required this.height, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Panel 2: 输入目标 ID（数字键盘）
// ─────────────────────────────────────────────────────

class _EnterTargetPanel extends StatelessWidget {
  final ConnectedState state;
  final PagerCubit cubit;
  final ColorScheme cs;
  final ThemeData theme;
  final Color themeColor;
  const _EnterTargetPanel({
    super.key,
    required this.state,
    required this.cubit,
    required this.cs,
    required this.theme,
    required this.themeColor,
  });

  void _onDigit(String d) {
    if (state.isConfirming) return;
    if (state.targetId.length >= 12) return;
    cubit.updateInCallTargetId(state.targetId + d);
  }

  void _onBackspace() {
    if (state.isConfirming) return;
    if (state.targetId.isEmpty) return;
    cubit.updateInCallTargetId(
      state.targetId.substring(0, state.targetId.length - 1),
    );
  }

  void _onClear() {
    if (state.isConfirming) return;
    cubit.updateInCallTargetId('');
  }

  @override
  Widget build(BuildContext context) {
    final id = state.targetId;
    final hasId = id.isNotEmpty;
    final hasError = state.errorMessage != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ID 显示区
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: hasError
                  ? cs.errorContainer.withOpacity(0.3)
                  : cs.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasError
                    ? cs.error.withOpacity(0.5)
                    : (hasId
                          ? themeColor.withOpacity(0.4)
                          : cs.outlineVariant.withOpacity(0.3)),
                width: hasId ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  hasId ? id : '请输入对方的传呼号',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: hasId ? cs.onSurface : cs.outline.withOpacity(0.4),
                    letterSpacing: hasId ? 5 : 0,
                  ),
                ),
                if (hasError) ...[
                  const SizedBox(height: 4),
                  Text(
                    state.errorMessage!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          // 数字键盘（紧凑版）
          _CompactNumpad(
            onDigit: _onDigit,
            onBackspace: _onBackspace,
            onClear: _onClear,
            cs: cs,
            theme: theme,
          ),
          const SizedBox(height: 10),
          // 确认按钮
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: (hasId && !state.isConfirming)
                  ? () => cubit.confirmInCallTargetId()
                  : null,
              icon: state.isConfirming
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
                      ),
                    )
                  : const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(
                state.isConfirming ? '查询中...' : '确认号码',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: themeColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 紧凑数字键盘
class _CompactNumpad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final ColorScheme cs;
  final ThemeData theme;
  const _CompactNumpad({
    required this.onDigit,
    required this.onBackspace,
    required this.onClear,
    required this.cs,
    required this.theme,
  });

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['C', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row
                .map(
                  (label) => _NumpadKey(
                    label: label,
                    onDigit: onDigit,
                    onBackspace: onBackspace,
                    onClear: onClear,
                    cs: cs,
                    theme: theme,
                  ),
                )
                .toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _NumpadKey extends StatelessWidget {
  final String label;
  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final ColorScheme cs;
  final ThemeData theme;
  const _NumpadKey({
    required this.label,
    required this.onDigit,
    required this.onBackspace,
    required this.onClear,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isFunc = label == 'C' || label == '⌫';
    return InkWell(
      onTap: () {
        if (label == 'C')
          onClear();
        else if (label == '⌫')
          onBackspace();
        else
          onDigit(label);
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 72,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(12),
          color: isFunc
              ? Colors.transparent
              : cs.surfaceContainerHighest.withOpacity(0.4),
          border: isFunc
              ? null
              : Border.all(color: cs.outlineVariant.withOpacity(0.4)),
        ),
        child: Center(
          child: isFunc
              ? Icon(
                  label == '⌫'
                      ? Icons.backspace_rounded
                      : Icons.delete_sweep_rounded,
                  size: 22,
                  color: label == 'C'
                      ? cs.error.withOpacity(0.8)
                      : cs.onSurfaceVariant,
                )
              : Text(
                  label,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: cs.onSurface,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Panel 3: 语音 / 文字录入消息
// ─────────────────────────────────────────────────────

class _InputMessagePanel extends StatelessWidget {
  final ConnectedState state;
  final PagerCubit cubit;
  final ColorScheme cs;
  final ThemeData theme;
  final Color themeColor;
  const _InputMessagePanel({
    super.key,
    required this.state,
    required this.cubit,
    required this.cs,
    required this.theme,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isRecording = state.isRecording;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ASR 实时转写区（transcript 通过 ValueNotifier 驱动，不触发父级重建）
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 60, maxHeight: 96),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isRecording
                  ? cs.primaryContainer.withOpacity(0.35)
                  : cs.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isRecording
                    ? cs.primary.withOpacity(0.4)
                    : cs.outlineVariant.withOpacity(0.25),
                width: isRecording ? 1.5 : 1,
              ),
            ),
            child: ValueListenableBuilder<String>(
              valueListenable: cubit.asrTranscriptNotifier,
              builder: (context, transcript, _) {
                if (transcript.isNotEmpty) {
                  return Text(
                    transcript,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  );
                }
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
                      size: 26,
                      color: isRecording
                          ? cs.primary
                          : cs.onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isRecording ? '正在聆听...' : '点击麦克风开始说话',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isRecording ? cs.primary : cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // 控制行：挂断 | 大麦克风 | 键盘
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 挂断
              _SmallCircleButton(
                icon: Icons.call_end_rounded,
                bg: cs.errorContainer,
                fg: cs.onErrorContainer,
                label: '挂断',
                theme: theme,
                onTap: () => cubit.hangup(),
              ),
              // 大麦克风按钮
              GestureDetector(
                onTap: () {
                  if (isRecording) {
                    cubit.finishAsrRecording();
                  } else {
                    cubit.startVoiceRecording();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isRecording ? cs.error : themeColor,
                    boxShadow: [
                      BoxShadow(
                        color: (isRecording ? cs.error : themeColor)
                            .withOpacity(0.4),
                        blurRadius: isRecording ? 20 : 12,
                        spreadRadius: isRecording ? 4 : 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
              // 键盘
              _SmallCircleButton(
                icon: Icons.keyboard_alt_rounded,
                bg: cs.secondaryContainer,
                fg: cs.onSecondaryContainer,
                label: '键盘',
                theme: theme,
                onTap: () => cubit.switchToTextInput(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Panel 4: 确认 / 编辑消息
// ─────────────────────────────────────────────────────

class _ReviewPanel extends StatefulWidget {
  final ConnectedState state;
  final PagerCubit cubit;
  final ColorScheme cs;
  final ThemeData theme;
  final Color themeColor;
  const _ReviewPanel({
    super.key,
    required this.state,
    required this.cubit,
    required this.cs,
    required this.theme,
    required this.themeColor,
  });

  @override
  State<_ReviewPanel> createState() => _ReviewPanelState();
}

class _ReviewPanelState extends State<_ReviewPanel> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.state.messageContent);
    _focus = FocusNode();
    // 监听输入和焦点变化：仅局部 setState 刷新按鈕状态和边框样式，
    // 不再通过 cubit.updateMessageContent 触发全局 Bloc 重建
    _ctrl.addListener(_onLocalChange);
    _focus.addListener(_onLocalChange);
    // 自动聚焦（进入面板后弹出键盘）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _onLocalChange() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(_ReviewPanel old) {
    super.didUpdateWidget(old);
    // 仅在外部（cubit）修改内容时同步（防止打字时被覆盖）
    if (widget.state.messageContent != old.state.messageContent &&
        widget.state.messageContent != _ctrl.text) {
      _ctrl.text = widget.state.messageContent;
      _ctrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _ctrl.text.length),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final theme = widget.theme;
    final themeColor = widget.themeColor;
    final hasError = widget.state.errorMessage != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 消息编辑框
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _focus.hasFocus
                    ? themeColor.withOpacity(0.5)
                    : cs.outlineVariant.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              maxLines: 3,
              minLines: 2,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: InputBorder.none,
                hintText: '请输入或编辑要发送的消息...',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
              onChanged: null,
            ),
          ),
          // 错误提示
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 14, color: cs.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.state.errorMessage!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          // 操作行
          Row(
            children: [
              // 重新录音
              OutlinedButton.icon(
                onPressed: () => widget.cubit.backToVoiceInput(),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('重录'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 发送
              Expanded(
                child: FilledButton.icon(
                  onPressed: _ctrl.text.trim().isNotEmpty
                      ? () => widget.cubit.sendMessage(message: _ctrl.text)
                      : null,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text(
                    '确认发送',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Panel 5: 发送中
// ─────────────────────────────────────────────────────

class _SendingPanel extends StatelessWidget {
  final ColorScheme cs;
  final ThemeData theme;
  const _SendingPanel({super.key, required this.cs, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '正在发送消息...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Panel 6: 发送成功
// ─────────────────────────────────────────────────────

class _SuccessPanel extends StatelessWidget {
  final ConnectedState state;
  final PagerCubit cubit;
  final ColorScheme cs;
  final ThemeData theme;
  final Color themeColor;
  const _SuccessPanel({
    super.key,
    required this.state,
    required this.cubit,
    required this.cs,
    required this.theme,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final last = state.sentHistory.isNotEmpty ? state.sentHistory.last : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 成功卡片
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: cs.onPrimaryContainer,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '消息已发送至 ${last?.targetId ?? state.targetId}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (last != null)
                        Text(
                          last.content,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 本次已发送计数
          if (state.sentHistory.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '本次通话已发送 ${state.sentHistory.length} 条消息',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 14),
          // 操作行
          Row(
            children: [
              // 挂断
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => cubit.hangup(),
                  icon: const Icon(Icons.call_end_rounded, size: 16),
                  label: const Text('挂断'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.error,
                    side: BorderSide(color: cs.error.withOpacity(0.6)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 继续发送给另一人
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => cubit.continueToNextRecipient(),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: const Text(
                    '继续发送',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  共享组件
// ─────────────────────────────────────────────────────

/// 全宽挂断按钮（问候阶段使用）
class _HangupButton extends StatelessWidget {
  final PagerCubit cubit;
  final ColorScheme cs;
  final ThemeData theme;
  const _HangupButton({
    required this.cubit,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => cubit.hangup(),
        icon: const Icon(Icons.call_end_rounded, size: 18),
        label: const Text(
          '挂断通话',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.error,
          side: BorderSide(color: cs.error.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

/// 带标签的小圆形按钮（语音输入面板使用）
class _SmallCircleButton extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final String label;
  final ThemeData theme;
  final VoidCallback onTap;
  const _SmallCircleButton({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.label,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: fg, size: 22),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// 静态等待脉冲条（无波形数据但正在录音时显示）
class _IdlePulseBars extends StatefulWidget {
  final Color color;
  const _IdlePulseBars({required this.color});

  @override
  State<_IdlePulseBars> createState() => _IdlePulseBarsState();
}

class _IdlePulseBarsState extends State<_IdlePulseBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final height = 6.0 + 14.0 * (((_ctrl.value + i * 0.18) % 1.0));
            return Container(
              width: 3,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.5 + 0.4 * _ctrl.value),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
