import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/services/auth_service.dart';
import '../features/auth/login_page.dart';
import '../features/home/admin_home_page.dart';
import '../features/users/user_management_page.dart';
import '../features/logs/admin_log_page.dart';
import '../features/settings/admin_settings_page.dart';
import '../features/messages/message_management_page.dart';
import '../features/subscriptions/subscription_management_page.dart';

// 私有导航键，用于不需要上下文的导航
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class AdminRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: AuthService().authState,
    redirect: (context, state) {
      final authService = AuthService();
      final authStatus = authService.authState.value;
      final isLoggingIn = state.uri.path == '/login';

      if (authStatus == AuthStatus.unauthenticated) {
        return isLoggingIn ? null : '/login';
      }

      if (authStatus == AuthStatus.authenticated) {
        final user = authService.currentUser;

        // Guard: Only allow superusers
        if (user == null || !user.isSuperuser) {
          // If user is logged in but not admin, prevent access to dashboard
          // If they are on login page, stay there (UI should handle "not authorized" feedback if needed)
          // If they are trying to access other pages, redirect to login
          return isLoggingIn ? null : '/login';
        }

        if (isLoggingIn) {
          return '/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const AdminLoginPage(),
      ),
      // 使用 ShellRoute 实现侧边栏导航布局
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return AdminShellPage(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardView()),
          ),
          GoRoute(
            path: '/users',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: UserManagementPage()),
          ),
          GoRoute(
            path: '/logs',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AdminLogPage()),
          ),
          GoRoute(
            path: '/messages',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MessageManagementPage()),
          ),
          GoRoute(
            path: '/subscriptions',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SubscriptionManagementPage()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AdminSettingsPage()),
          ),
        ],
      ),
    ],
  );
}
