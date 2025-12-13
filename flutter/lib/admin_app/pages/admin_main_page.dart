import 'package:flutter/material.dart';
import '../widgets/admin_scaffold.dart';
import 'dashboard_page.dart';
import 'user_management_page.dart';
// TODO: 导入其他管理页面
// import 'device_management_page.dart';
// import 'message_management_page.dart';
// import 'notification_management_page.dart';

/// 管理端主页面，包含侧边栏导航和内容区域
class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  int _selectedIndex = 0;
  String _pageTitle = '仪表盘';

  // 页面标题映射
  final List<String> _pageTitles = [
    '仪表盘',
    '用户管理',
    '设备管理',
    '消息管理',
    '通知管理',
    '数据分析',
    '系统设置',
  ];

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: _pageTitle,
      selectedIndex: _selectedIndex,
      onNavigationChanged: _onNavigationChanged,
      body: _buildCurrentPage(),
      actions: _buildPageActions(),
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardPage();
      case 1:
        return const UserManagementPage();
      case 2:
        return _buildPlaceholderPage('设备管理');
      case 3:
        return _buildPlaceholderPage('消息管理');
      case 4:
        return _buildPlaceholderPage('通知管理');
      case 5:
        return _buildAnalyticsPage();
      case 6:
        return _buildSettingsPage();
      default:
        return const DashboardPage();
    }
  }

  List<Widget>? _buildPageActions() {
    switch (_selectedIndex) {
      case 1: // 用户管理
        return [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddUserDialog(),
            tooltip: '添加用户',
          ),
        ];
      case 2: // 设备管理
        return [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDeviceDialog(),
            tooltip: '添加设备',
          ),
        ];
      case 3: // 消息管理
        return [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddMessageDialog(),
            tooltip: '发送消息',
          ),
        ];
      case 4: // 通知管理
        return [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddNotificationDialog(),
            tooltip: '发送通知',
          ),
        ];
      default:
        return null;
    }
  }

  void _onNavigationChanged(int index) {
    setState(() {
      _selectedIndex = index;
      _pageTitle = _pageTitles[index];
    });
  }

  Widget _buildAnalyticsPage() {
    return const Center(child: Text('数据分析页面开发中...'));
  }

  Widget _buildSettingsPage() {
    return const Center(child: Text('系统设置页面开发中...'));
  }

  Widget _buildPlaceholderPage(String pageName) {
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    // TODO: 实现添加用户对话框
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('添加用户功能开发中...')));
  }

  void _showAddDeviceDialog() {
    // TODO: 实现添加设备对话框
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('添加设备功能开发中...')));
  }

  void _showAddMessageDialog() {
    // TODO: 实现发送消息对话框
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('发送消息功能开发中...')));
  }

  void _showAddNotificationDialog() {
    // TODO: 实现发送通知对话框
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('发送通知功能开发中...')));
  }
}
