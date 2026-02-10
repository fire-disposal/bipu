import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:easy_localization/easy_localization.dart';

import 'core/state/app_state_management.dart';
import 'core/utils/interaction_optimizer.dart';
import 'features/layout/main_layout.dart';
import 'features/pager/pages/pager_page.dart';
import 'features/profile/pages/profile_page.dart';
import 'features/profile/pages/about_page.dart';
import 'features/profile/pages/language_page.dart';
import 'features/profile/pages/notifications_page.dart';
import 'features/profile/pages/privacy_page.dart';
import 'features/profile/pages/profile_edit_page.dart';
import 'features/profile/pages/security_page.dart';
import 'package:flutter_user/features/chat/pages/conversation_list_page.dart';
import 'package:flutter_user/features/chat/pages/chat_page.dart';
import 'package:flutter_user/features/chat/pages/favorites_page.dart';
import 'package:flutter_user/features/contacts/pages/contacts_page.dart';
import 'package:flutter_user/features/contacts/pages/user_search_page.dart';
import 'package:flutter_user/features/profile/pages/user_detail_page.dart';
import 'core/services/im_service.dart';
import 'features/layout/discover_page.dart';

import 'api/api.dart';
import 'core/services/auth_service.dart';
import 'core/services/toast_service.dart';
import 'core/storage/storage_manager.dart';
import 'core/theme/app_theme_optimized.dart';
import 'core/utils/logger.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/bluetooth/bluetooth_scan_page.dart';
import 'features/home/home_page.dart';

Future<void> main() async {
  // Catch errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    logger.e(
      'Flutter error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger
  Logger.root.level = Level.ALL;
  // Logger listener removed to fix analyze error
  // Logger.root.onRecord.listen((record) {});

  await StorageManager.initialize();

  // Initialize Optimizer
  await InteractionOptimizer.initialize();

  // Initialize Auth
  await AuthService().initialize();

  // Initialize IM Service
  ImService().initialize(bipupuHttp);

  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
      path: 'assets/translations',
      fallbackLocale: const Locale('zh', 'CN'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: StateProviders.providers,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: AppThemeOptimized.themeMode,
        builder: (context, themeMode, _) {
          return MaterialApp.router(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            title: 'Bipupu',
            theme: AppThemeOptimized.lightTheme,
            darkTheme: AppThemeOptimized.darkTheme,
            themeMode: themeMode,
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

    if (authStatus == AuthStatus.unknown) {
      return '/loading';
    }

    if (authStatus == AuthStatus.authenticated) {
      if (state.matchedLocation == '/' ||
          state.matchedLocation == '/loading' ||
          state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register')) {
        return '/home';
      }
      return null;
    }

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
              path: 'search',
              builder: (context, state) => const UserSearchPage(),
            ),
          ],
        ),
        GoRoute(
          path: '/discover',
          builder: (context, state) => const DiscoverPage(),
        ),
        // Subscription Page Deleted
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
          routes: [
            GoRoute(
              path: 'personal_info',
              builder: (context, state) {
                final user = AuthService().currentUser;
                return UserDetailPage(bipupuId: user?.bipupuId ?? '');
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
        return UserDetailPage(bipupuId: id);
      },
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) {
        final extra = state.extra as String?;
        return ChatPage(peerId: extra ?? '');
      },
    ),
    GoRoute(
      path: '/bluetooth/scan',
      builder: (context, state) => const BluetoothScanPage(),
    ),
  ],
);
