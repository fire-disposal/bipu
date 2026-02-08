import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme_optimized.dart';
import 'core/storage/storage_manager.dart';
import 'core/state/app_state_management.dart';
import 'core/interactions/enhanced_interactions.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/home/home_page.dart';
import 'features/pager/pages/pager_page.dart';
import 'features/chat/pages/conversation_list_page.dart';
import 'features/profile/pages/profile_page.dart';
import 'features/profile/pages/user_detail_page.dart';
import 'features/profile/pages/profile_edit_page.dart';

import 'features/layout/main_layout.dart';
import 'features/contacts/pages/contacts_page.dart';
import 'features/contacts/pages/friend_requests_page.dart';
import 'features/contacts/pages/user_search_page.dart';
import 'features/layout/discover_page.dart';
import 'features/subscription/pages/subscription_page.dart';
import 'features/chat/pages/chat_page.dart';
import 'features/chat/pages/favorites_page.dart';
import 'features/profile/pages/security_page.dart';
import 'features/profile/pages/privacy_page.dart';
import 'features/profile/pages/notifications_page.dart';
import 'features/bluetooth/bluetooth_scan_page.dart';
import 'features/profile/pages/language_page.dart';
import 'features/profile/pages/about_page.dart';
import 'core/services/auth_service.dart';
import 'core/services/toast_service.dart';
import 'core/services/im_service.dart';
import 'api/api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化存储系统
  await StorageManager.initialize();

  // 初始化交互优化器
  await InteractionOptimizer.initialize();

  // 初始化认证服务
  await AuthService().initialize();

  // 初始化IM服务
  ImService().initialize(bipupuApi);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: StateProviders.providers,
      child: BlocBuilder<AppCubit, AppState>(
        builder: (context, appState) {
          return MaterialApp.router(
            title: 'Bipupu User',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appState.themeMode,
            locale: appState.locale,
            routerConfig: _router,
            scaffoldMessengerKey: ToastService().scaffoldMessengerKey,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  refreshListenable: AuthService().authState,
  redirect: (BuildContext context, GoRouterState state) {
    final authService = AuthService();
    final authStatus = authService.authState.value;

    // 如果正在初始化，显示加载页面
    if (authStatus == AuthStatus.unknown) {
      return '/loading';
    }

    // 如果是认证状态且当前不在主界面相关页面，进入主界面
    if (authStatus == AuthStatus.authenticated) {
      if (state.matchedLocation == '/' ||
          state.matchedLocation == '/loading' ||
          state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register')) {
        return '/home';
      }
      return null;
    }

    // 访客/离线模式已移除 - 仅处理认证与未认证两类状态

    // 如果是未认证状态且不在登录页面，进入登录页面
    if (authStatus == AuthStatus.unauthenticated) {
      if (state.matchedLocation != '/login' &&
          !state.matchedLocation.startsWith('/register')) {
        return '/login';
      }
      return null;
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/loading',
      builder: (context, state) =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    ),
    ShellRoute(
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomePage()),
        GoRoute(path: '/pager', builder: (context, state) => const PagerPage()),
        GoRoute(
          path: '/messages',
          builder: (context, state) => const ConversationListPage(),
        ),
        GoRoute(
          path: '/messages/favorites',
          builder: (context, state) => const FavoritesPage(),
        ),
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
          path: '/subscription',
          builder: (context, state) => const SubscriptionPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
          routes: [
            GoRoute(
              path: 'personal_info',
              builder: (context, state) {
                final user = AuthService().currentUser;
                return UserDetailPage(userId: user?.id ?? 0);
              },
            ),
            GoRoute(
              path: 'edit',
              builder: (context, state) => const ProfileEditPage(),
            ),
            GoRoute(
              path: 'security',
              builder: (context, state) => const SecurityPage(),
            ),
            GoRoute(
              path: 'privacy',
              builder: (context, state) => const PrivacyPage(),
            ),
            GoRoute(
              path: 'notifications',
              builder: (context, state) => const NotificationsPage(),
            ),
            GoRoute(
              path: 'language',
              builder: (context, state) => const LanguagePage(),
            ),
            GoRoute(
              path: 'about',
              builder: (context, state) => const AboutPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(path: '/login', builder: (context, state) => const UserLoginPage()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const UserRegisterPage(),
    ),
    GoRoute(
      path: '/user/detail/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return UserDetailPage(userId: int.parse(id));
      },
    ),
    GoRoute(
      path: '/chat/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ChatPage(userId: int.parse(id));
      },
    ),
    GoRoute(
      path: '/bluetooth/scan',
      builder: (context, state) => const BluetoothScanPage(),
    ),
  ],
);
