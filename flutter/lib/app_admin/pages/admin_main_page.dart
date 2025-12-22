import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/admin_scaffold.dart';
import '../state/admin_state.dart';
import 'dashboard_page.dart';
import 'user_management_page.dart';

/// 管理端主页面，包含侧边栏导航和内容区域
class AdminMainPage extends StatelessWidget {
  const AdminMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminNavigationCubit(),
      child: const _AdminMainPageContent(),
    );
  }
}

class _AdminMainPageContent extends StatelessWidget {
  const _AdminMainPageContent();

  @override
  Widget build(BuildContext context) {
    final navigationCubit = context.watch<AdminNavigationCubit>();

    return AdminScaffold(
      title: _getPageTitle(navigationCubit.selectedIndex),
      selectedIndex: navigationCubit.selectedIndex,
      onNavigationChanged: navigationCubit.changeIndex,
      body: _buildCurrentPage(context, navigationCubit.selectedIndex),
      actions: _buildPageActions(context, navigationCubit.selectedIndex),
    );
  }

  String _getPageTitle(int index) {
    const titles = ['仪表盘', '用户管理', '设备管理', '消息管理', '通知管理', '数据分析', '系统设置'];
    return titles[index];
  }

  Widget _buildCurrentPage(BuildContext context, int selectedIndex) {
    switch (selectedIndex) {
      case 0:
        return const DashboardPage();
      case 1:
        return const UserManagementPage();
      case 2:
        return _buildPlaceholderPage(context, '设备管理');
      case 3:
        return _buildPlaceholderPage(context, '消息管理');
      case 4:
        return _buildPlaceholderPage(context, '通知管理');
      case 5:
        return _buildAnalyticsPage(context);
      case 6:
        return _buildSettingsPage(context);
      default:
        return const DashboardPage();
    }
  }

  List<Widget>? _buildPageActions(BuildContext context, int selectedIndex) {
    switch (selectedIndex) {
      case 1: // 用户管理
        return [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddUserDialog(context),
            tooltip: '添加用户',
          ),
        ];
      case 2: // 设备管理
        return [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDeviceDialog(context),
            tooltip: '添加设备',
          ),
        ];
      case 3: // 消息管理
        return [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddMessageDialog(context),
            tooltip: '发送消息',
          ),
        ];
      case 4: // 通知管理
        return [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddNotificationDialog(context),
            tooltip: '发送通知',
          ),
        ];
      default:
        return null;
    }
  }

  Widget _buildAnalyticsPage(BuildContext context) {
    return Center(
      child: Text('数据分析页面开发中...', style: Theme.of(context).textTheme.bodyLarge),
    );
  }

  Widget _buildSettingsPage(BuildContext context) {
    return Center(
      child: Text('系统设置页面开发中...', style: Theme.of(context).textTheme.bodyLarge),
    );
  }

  Widget _buildPlaceholderPage(BuildContext context, String pageName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            '$pageName页面开发中...',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '功能正在开发中，敬请期待',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('添加用户功能开发中...')));
  }

  void _showAddDeviceDialog(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('添加设备功能开发中...')));
  }

  void _showAddMessageDialog(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('发送消息功能开发中...')));
  }

  void _showAddNotificationDialog(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('发送通知功能开发中...')));
  }
}
