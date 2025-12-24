import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../core/core.dart';
import 'pages/admin_pages.dart';

/// 管理端路由配置
final GoRouter adminRouter = GoRouter(
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/',
      builder: (context, state) => const AdminMainPage(),
      redirect: (context, state) async {
        // 检查认证状态和管理员权限
        final authService = ServiceLocatorConfig.get<AuthService>();
        if (!authService.isAuthenticated()) {
          return '/login';
        }

        // 检查管理员权限
        final isAdmin = await authService.isAdmin();
        if (!isAdmin) {
          Logger.warning('非管理员用户尝试访问管理端');
          return '/login';
        }

        return null; // 不重定向，允许访问
      },
      routes: [
        GoRoute(
          path: 'dashboard',
          builder: (context, state) => const DashboardPage(),
          redirect: (context, state) async {
            // 子路由也进行认证检查
            final authService = ServiceLocatorConfig.get<AuthService>();
            if (!authService.isAuthenticated()) {
              return '/login';
            }
            return null;
          },
        ),
        GoRoute(
          path: 'users',
          builder: (context, state) => const UserManagementPage(),
          redirect: (context, state) async {
            // 子路由也进行认证检查
            final authService = ServiceLocatorConfig.get<AuthService>();
            if (!authService.isAuthenticated()) {
              return '/login';
            }
            return null;
          },
        ),
        // 其他管理页面路由
        GoRoute(
          path: 'devices',
          builder: (context, state) => const DeviceManagementPage(),
          redirect: _requireAuth,
        ),
        GoRoute(
          path: 'messages',
          builder: (context, state) => const MessageManagementPage(),
          redirect: _requireAuth,
        ),
        // GoRoute(
        //   path: 'messages',
        //   builder: (context, state) => const MessageManagementPage(),
        //   redirect: _requireAuth,
        // ),
        // GoRoute(
        //   path: 'messages',
        //   builder: (context, state) => const MessageManagementPage(),
        //   redirect: _requireAuth,
        // ),
        // GoRoute(
        //   path: 'notifications',
        //   builder: (context, state) => const NotificationManagementPage(),
        //   redirect: _requireAuth,
        // ),
      ],
    ),
  ],
  redirect: (context, state) async {
    // 全局认证检查 - 排除登录页面
    if (state.matchedLocation == '/login') {
      return null; // 允许访问登录页面
    }

    // 检查认证状态
    final authService = ServiceLocatorConfig.get<AuthService>();
    if (!authService.isAuthenticated()) {
      return '/login';
    }

    // 检查管理员权限（仅对管理端主要路径）
    if (state.matchedLocation == '/' ||
        state.matchedLocation.startsWith('/dashboard') ||
        state.matchedLocation.startsWith('/users')) {
      final isAdmin = await authService.isAdmin();
      if (!isAdmin) {
        Logger.warning('非管理员用户尝试访问管理端路径: ${state.matchedLocation}');
        return '/login';
      }
    }

    return null; // 允许访问
  },
  errorBuilder: (context, state) {
    Logger.error('管理端路由错误: ${state.error}');
    return Scaffold(
      appBar: AppBar(title: const Text('页面未找到')),
      body: Center(
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
              '抱歉，请求的页面不存在',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '错误信息: ${state.error?.message ?? '未知错误'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.home),
                  label: const Text('返回首页'),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.login),
                  label: const Text('重新登录'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  },
);

/// 基础认证检查辅助函数
Future<String?> _requireAuth(BuildContext context, GoRouterState state) async {
  try {
    final authService = ServiceLocatorConfig.get<AuthService>();
    if (!authService.isAuthenticated()) {
      Logger.info('用户未认证，重定向到登录页');
      return '/login';
    }
    return null; // 认证通过
  } catch (e) {
    Logger.error('认证检查失败', e);
    return '/login'; // 出错时保守处理，重定向到登录
  }
}

/// 管理员认证检查辅助函数
Future<String?> _requireAdminAuth(
  BuildContext context,
  GoRouterState state,
) async {
  try {
    final authService = ServiceLocatorConfig.get<AuthService>();

    // 检查基础认证
    if (!authService.isAuthenticated()) {
      Logger.info('用户未认证，重定向到登录页');
      return '/login';
    }

    // 检查管理员权限
    final isAdmin = await authService.isAdmin();
    if (!isAdmin) {
      Logger.warning('非管理员用户尝试访问管理端路径: ${state.matchedLocation}');
      return '/login';
    }

    Logger.debug('管理员认证通过: ${state.matchedLocation}');
    return null; // 认证通过
  } catch (e) {
    Logger.error('管理员认证检查失败', e);
    return '/login'; // 出错时保守处理，重定向到登录
  }
}
