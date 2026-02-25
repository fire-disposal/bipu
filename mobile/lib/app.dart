import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/services/polling_service.dart';
import 'core/services/message_forwarder.dart';
import 'core/services/toast_service.dart';
import 'core/services/token_refresh_service.dart';
import 'core/bluetooth/ble_manager.dart';

import 'features/home/ui/home_screen.dart';
import 'features/pager/ui/pager_screen.dart';
import 'features/message/ui/message_screen.dart';
import 'features/profile/ui/profile_screen.dart';
import 'features/auth/logic/auth_notifier.dart';
import 'features/auth/ui/login_page.dart';

/// 应用根 Widget
class App extends HookConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = useState(0);
    final authState = ref.watch(authStateNotifierProvider);
    final authStatus = authState.status;

    // 简化服务管理：只在需要时启动服务
    useEffect(() {
      debugPrint('[App] 认证状态: $authStatus');

      if (authStatus == AuthStatus.authenticated) {
        debugPrint('[App] 用户已认证，启动必要服务...');

        // 启动轮询服务
        final pollingService = ref.read(pollingServiceProvider);
        pollingService.start();

        // 启动Token自动刷新服务
        final tokenRefreshService = ref.read(tokenRefreshServiceProvider);
        tokenRefreshService.start();

        debugPrint('[App] 核心服务已启动');
      } else if (authStatus == AuthStatus.unauthenticated) {
        debugPrint('[App] 用户未认证，停止服务...');

        // 停止轮询服务
        final pollingService = ref.read(pollingServiceProvider);
        pollingService.stop();

        // 停止Token自动刷新服务
        final tokenRefreshService = ref.read(tokenRefreshServiceProvider);
        tokenRefreshService.stop();

        debugPrint('[App] 服务已停止');
      }

      return () {
        // 清理时停止轮询服务
        final pollingService = ref.read(pollingServiceProvider);
        pollingService.stop();
      };
    }, [authStatus]);

    // 监听应用生命周期状态
    useEffect(() {
      final observer = AppLifecycleObserver(ref);

      WidgetsBinding.instance.addObserver(observer);

      return () {
        WidgetsBinding.instance.removeObserver(observer);
      };
    }, []);

    // 根据认证状态显示不同内容
    debugPrint('[App] 构建Widget，认证状态: $authStatus');

    if (authStatus == AuthStatus.unknown) {
      debugPrint('[App] 显示加载屏幕');
      return _buildLoadingScreen(context, ref);
    }

    if (authStatus == AuthStatus.unauthenticated) {
      debugPrint('[App] 显示登录屏幕');
      return _buildLoginScreen(ref);
    }

    debugPrint('[App] 显示主界面');
    return _buildMainLayout(context, ref, currentIndex);
  }

  Widget _buildLoadingScreen(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ref.watch(appThemeProvider),
      home: Scaffold(
        body: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Bipupu - 宇宙传讯',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const ToastContainer(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginScreen(WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ref.watch(appThemeProvider),
      home: Scaffold(
        body: Stack(children: const [LoginPage(), ToastContainer()]),
      ),
    );
  }

  Widget _buildMainLayout(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<int> currentIndex,
  ) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ref.watch(appThemeProvider),
      home: Scaffold(
        body: Stack(
          children: [
            IndexedStack(
              index: currentIndex.value,
              children: const [
                HomeScreen(),
                PagerScreen(),
                MessageScreen(),
                ProfileScreen(),
              ],
            ),
            const ToastContainer(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex.value,
          onTap: (index) => currentIndex.value = index,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
          selectedLabelStyle: const TextStyle(fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: '首页',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.call_outlined),
              activeIcon: Icon(Icons.call),
              label: '传唤台',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_outlined),
              activeIcon: Icon(Icons.chat),
              label: '消息',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined),
              activeIcon: Icon(Icons.person),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }
}

/// 应用生命周期观察器
class AppLifecycleObserver extends WidgetsBindingObserver {
  final WidgetRef ref;

  AppLifecycleObserver(this.ref);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('应用生命周期状态变化: $state');

    final authState = ref.read(authStateNotifierProvider);
    if (!authState.isAuthenticated) {
      return; // 用户未认证，不处理生命周期状态
    }

    final pollingService = ref.read(pollingServiceProvider);

    switch (state) {
      case AppLifecycleState.resumed:
        // 应用回到前台
        pollingService.resume();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // 应用进入后台或不活跃
        pollingService.pause();
        break;
      case AppLifecycleState.detached:
        // 应用被销毁
        pollingService.stop();
        break;
    }
  }
}
