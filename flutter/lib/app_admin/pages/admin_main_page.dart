import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/core.dart';
import '../widgets/admin_scaffold.dart';
import '../state/admin_state.dart';
import '../state/dashboard_cubit.dart';
import '../state/device_management_cubit.dart';
import '../state/message_management_cubit.dart';
import '../state/notification_management_cubit.dart';
import '../state/user_management_cubit.dart';
import 'dashboard_page.dart';
import 'user_management_page.dart';
import 'device_management_page.dart';
import 'message_management_page.dart';
import 'notification_management_page.dart';

/// 管理端主页面，包含侧边栏导航和内容区域
class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  bool _isChecking = true;
  bool _isAuthenticated = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final authService = ServiceLocatorConfig.get<AuthService>();
      final isAuthenticated = authService.isAuthenticated();
      final isAdmin = await authService.isAdmin();

      if (mounted) {
        setState(() {
          _isChecking = false;
          _isAuthenticated = isAuthenticated;
          _isAdmin = isAdmin;
        });

        // 如果没有认证或不是管理员，跳转到登录页
        if (!isAuthenticated || !isAdmin) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.go('/login');
            }
          });
        }
      }
    } catch (e) {
      Logger.error('检查认证状态失败', e);
      if (mounted) {
        setState(() {
          _isChecking = false;
          _isAuthenticated = false;
          _isAdmin = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAuthenticated || !_isAdmin) {
      return const SizedBox.shrink(); // 等待跳转
    }

    return const _AdminMainPageContent();
  }
}

class _AdminMainPageContent extends StatelessWidget {
  const _AdminMainPageContent();

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: '仪表盘',
      selectedIndex: 0,
      onNavigationChanged: (index) {
        // 导航逻辑待实现
      },
      body: _buildCurrentPage(context, 0),
      actions: _buildPageActions(context, 0),
    );
  }

  String _getPageTitle(int index) {
    const titles = ['仪表盘', '用户管理', '设备管理', '消息管理', '通知管理', '数据分析', '系统设置'];
    if (index < 0 || index >= titles.length) return '仪表盘';
    return titles[index];
  }

  Widget _buildCurrentPage(BuildContext context, int selectedIndex) {
    switch (selectedIndex) {
      case 0:
        return BlocProvider(
          create: (context) => DashboardCubit(),
          child: const DashboardPage(),
        );
      case 1:
        return BlocProvider(
          create: (context) => UserManagementCubit(),
          child: const UserManagementPage(),
        );
      case 2:
        return BlocProvider(
          create: (context) => DeviceManagementCubit(),
          child: const DeviceManagementPage(),
        );
      case 3:
        return BlocProvider(
          create: (context) => MessageManagementCubit(),
          child: const MessageManagementPage(),
        );
      case 4:
        return BlocProvider(
          create: (context) => NotificationManagementCubit(),
          child: const NotificationManagementPage(),
        );
      case 5:
        return _buildAnalyticsPage(context);
      case 6:
        return _buildSettingsPage(context);
      default:
        return BlocProvider(
          create: (context) => DashboardCubit(),
          child: const DashboardPage(),
        );
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
