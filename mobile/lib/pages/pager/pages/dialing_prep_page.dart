import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state/pager_state_machine.dart';
import '../state/pager_cubit.dart';

// ──────────────────────────────────────────────────────────────────────────────
//  拨号准备页面
//
//  职责：品牌入口 + 服务流程说明 + 开始通话按钮
//  接线员由系统在接通后随机分配，此页不展示接线员面板
// ──────────────────────────────────────────────────────────────────────────────

class DialingPrepPage extends StatelessWidget {
  final PagerCubit cubit;
  const DialingPrepPage({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PagerCubit, PagerState>(
      bloc: cubit,
      builder: (context, state) {
        if (state is! DialingPrepState) return const SizedBox.shrink();
        return _PrepView(state: state, cubit: cubit);
      },
    );
  }
}

class _PrepView extends StatelessWidget {
  final DialingPrepState state;
  final PagerCubit cubit;
  const _PrepView({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final op = state.currentOperator;
    final themeColor = op?.themeColor ?? cs.primary;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // ─── 顶部品牌标题 ───
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'BIPUPU',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.primary,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '传呼',
                        style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // ─── 视觉中心区 ───
              _HeroVisual(themeColor: themeColor, cs: cs, theme: theme),

              const Spacer(flex: 1),

              // ─── 服务说明 ───
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 18,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.keyboard_rounded,
                      text: '接通后输入目标用户号码',
                      cs: cs,
                      theme: theme,
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.mic_rounded,
                      text: '语音或文字录入传呼消息',
                      cs: cs,
                      theme: theme,
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.send_rounded,
                      text: '确认后一键发送，可续发多人',
                      cs: cs,
                      theme: theme,
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // ─── 开始通话按钮 ───
              _DialButton(
                isLoading: state.isLoading,
                themeColor: themeColor,
                theme: theme,
                cs: cs,
                onTap: () => cubit.startDialing(),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  视觉中心区
// ─────────────────────────────────────────────────────

class _HeroVisual extends StatelessWidget {
  final Color themeColor;
  final ColorScheme cs;
  final ThemeData theme;
  const _HeroVisual({
    required this.themeColor,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 外圈光晕
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: themeColor.withOpacity(0.08),
                    width: 1,
                  ),
                ),
              ),
              // 中圈
              Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: themeColor.withOpacity(0.18),
                    width: 1.5,
                  ),
                ),
              ),
              // 核心圆
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: themeColor.withOpacity(0.1),
                  border: Border.all(
                    color: themeColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.phone_in_talk_rounded,
                  size: 34,
                  color: themeColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '随机接线员接待',
          style: theme.textTheme.titleSmall?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '接通后为您随机分配一位接线员',
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────
//  信息行
// ─────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme cs;
  final ThemeData theme;
  const _InfoRow({
    required this.icon,
    required this.text,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.primary.withOpacity(0.7)),
        const SizedBox(width: 10),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────
//  开始通话按钮
// ─────────────────────────────────────────────────────

class _DialButton extends StatelessWidget {
  final bool isLoading;
  final Color themeColor;
  final ThemeData theme;
  final ColorScheme cs;
  final VoidCallback onTap;
  const _DialButton({
    required this.isLoading,
    required this.themeColor,
    required this.theme,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(32),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 62,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: themeColor,
          boxShadow: [
            BoxShadow(
              color: themeColor.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.phone_in_talk_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '呼叫接线员',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
