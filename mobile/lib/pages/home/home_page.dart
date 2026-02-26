import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bipupu/core/network/network.dart';
import 'package:bipupu/core/network/api_exception.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _titleAnimationController;
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;

  late PageController _posterController;
  int _currentPosterIndex = 0;
  List<dynamic> _posters = [];

  @override
  void initState() {
    super.initState();

    // 标题动画控制器
    _titleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // 淡入动画
    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _titleAnimationController, curve: Curves.easeOut),
    );

    // 滑动动画
    _titleSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _titleAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // 开始动画
    _titleAnimationController.forward();

    // 初始化海报控制器
    _posterController = PageController();

    // 加载海报
    _loadPosters();
  }

  Future<void> _loadPosters() async {
    try {
      final response = await ApiClient.instance.api.posters
          .getApiPostersActive();
      setState(() {
        _posters = response;
      });
    } on ApiException catch (e) {
      debugPrint('Error loading posters: ${e.message}');
    }
  }

  @override
  void dispose() {
    _titleAnimationController.dispose();
    _posterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 顶部标题区域 - 简化为纯色背景
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Theme.of(context).colorScheme.surface
                  : Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 欢迎文本
                SlideTransition(
                  position: _titleSlideAnimation,
                  child: FadeTransition(
                    opacity: _titleFadeAnimation,
                    child: Text(
                      '欢迎回来',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // 主标题 - 只在字体上应用渐变
                SlideTransition(
                  position: _titleSlideAnimation,
                  child: FadeTransition(
                    opacity: _titleFadeAnimation,
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: isDarkMode
                            ? [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.8),
                                Theme.of(
                                  context,
                                ).colorScheme.secondary.withValues(alpha: 0.9),
                              ]
                            : [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.9),
                                Theme.of(context).colorScheme.secondary,
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'Bipupu',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // ShaderMask 需要白色基础色
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // 副标题
                SlideTransition(
                  position: _titleSlideAnimation,
                  child: FadeTransition(
                    opacity: _titleFadeAnimation,
                    child: Text(
                      '连接 · 沟通 · 发现',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 主要内容区域
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 海报轮播 - 极简设计
                if (_posters.isNotEmpty)
                  SizedBox(
                    height: 180,
                    child: PageView.builder(
                      controller: _posterController,
                      onPageChanged: (index) {
                        setState(() => _currentPosterIndex = index);
                      },
                      itemCount: _posters.length,
                      itemBuilder: (context, index) {
                        final poster = _posters[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context).colorScheme.surfaceVariant,
                          ),
                          child: Center(
                            child: Text(
                              poster.title ?? '海报',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (_posters.isNotEmpty) const SizedBox(height: 12),
                if (_posters.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _posters.length,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPosterIndex == index
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                // Device Information Card
                Card(
                  elevation: 4,
                  shadowColor: Theme.of(
                    context,
                  ).colorScheme.shadow.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '我的设备',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.bluetooth_disabled,
                                    size: 16,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '未连接',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.developer_board,
                                size: 32,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '设备控制',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '连接蓝牙设备以启用控制功能',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            context.push('/bluetooth/scan');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bluetooth_searching),
                              const SizedBox(width: 8),
                              Text(
                                '连接设备',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.4,
                  children: [
                    _buildQuickActionCard(
                      context,
                      '好友',
                      Icons.people_alt_rounded,
                      Colors.blue.shade600,
                      () => context.push('/contacts'),
                    ),
                    _buildQuickActionCard(
                      context,
                      '语音测试',
                      Icons.mic,
                      const Color.fromARGB(255, 73, 255, 97),
                      () => context.push('/voice_test'),
                    ),
                  ],
                ),

                // 添加底部间距，避免内容贴底
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
