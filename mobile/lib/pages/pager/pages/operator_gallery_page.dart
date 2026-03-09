import 'package:flutter/material.dart';
import '../models/operator_model.dart';
import '../services/operator_service.dart';

/// 操作员图鉴页面
/// 显示所有可用的虚拟接线员，已解锁显示完整信息，未解锁显示黑影占位符
class OperatorGalleryPage extends StatefulWidget {
  final OperatorService operatorService;

  const OperatorGalleryPage({super.key, required this.operatorService});

  @override
  State<OperatorGalleryPage> createState() => _OperatorGalleryPageState();
}

class _OperatorGalleryPageState extends State<OperatorGalleryPage> {
  late List<OperatorPersonality> _allOperators;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  /// 每次进入页面时重新读取最新解锁状态（解锁后从图鉴入口进入时确保数据最新）
  void _reload() {
    setState(() {
      _allOperators = widget.operatorService.getAllOperators();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('拨号员图鉴'),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 统计信息卡片
            SliverToBoxAdapter(child: _buildStatsCard(colorScheme, theme)),

            // 操作员网格
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
                  final operator = _allOperators[index];
                  return _buildOperatorCard(operator, colorScheme, theme);
                }, childCount: _allOperators.length),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  /// 构建统计信息卡片
  Widget _buildStatsCard(ColorScheme colorScheme, ThemeData theme) {
    final unlockedCount = widget.operatorService.getUnlockedCount();
    final totalCount = _allOperators.length;
    final progressPercent = (unlockedCount / totalCount * 100).toStringAsFixed(
      0,
    );

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                        color: colorScheme.onSurfaceVariant,
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
                            color: colorScheme.primary,
                          ),
                        ),
                        Text(
                          ' / $totalCount',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
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
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '$progressPercent%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
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

  /// 构建操作员卡片
  Widget _buildOperatorCard(
    OperatorPersonality operator,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: operator.isUnlocked
          ? () => _showOperatorDetail(operator, colorScheme, theme)
          : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: colorScheme.surface,
          border: Border.all(
            color: operator.isUnlocked
                ? colorScheme.outlineVariant
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: operator.isUnlocked
              ? _buildUnlockedCard(operator, colorScheme, theme)
              : _buildLockedCard(operator, colorScheme, theme),
        ),
      ),
    );
  }

  /// 已解锁的卡片
  Widget _buildUnlockedCard(
    OperatorPersonality operator,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      decoration: BoxDecoration(color: colorScheme.surfaceContainerLow),
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
                Container(color: operator.themeColor.withValues(alpha: 0.1)),
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
                        colors: [
                          Colors.transparent,
                          colorScheme.surfaceContainerLow,
                        ],
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
                children: [
                  Text(
                    operator.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
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
                      color: operator.themeColor.withValues(alpha: 0.15),
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

  /// 未解锁的卡片（黑影风格）
  Widget _buildLockedCard(
    OperatorPersonality operator,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_rounded,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          operator.initials,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 
                              0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 锁定徽章
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.surfaceContainerHighest,
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.lock_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 信息区域
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 8,
                  width: 50,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '???',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                    fontSize: 9,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 立绘占位符
  Widget _buildPortraitPlaceholder(
    OperatorPersonality operator,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_rounded,
            size: 32,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  /// 显示操作员详细信息
  void _showOperatorDetail(
    OperatorPersonality operator,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: colorScheme.surface,
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
                          color: operator.themeColor.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: operator.themeColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: operator.portraitUrl.startsWith('http')
                          ? Image.network(
                              operator.portraitUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  _buildPortraitPlaceholder(
                                    operator,
                                    colorScheme,
                                    theme,
                                  ),
                            )
                          : Image.asset(
                              operator.portraitUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  _buildPortraitPlaceholder(
                                    operator,
                                    colorScheme,
                                    theme,
                                  ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 名字
                  Text(
                    operator.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 角色描述标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: operator.themeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      operator.initials, // Use initials or create a role field
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
                      color: colorScheme.onSurfaceVariant,
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
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDetailStat(
                          context,
                          '${operator.conversationCount}',
                          '次对话',
                          colorScheme.primary,
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: colorScheme.outlineVariant,
                        ),
                        _buildDetailStat(
                          context,
                          operator.unlockedAt != null
                              ? _formatDate(operator.unlockedAt!)
                              : '-',
                          '解锁日期',
                          colorScheme.onSurface,
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
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        foregroundColor: colorScheme.onSurface,
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
