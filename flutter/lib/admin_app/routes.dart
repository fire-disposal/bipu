import 'package:go_router/go_router.dart';
import 'pages/admin_main_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/login_page.dart';
import 'pages/user_management_page.dart';

/// 管理端路由配置
final GoRouter adminRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AdminMainPage(),
      routes: [
        GoRoute(path: 'login', builder: (context, state) => const LoginPage()),
        GoRoute(
          path: 'dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: 'users',
          builder: (context, state) => const UserManagementPage(),
        ),
        // TODO: 添加其他管理页面路由
        // GoRoute(path: 'devices', builder: (context, state) => const DeviceManagementPage()),
        // GoRoute(path: 'messages', builder: (context, state) => const MessageManagementPage()),
        // GoRoute(path: 'notifications', builder: (context, state) => const NotificationManagementPage()),
      ],
    ),
  ],
);
