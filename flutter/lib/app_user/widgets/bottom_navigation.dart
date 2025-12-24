import 'package:flutter/material.dart';

/// 用户端底部导航栏
class UserBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const UserBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context,
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: '首页',
            index: 0,
          ),
          _buildNavItem(
            context,
            icon: Icons.message_outlined,
            activeIcon: Icons.message,
            label: '消息',
            index: 1,
          ),
          _buildNavItem(
            context,
            icon: Icons.devices_outlined,
            activeIcon: Icons.devices,
            label: '设备',
            index: 2,
          ),
          _buildNavItem(
            context,
            icon: Icons.person_outlined,
            activeIcon: Icons.person,
            label: '我的',
            index: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = currentIndex == index;
    final color = isActive
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Flexible(
      fit: FlexFit.tight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onIndexChanged(index),
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: kBottomNavigationBarHeight,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isActive ? activeIcon : icon, color: color, size: 24),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
