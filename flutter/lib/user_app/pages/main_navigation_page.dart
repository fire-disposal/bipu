import 'package:flutter/material.dart';
import 'home/home_tab.dart';
import 'call/call_tab.dart';
import 'message/message_tab.dart';
import 'profile/profile_tab.dart';

/// 主导航页面，包含底部导航栏与四大主页面
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({Key? key}) : super(key: key);

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeTab(),
    const CallTab(),
    const MessageTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

/// 自定义底部导航栏，传呼台按钮更大更突出
/// 采用现代设计，中央按钮艺术化处理
class _CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _CustomBottomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color selected = Theme.of(context).colorScheme.primary;
    final Color unselected = Colors.grey;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景装饰
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _NavBarItem(
                icon: Icons.home_outlined,
                label: '首页',
                selected: currentIndex == 0,
                onTap: () => onTap(0),
                iconSize: 26,
              ),

              // 传呼台按钮 - 中央突出显示
              _PagerButton(selected: currentIndex == 1, onTap: () => onTap(1)),

              _NavBarItem(
                icon: Icons.chat_bubble_outline,
                label: '消息',
                selected: currentIndex == 2,
                onTap: () => onTap(2),
                iconSize: 26,
              ),
              _NavBarItem(
                icon: Icons.person_outline,
                label: '我的',
                selected: currentIndex == 3,
                onTap: () => onTap(3),
                iconSize: 26,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 传呼台按钮 - 艺术化设计
class _PagerButton extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _PagerButton({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color baseColor = selected ? theme.colorScheme.primary : Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: selected
                ? [baseColor, baseColor.withOpacity(0.8)]
                : [Colors.grey.shade300, Colors.grey.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: baseColor.withOpacity(0.3),
              blurRadius: selected ? 20 : 10,
              spreadRadius: selected ? 2 : 0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 外圈装饰
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),

            // 内圈装饰
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.white.withOpacity(0.2), Colors.transparent],
                ),
              ),
            ),

            // 主要图标
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.radio, size: 28, color: Colors.white),
                const SizedBox(height: 2),
                Text(
                  '传呼台',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // 选中时的脉冲动画
            if (selected)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.2),
                duration: const Duration(seconds: 2),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: baseColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// 导航栏项目组件
class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double iconSize;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.iconSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color selectedColor = theme.colorScheme.primary;
    final Color unselectedColor = Colors.grey.shade600;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: selected ? selectedColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selected
                      ? selectedColor.withOpacity(0.1)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: selected ? selectedColor : unselectedColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? selectedColor : unselectedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
