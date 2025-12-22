import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../core/core.dart';
import 'pages/main_navigation_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';

/// 用户端路由配置
final GoRouter router = GoRouter(
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const MainNavigationPage(),
      redirect: (context, state) async {
        // 检查认证状态
        final authService = getIt<AuthService>();
        if (!authService.isAuthenticated()) {
          return '/login';
        }
        return null; // 不重定向，允许访问
      },
    ),
    // 其他需要认证的路由可以放在这里
  ],
  redirect: (context, state) async {
    // 全局认证检查 - 排除登录和注册页面
    if (state.matchedLocation == '/login' ||
        state.matchedLocation == '/register') {
      return null; // 允许访问登录和注册页面
    }

    // 检查认证状态
    final authService = getIt<AuthService>();
    if (!authService.isAuthenticated()) {
      return '/login';
    }

    return null; // 允许访问
  },
  errorBuilder: (context, state) {
    Logger.error('路由错误: ${state.error}');
    return Scaffold(
      appBar: AppBar(title: const Text('页面未找到')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('抱歉，请求的页面不存在'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    );
  },
);
