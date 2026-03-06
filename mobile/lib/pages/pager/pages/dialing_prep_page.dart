import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state/pager_state_machine.dart';
import '../state/pager_cubit.dart';
import '../models/operator_model.dart';

// ──────────────────────────────────────────────────────────────────────────────
//  拨号准备页面（简化版）
//
//  职责：展示当前接线员 + 提供"开始通话"入口
//  目标号码改为在接通后由接线员语音引导输入，此页不再需要数字键盘
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
              // ─── 顶部标题行 ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '拨号传呼',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  // 接线员选择功能暂时禁用，拨通后随机分配
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      op != null ? op.name : '随机接线员',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 1),

              // ─── 神秘接线员占位符 ───
              _MysteryOperatorCard(cs: cs, theme: theme),

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
//  接线员选择器 Chip
// ─────────────────────────────────────────────────────

class _OperatorSelectorChip extends StatelessWidget {
  final DialingPrepState state;
  final PagerCubit cubit;
  final ColorScheme cs;
  const _OperatorSelectorChip({
    required this.state,
    required this.cubit,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final op = state.currentOperator;
    return InkWell(
      onTap: () => _showOperatorSheet(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: cs.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_outline,
              size: 15,
              color: cs.onSecondaryContainer,
            ),
            const SizedBox(width: 6),
            Text(
              op?.name ?? '随机接线员',
              style: TextStyle(
                color: cs.onSecondaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: cs.onSecondaryContainer,
            ),
          ],
        ),
      ),
    );
  }

  void _showOperatorSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _OperatorPickerSheet(cubit: cubit, cs: cs),
    );
  }
}

/// 接线员选择器底部弹窗
class _OperatorPickerSheet extends StatelessWidget {
  final PagerCubit cubit;
  final ColorScheme cs;
  const _OperatorPickerSheet({required this.cubit, required this.cs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '选择接线员',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: OperatorFactory.defaultOperators.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, i) {
                final op = OperatorFactory.defaultOperators[i];
                return GestureDetector(
                  onTap: () {
                    cubit.selectOperator(op);
                    Navigator.pop(context);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: op.themeColor.withOpacity(0.15),
                          border: Border.all(color: op.themeColor, width: 2),
                          image: DecorationImage(
                            image: op.portraitUrl.startsWith('assets')
                                ? AssetImage(op.portraitUrl) as ImageProvider
                                : NetworkImage(op.portraitUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        op.name,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        op.description,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  神秘接线员占位符（拨通前不显示具体是谁）
// ─────────────────────────────────────────────────────

class _MysteryOperatorCard extends StatelessWidget {
  final ColorScheme cs;
  final ThemeData theme;
  const _MysteryOperatorCard({required this.cs, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: cs.surfaceContainer,
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // 神秘立绘区
          Container(
            width: 80,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: cs.surfaceContainerHighest,
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.question_mark_rounded,
                  size: 28,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 6),
                Text(
                  '???',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '未知接线员',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '拨通后随机分配一位接线员为您服务',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.casino_outlined,
                        size: 12,
                        color: cs.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '随机分配',
                        style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  接线员展示卡（接通后展示）
// ─────────────────────────────────────────────────────

class _OperatorCard extends StatelessWidget {
  final OperatorPersonality? op;
  final Color themeColor;
  final ColorScheme cs;
  final ThemeData theme;
  const _OperatorCard({
    required this.op,
    required this.themeColor,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (op == null) return const SizedBox(height: 200);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: cs.surfaceContainer,
        border: Border.all(color: themeColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // 立绘
          Container(
            width: 80,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: themeColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildPortrait(themeColor),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  op!.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: themeColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  op!.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: themeColor.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.headset_mic_rounded,
                        size: 13,
                        color: themeColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '待机中',
                        style: TextStyle(
                          color: themeColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortrait(Color themeColor) {
    Widget fallback = Container(
      color: themeColor.withOpacity(0.1),
      child: Center(
        child: Text(
          op!.initials,
          style: TextStyle(
            color: themeColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
    if (op == null) return fallback;
    final url = op!.portraitUrl;
    if (url.startsWith('assets')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
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
