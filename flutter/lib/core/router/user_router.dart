import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../../../features/user/auth/login_page.dart';
import '../../../features/user/auth/register_page.dart';
import '../../../features/user/home/home_page.dart';
import '../../../features/user/speech_test/speech_test_page.dart';
import '../../../features/user/bluetooth/bluetooth_message_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class UserRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: AuthService().authState,
    redirect: (context, state) {
      final authStatus = AuthService().authState.value;
      final isLoggingIn = state.uri.path == '/login';
      final isRegistering = state.uri.path == '/register';

      // 允许离线使用：移除强制登录跳转
      // if (authStatus == AuthStatus.unauthenticated) {
      //   return (isLoggingIn || isRegistering) ? null : '/login';
      // }

      if (authStatus == AuthStatus.authenticated) {
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
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/speech_test',
        builder: (context, state) => const SpeechTestPage(),
      ),
      GoRoute(
        path: '/bluetooth',
        builder: (context, state) => const BluetoothMessagePage(),
      ),
    ],
  );
}
