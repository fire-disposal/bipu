import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/constants.dart';

class DailyFortunePage extends StatefulWidget {
  const DailyFortunePage({super.key});

  @override
  State<DailyFortunePage> createState() => _DailyFortunePageState();
}

class _DailyFortunePageState extends State<DailyFortunePage> {
  bool _isLoading = false;
  Map<String, dynamic>? _fortuneData;

  @override
  void initState() {
    super.initState();
    // TODO: Logger.logUserAction('进入每日运势页面'); 需补充 logger 方法实现或移除
    _loadFortune();
  }

  Future<void> _loadFortune() async {
    setState(() {
      _isLoading = true;
    });

    // 模拟加载运势数据
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _fortuneData = {
        'date': DateTime.now(),
        'overall': {'rating': 4, 'description': '今天是充满机遇的一天，保持积极的心态，好运将会眷顾你。'},
        'love': {
          'rating': 5,
          'description': '爱情运势极佳，单身者有机会遇到心仪的对象，有伴侣者感情会更加甜蜜。',
        },
        'career': {'rating': 3, 'description': '工作上可能会遇到一些小挑战，但只要保持冷静，都能顺利解决。'},
        'wealth': {'rating': 4, 'description': '财运不错，可能会有意外的收入，但要注意理性消费。'},
        'health': {'rating': 4, 'description': '身体状况良好，适合进行户外运动，保持规律的作息。'},
        'lucky': {
          'numbers': [3, 7, 21],
          'colors': ['蓝色', '金色'],
          'direction': '东南',
        },
        'advice': '保持乐观的心态，相信自己的能力，勇敢面对挑战。',
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('今日运势'),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {
                  // TODO: 分享运势
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('分享功能开发中')));
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _isLoading ? null : _loadFortune,
              ),
            ],
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_fortuneData != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateHeader(),
                    const SizedBox(height: 24),
                    _buildOverallFortune(),
                    const SizedBox(height: 24),
                    _buildFortuneCategories(),
                    const SizedBox(height: 24),
                    _buildLuckyInfo(),
                    const SizedBox(height: 24),
                    _buildAdviceCard(),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                  ],
                ),
              ),
            )
          else
            SliverFillRemaining(child: _buildErrorState()),
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    final date = _fortuneData!['date'] as DateTime;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((255 * 0.2).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${date.year}年${date.month}月${date.day}日',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getWeekdayName(date.weekday),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withAlpha((255 * 0.9).round()),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((255 * 0.2).round()),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Colors.white.withAlpha((255 * 0.9).round()),
                ),
                const SizedBox(width: 4),
                Text(
                  'AI运势',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withAlpha((255 * 0.9).round()),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallFortune() {
    final overall = _fortuneData!['overall'] as Map<String, dynamic>;
    final rating = overall['rating'] as int;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '综合运势',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                _buildRatingStars(rating),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              overall['description'] as String,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFortuneCategories() {
    final categories = [
      {'key': 'love', 'title': '爱情运势', 'icon': Icons.favorite},
      {'key': 'career', 'title': '事业运势', 'icon': Icons.work},
      {'key': 'wealth', 'title': '财富运势', 'icon': Icons.attach_money},
      {'key': 'health', 'title': '健康运势', 'icon': Icons.health_and_safety},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '运势详情',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...categories.map(
          (category) => _FortuneCategoryItem(
            title: category['title'] as String,
            icon: category['icon'] as IconData,
            data: _fortuneData![category['key']] as Map<String, dynamic>,
          ),
        ),
      ],
    );
  }

  Widget _buildLuckyInfo() {
    final lucky = _fortuneData!['lucky'] as Map<String, dynamic>;
    final numbers = lucky['numbers'] as List<int>;
    final colors = lucky['colors'] as List<String>;
    final direction = lucky['direction'] as String;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '幸运信息',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _LuckyInfoItem(
                    icon: Icons.format_list_numbered,
                    title: '幸运数字',
                    content: numbers.join(', '),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LuckyInfoItem(
                    icon: Icons.palette,
                    title: '幸运颜色',
                    content: colors.join(', '),
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _LuckyInfoItem(
              icon: Icons.navigation,
              title: '幸运方向',
              content: direction,
              color: AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdviceCard() {
    final advice = _fortuneData!['advice'] as String;

    return Card(
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withAlpha((255 * 0.3).round()),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '今日建议',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              advice,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              context.push('/cosmos-comm-settings');
            },
            icon: const Icon(Icons.settings_outlined),
            label: const Text('运势设置'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: 订阅运势推送
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('订阅功能开发中')));
            },
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('订阅推送'),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: index < rating
              ? AppColors.warning
              : Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withAlpha((255 * 0.3).round()),
          size: 20,
        );
      }),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            '获取运势失败',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请检查网络连接后重试',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadFortune,
            icon: const Icon(Icons.refresh),
            label: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  String _getWeekdayName(int weekday) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[weekday - 1];
  }
}

class _FortuneCategoryItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Map<String, dynamic> data;

  const _FortuneCategoryItem({
    required this.title,
    required this.icon,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final rating = data['rating'] as int;
    final description = data['description'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getRatingColor(rating).withAlpha((255 * 0.1).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: _getRatingColor(rating)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      _buildSmallRatingStars(rating),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 5:
        return AppColors.success;
      case 4:
        return AppColors.info;
      case 3:
        return AppColors.warning;
      default:
        return AppColors.error;
    }
  }

  Widget _buildSmallRatingStars(int rating) {
    return Builder(
      builder: (context) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return Icon(
              index < rating ? Icons.star : Icons.star_border,
              color: index < rating
                  ? AppColors.warning
                  : Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(
                      (255 * 0.3).round(),
                    ),
              size: 16,
            );
          }),
        );
      },
    );
  }
}

class _LuckyInfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color color;

  const _LuckyInfoItem({
    required this.icon,
    required this.title,
    required this.content,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.1).round()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
