import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:easy_localization/easy_localization.dart';

import 'core/state/app_state_management.dart';
import 'core/utils/interaction_optimizer.dart';
import 'core/network/network.dart';
import 'core/api/export.dart';
import 'pages/layout/main_layout.dart';
import 'pages/pager/pager_page_enhanced.dart';
import 'pages/profile/profile_page.dart';
import 'pages/profile/pages/security_page.dart';
import 'pages/profile/pages/edit_profile_page.dart';
import 'pages/profile/pages/language_page.dart';
import 'pages/common/widgets/settings_dialog.dart';
import 'pages/messages/messages_page.dart';
import 'pages/messages/pages/message_detail_page.dart';
import 'pages/messages/pages/favorites_page.dart';
import 'pages/messages/pages/message_conversation_page.dart';
import 'pages/messages/pages/subscriptions_management_page.dart';
import 'pages/messages/pages/received_messages_page.dart';
import 'pages/messages/pages/sent_messages_page.dart';
import 'pages/messages/pages/system_messages_page.dart';
import 'pages/home/pages/quick_actions/contacts_page.dart';
import 'pages/home/pages/quick_actions/user_search_page.dart';
import 'pages/profile/pages/user_detail_page.dart';
import 'core/services/im_service.dart';
import 'pages/layout/discover_page.dart';

import 'core/services/auth_service.dart';
import 'core/services/toast_service.dart';
import 'core/storage/storage_manager.dart';
import 'core/theme/app_theme_optimized.dart';
import 'core/utils/logger.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/register_page.dart';
import 'pages/profile/pages/bluetooth/bluetooth_scan_page.dart';
import 'pages/profile/pages/bluetooth/device_detail_page.dart';
import 'pages/home/pages/quick_actions/voice_test_page.dart';
import 'pages/home/home_page.dart';
import 'pages/home/pages/bluetooth_message_test.dart';

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
  await ImService().initialize();

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
        GoRoute(
          path: '/pager',
          builder: (context, state) => const PagerPageEnhanced(),
        ),
        GoRoute(
          path: '/messages',
          builder: (context, state) => const MessagesPage(),
          routes: [
            GoRoute(
              path: 'detail',
              builder: (context, state) {
                final extra = state.extra as dynamic;
                if (extra is Map) {
                  // sometimes JSON map may be passed
                  final msg = MessageResponse.fromJson(
                    Map<String, dynamic>.from(extra),
                  );
                  return MessageDetailPage(message: msg);
                }
                if (extra is MessageResponse) {
                  return MessageDetailPage(message: extra);
                }
                // Fallback: show empty scaffold
                return const Scaffold(body: Center(child: Text('消息未找到')));
              },
            ),
            GoRoute(
              path: 'received',
              builder: (context, state) => const ReceivedMessagesPage(),
            ),
            GoRoute(
              path: 'sent',
              builder: (context, state) => const SentMessagesPage(),
            ),
            GoRoute(
              path: 'system',
              builder: (context, state) => const SystemMessagesPage(),
            ),
            GoRoute(
              path: 'favorites',
              builder: (context, state) => const FavoritesPage(),
            ),
            GoRoute(
              path: 'conversation',
              builder: (context, state) {
                final peerId = state.extra as String? ?? '';
                return MessageConversationPage(peerId: peerId);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/home/contacts',
          builder: (context, state) => const ContactsPage(),
          routes: [
            GoRoute(
              path: 'search',
              builder: (context, state) => const UserSearchPage(),
            ),
          ],
        ),
        GoRoute(
          path: '/messages/subscriptions',
          builder: (context, state) => const SubscriptionsManagementPage(),
        ),
        GoRoute(
          path: '/home/voice_test',
          builder: (context, state) => const VoiceTestPage(),
        ),
        GoRoute(
          path: '/home/bluetooth_message_test',
          builder: (context, state) => const BluetoothMessageTestPage(),
        ),
        GoRoute(
          path: '/discover',
          builder: (context, state) => const DiscoverPage(),
        ),
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
              path: 'edit_profile',
              builder: (context, state) => const EditProfilePage(),
            ),
            GoRoute(
              path: 'security',
              builder: (context, state) => const SecurityPage(),
            ),
            GoRoute(
              path: 'privacy',
              builder: (context, state) {
                // 显示隐私设置对话框
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  SettingsDialog.showPrivacyDialog(context);
                });
                return const SizedBox.shrink();
              },
            ),
            GoRoute(
              path: 'notifications',
              builder: (context, state) {
                // 显示通知设置对话框
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  SettingsDialog.showNotificationsDialog(context);
                });
                return const SizedBox.shrink();
              },
            ),
            GoRoute(
              path: 'language',
              builder: (context, state) => const LanguagePage(),
            ),
            GoRoute(
              path: 'settings',
              builder: (context, state) {
                // 显示设置菜单对话框
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  SettingsDialog.showSettingsDialog(context);
                });
                return const SizedBox.shrink();
              },
            ),
            GoRoute(
              path: 'about',
              builder: (context, state) {
                // 显示关于对话框
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  SettingsDialog.showAboutDialog(context);
                });
                return const SizedBox.shrink();
              },
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
    // Chat (conversation bubble) UI removed in favor of message-based flow.
    GoRoute(
      path: '/profile/bluetooth/scan',
      builder: (context, state) => const BluetoothScanPage(),
    ),
    GoRoute(
      path: '/profile/bluetooth/device',
      builder: (context, state) => const DeviceDetailPage(),
    ),
  ],
);
