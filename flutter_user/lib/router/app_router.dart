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
// import '../features/bluetooth/bluetooth_message_page.dart';
import '../features/bluetooth/bluetooth_scan_page.dart';
import '../features/bluetooth/device_control_page.dart';
import '../features/home/home_page.dart';
import '../features/pager/pages/pager_page.dart';
import '../features/subscription/pages/subscription_page.dart';
import '../features/common/placeholder_page.dart';
import '../features/contacts/pages/friend_requests_page.dart';
import '../features/contacts/pages/user_search_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class UserRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: AuthService().authState,
    redirect: (context, state) {
      final authStatus = AuthService().authState.value;
      final isLoggingIn = state.uri.path == '/login';
      final isRegistering = state.uri.path == '/register';

      if (authStatus == AuthStatus.unauthenticated) {
        return (isLoggingIn || isRegistering) ? null : '/login';
      }

      if (authStatus == AuthStatus.authenticated ||
          authStatus == AuthStatus.guest) {
        if (isLoggingIn || isRegistering) {
          return '/home';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const UserLoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const UserRegisterPage(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomePage()),
          GoRoute(
            path: '/pager',
            builder: (context, state) => const PagerPage(),
          ),
          GoRoute(
            path: '/messages',
            builder: (context, state) => const ConversationListPage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
      // Other routes
      GoRoute(
        path: '/contacts',
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
      GoRoute(
        path: '/discover',
        builder: (context, state) => const DiscoverPage(),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '0';
          return ChatPage(userId: int.parse(id));
        },
      ),
      GoRoute(
        path: '/speech_test',
        builder: (context, state) => const SpeechTestPage(),
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionPage(),
      ),
      // Bluetooth Routes
      GoRoute(
        path: '/bluetooth',
        redirect: (context, state) => '/bluetooth/scan',
        routes: [
          GoRoute(
            path: 'scan',
            builder: (context, state) => const BluetoothScanPage(),
          ),
          GoRoute(
            path: 'control',
            builder: (context, state) => const DeviceControlPage(),
          ),
        ],
      ),
      // Profile Sub-routes
      GoRoute(
        path: '/profile/personal_info',
        builder: (context, state) =>
            const PlaceholderPage(title: 'Personal Info'),
      ),
      GoRoute(
        path: '/profile/security',
        builder: (context, state) =>
            const PlaceholderPage(title: 'Account Security'),
      ),
      GoRoute(
        path: '/profile/privacy',
        builder: (context, state) =>
            const PlaceholderPage(title: 'Privacy Settings'),
      ),
      GoRoute(
        path: '/profile/notifications',
        builder: (context, state) =>
            const PlaceholderPage(title: 'Notifications'),
      ),
      GoRoute(
        path: '/profile/language',
        builder: (context, state) => const PlaceholderPage(title: 'Language'),
      ),
      GoRoute(
        path: '/profile/about',
        builder: (context, state) =>
            const PlaceholderPage(title: 'About Bipupu'),
      ),
    ],
  );
}
