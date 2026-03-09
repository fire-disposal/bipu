import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/pager_vm.dart';
import '../models/operator_model.dart';

/// 新架构接线员图鉴页面
class NewOperatorGalleryView extends StatelessWidget {
  const NewOperatorGalleryView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PagerVM>();
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final allOperators = vm.operatorService.getAllOperators();
    final unlockedCount = allOperators.where((op) => op.isUnlocked).length;
    final totalCount = allOperators.length;
    final progressPercent = (unlockedCount / totalCount * 100).toStringAsFixed(
      0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('接线员图鉴'),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 统计信息卡片
            SliverToBoxAdapter(
              child: _buildStatsCard(
                context,
                cs,
                theme,
                unlockedCount,
                totalCount,
                progressPercent,
              ),
            ),

            // 接线员网格
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final operator = allOperators[index];
                  return _buildOperatorCard(context, operator, cs, theme);
                }, childCount: allOperators.length),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  /// 构建统计信息卡片
  Widget _buildStatsCard(
    BuildContext context,
    ColorScheme cs,
    ThemeData theme,
    int unlockedCount,
    int totalCount,
    String progressPercent,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '解锁进度',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$unlockedCount',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                        Text(
                          ' / $totalCount',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: unlockedCount / totalCount,
                        strokeWidth: 8,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(cs.primary),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '$progressPercent%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建接线员卡片
  Widget _buildOperatorCard(
    BuildContext context,
    OperatorPersonality operator,
    ColorScheme cs,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: operator.isUnlocked
          ? () => _showOperatorDetail(operator, cs, theme, context)
          : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: cs.surface,
          border: Border.all(
            color: operator.isUnlocked
                ? cs.outline.withOpacity(0.5)
                : cs.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: operator.isUnlocked
              ? _buildUnlockedCard(operator, cs, theme)
              : _buildLockedCard(operator, cs, theme),
        ),
      ),
    );
  }

  /// 已解锁卡片
  Widget _buildUnlockedCard(
    OperatorPersonality operator,
    ColorScheme cs,
    ThemeData theme,
  ) {
    return Container(
      decoration: BoxDecoration(color: cs.surfaceContainerLow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 立绘区域
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 背景装饰
                Container(color: operator.themeColor.withOpacity(0.1)),
                // 图片
                operator.portraitUrl.startsWith('http')
                    ? Image.network(
                        operator.portraitUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      )
                    : Image.asset(
                        operator.portraitUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                // 渐变遮罩
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, cs.surfaceContainerLow],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 信息区域
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    operator.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: operator.themeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '已解锁',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: operator.themeColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 未解锁卡片
  Widget _buildLockedCard(
    OperatorPersonality operator,
    ColorScheme cs,
    ThemeData theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 黑影区域
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 黑影效果
                Center(
                  child: Container(
                    width: 72,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(12),
                      color: cs.onSurfaceVariant.withOpacity(0.2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_rounded,
                          color: cs.onSurfaceVariant.withOpacity(0.5),
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '未解锁',
                          style: TextStyle(
                            color: cs.onSurfaceVariant.withOpacity(0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 信息区域
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 8,
                    width: 50,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '???',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                      fontSize: 9,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示接线员详情
  void _showOperatorDetail(
    OperatorPersonality operator,
    ColorScheme cs,
    ThemeData theme,
    BuildContext context,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 立绘
                  Container(
                    width: 100,
                    height: 130,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: operator.themeColor.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: operator.themeColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: operator.portraitUrl.startsWith('http')
                          ? Image.network(
                              operator.portraitUrl,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              operator.portraitUrl,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 名字
                  Text(
                    operator.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 角色标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: operator.themeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      operator.initials,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: operator.themeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 描述
                  Text(
                    operator.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // 统计信息
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: cs.outlineVariant.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDetailStat(
                          context,
                          '${operator.conversationCount}',
                          '次对话',
                          cs.primary,
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: cs.outlineVariant,
                        ),
                        _buildDetailStat(
                          context,
                          operator.unlockedAt != null
                              ? _formatDate(operator.unlockedAt!)
                              : '-',
                          '解锁日期',
                          cs.onSurface,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 关闭按钮
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: Navigator.of(context).pop,
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.surfaceContainerHighest,
                        foregroundColor: cs.onSurface,
                        elevation: 0,
                      ),
                      child: const Text('关闭'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建统计项
  Widget _buildDetailStat(
    BuildContext context,
    String value,
    String label,
    Color valueColor,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month}.${date.day}';
  }
}
