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
    final authStatus = ref.watch(authStatusNotifierProvider);

    // 使用 read 而不是 watch 来获取服务实例，避免不必要的重建
    final pollingService = ref.read(pollingServiceProvider);
    final bleManager = ref.read(bleManagerProvider);
    final messageForwarder = ref.read(messageForwarderProvider);

    // 初始化Token刷新管理器
    useEffect(() {
      TokenRefreshManager.initialize(ref);
      return () {
        TokenRefreshManager.stop();
      };
    }, []);

    // 监听认证状态变化，启动/停止服务
    useEffect(() {
      // 保存服务引用，避免在异步操作中使用可能变化的引用
      final currentPollingService = pollingService;
      final currentBleManager = bleManager;
      final currentMessageForwarder = messageForwarder;

      if (authStatus == AuthStatus.authenticated) {
        // 初始化蓝牙管理器
        currentBleManager.initialize().catchError((e) {
          debugPrint('蓝牙管理器初始化失败: $e');
        });

        // 启动轮询服务
        currentPollingService.start();

        // 启动消息转发服务
        currentMessageForwarder.start().catchError((e) {
          debugPrint('消息转发服务启动失败: $e');
        });

        // 启动Token自动刷新服务
        final tokenRefreshService = ref.read(tokenRefreshServiceProvider);
        tokenRefreshService.start();
      } else if (authStatus == AuthStatus.unauthenticated) {
        // 只在未认证状态时停止服务
        currentPollingService.stop();
        currentMessageForwarder.stop().catchError((e) {
          debugPrint('消息转发服务停止失败: $e');
        });

        // 停止Token自动刷新服务
        final tokenRefreshService = ref.read(tokenRefreshServiceProvider);
        tokenRefreshService.stop();
      }

      return () {
        // 清理时停止所有服务
        currentPollingService.stop();
        currentMessageForwarder.stop().catchError((e) {
          debugPrint('消息转发服务停止失败: $e');
        });
      };
    }, [authStatus]);

    // 监听应用生命周期状态
    useEffect(() {
      // 保存服务引用
      final currentPollingService = pollingService;
      final currentMessageForwarder = messageForwarder;

      final observer = AppLifecycleObserver(
        pollingService: currentPollingService,
        messageForwarder: currentMessageForwarder,
      );

      WidgetsBinding.instance.addObserver(observer);

      return () {
        WidgetsBinding.instance.removeObserver(observer);
        // 清理服务资源
        pollingService.dispose();
      };
    }, []);

    // 根据认证状态显示不同内容
    if (authStatus == AuthStatus.unknown) {
      return _buildLoadingScreen(context, ref);
    }

    if (authStatus == AuthStatus.unauthenticated) {
      return _buildLoginScreen(ref);
    }

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
  final PollingService pollingService;
  final MessageForwarder messageForwarder;

  AppLifecycleObserver({
    required this.pollingService,
    required this.messageForwarder,
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('应用生命周期状态变化: $state');

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
        messageForwarder.stop().catchError((e) {
          debugPrint('消息转发服务停止失败: $e');
        });
        break;
    }
  }
}
