import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/services/auth_service.dart';
import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/chat/pages/conversation_list_page.dart';
import '../features/chat/pages/chat_page.dart';
import '../features/contacts/pages/contacts_page.dart';
import '../features/profile/pages/profile_page.dart';
import '../features/layout/main_layout.dart';
import '../features/layout/discover_page.dart';
import '../features/speech_test/speech_test_page.dart';
import '../features/bluetooth/bluetooth_scan_page.dart';
import '../features/bluetooth/device_control_page.dart';
import '../features/home/home_page.dart';
import '../features/pager/pages/pager_page.dart';
import '../features/subscription/pages/subscription_page.dart';
import '../features/common/placeholder_page.dart';
import '../features/contacts/pages/friend_requests_page.dart';
import '../features/tts_test/tts_test_page.dart';
import '../features/contacts/pages/user_search_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class UserRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    // 确保 AuthService().authState 是一个 ValueListenable (如 ValueNotifier)
    refreshListenable: AuthService().authState,
    redirect: (context, state) {
      final authStatus = AuthService().authState.value;
      final isLoggingIn = state.uri.path == '/login';
      final isRegistering = state.uri.path == '/register';

      // 1. 未登录处理
      if (authStatus == AuthStatus.unauthenticated) {
        return (isLoggingIn || isRegistering) ? null : '/login';
      }

      // 2. 已登录但访问登录页处理
      if (authStatus == AuthStatus.authenticated ||
          authStatus == AuthStatus.guest) {
        if (isLoggingIn || isRegistering) {
          return '/home';
        }
      }

      return null;
    },
    routes: [
      // --- 登录注册 (全屏) ---
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const UserLoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const UserRegisterPage(),
      ),

      // --- 主应用外壳 (带底部导航栏) ---
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/pager',
            name: 'pager',
            builder: (context, state) => const PagerPage(),
          ),
          GoRoute(
            path: '/messages',
            name: 'messages',
            builder: (context, state) => const ConversationListPage(),
          ),
          // Profile 及其子路由嵌套在 ShellRoute 中
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
            routes: [
              GoRoute(
                path: 'personal_info',
                builder: (context, state) =>
                    const PlaceholderPage(title: 'Personal Info'),
              ),
              GoRoute(
                path: 'security',
                builder: (context, state) =>
                    const PlaceholderPage(title: 'Account Security'),
              ),
              GoRoute(
                path: 'privacy',
                builder: (context, state) =>
                    const PlaceholderPage(title: 'Privacy Settings'),
              ),
              GoRoute(
                path: 'notifications',
                builder: (context, state) =>
                    const PlaceholderPage(title: 'Notifications'),
              ),
              GoRoute(
                path: 'language',
                builder: (context, state) =>
                    const PlaceholderPage(title: 'Language'),
              ),
              GoRoute(
                path: 'about',
                builder: (context, state) =>
                    const PlaceholderPage(title: 'About Bipupu'),
              ),
            ],
          ),
        ],
      ),

      // --- 独立功能页 (全屏，不带底部导航) ---

      // 聊天页：使用 tryParse 保证安全
      GoRoute(
        path: '/chat/:id',
        name: 'chat',
        builder: (context, state) {
          final idParam = state.pathParameters['id'] ?? '0';
          return ChatPage(userId: int.tryParse(idParam) ?? 0);
        },
      ),

      // 联系人
      GoRoute(
        path: '/contacts',
        name: 'contacts',
        builder: (context, state) => const ContactsPage(),
        routes: [
          GoRoute(
            path: 'requests',
            builder: (context, state) => const FriendRequestsPage(),
          ),
          GoRoute(
            path: 'search',
            builder: (context, state) => const UserSearchPage(),
          ),
        ],
      ),

      // 发现
      GoRoute(
        path: '/discover',
        name: 'discover',
        builder: (context, state) => const DiscoverPage(),
      ),

      // 蓝牙设备扫描页
      GoRoute(
        path: '/bluetooth/scan',
        name: 'bluetooth_scan',
        builder: (context, state) => const BluetoothScanPage(),
      ),

      // 蓝牙设备控制页
      GoRoute(
        path: '/bluetooth/control',
        name: 'bluetooth_control',
        builder: (context, state) => const DeviceControlPage(),
      ),

      // 测试与订阅
      GoRoute(
        path: '/speech_test',
        builder: (context, state) => const SpeechTestPage(),
      ),
      GoRoute(
        path: '/tts_test',
        builder: (context, state) => const TtsTestPage(),
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionPage(),
      ),
    ],
    // 错误处理 (可选)
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  );
}
