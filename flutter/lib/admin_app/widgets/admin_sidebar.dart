import 'package:flutter/material.dart';

/// 管理端侧边栏组件
class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onItemSelected,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 1,
      extended: true,
      leading: Column(
        children: [
          const SizedBox(height: 16),
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.admin_panel_settings, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            '管理系统',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Divider(),
        ],
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('仪表盘'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: Text('用户管理'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.devices_outlined),
          selectedIcon: Icon(Icons.devices),
          label: Text('设备管理'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.message_outlined),
          selectedIcon: Icon(Icons.message),
          label: Text('消息管理'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.notifications_outlined),
          selectedIcon: Icon(Icons.notifications),
          label: Text('通知管理'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: Text('数据分析'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('系统设置'),
        ),
      ],
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('退出登录'),
                  onTap: () => _handleLogout(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    // TODO: 实现退出登录逻辑
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('退出登录功能开发中...')));
  }
}
