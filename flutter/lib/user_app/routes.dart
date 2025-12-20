import 'package:go_router/go_router.dart';
import 'pages/main_navigation_page.dart';

/// 用户端主路由，仅指向主导航页面
final GoRouter router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const MainNavigationPage()),
  ],
);
