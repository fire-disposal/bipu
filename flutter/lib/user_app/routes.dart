import 'package:go_router/go_router.dart';
import 'pages/main_navigation_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';

/// 用户端主路由，仅指向主导航页面
final GoRouter router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const MainNavigationPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
  ],
);
