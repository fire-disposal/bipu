import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/services/polling_service.dart';
import 'core/services/message_forwarder.dart';
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
    final pollingService = ref.watch(pollingServiceProvider);
    final bleManager = ref.watch(bleManagerProvider);
    final messageForwarder = ref.watch(messageForwarderProvider);

    // 监听认证状态变化，启动/停止服务
    useEffect(() {
      if (authStatus == AuthStatus.authenticated) {
        // 初始化蓝牙管理器
        bleManager.initialize().catchError((e) {
          debugPrint('蓝牙管理器初始化失败: $e');
        });

        // 启动轮询服务
        pollingService.start();

        // 启动消息转发服务
        messageForwarder.start().catchError((e) {
          debugPrint('消息转发服务启动失败: $e');
        });
      } else {
        // 停止所有服务
        pollingService.stop();
        messageForwarder.stop().catchError((e) {
          debugPrint('消息转发服务停止失败: $e');
        });
      }

      return () {
        // 清理时停止所有服务
        pollingService.stop();
        messageForwarder.stop().catchError((e) {
          debugPrint('消息转发服务停止失败: $e');
        });
      };
    }, [authStatus]);

    // 监听应用生命周期状态
    useEffect(() {
      final observer = AppLifecycleObserver(
        pollingService: pollingService,
        messageForwarder: messageForwarder,
      );

      WidgetsBinding.instance.addObserver(observer);

      return () {
        WidgetsBinding.instance.removeObserver(observer);
      };
    }, [pollingService, messageForwarder]);

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
        body: Center(
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
      ),
    );
  }

  Widget _buildLoginScreen(WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ref.watch(appThemeProvider),
      home: const LoginPage(),
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
        body: IndexedStack(
          index: currentIndex.value,
          children: const [
            HomeScreen(),
            PagerScreen(),
            MessageScreen(),
            ProfileScreen(),
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
        // 应用进入后台
        pollingService.pause();
        break;
      case AppLifecycleState.inactive:
        // 应用不活跃
        break;
      case AppLifecycleState.detached:
        // 应用被销毁
        pollingService.stop();
        messageForwarder.stop().catchError((e) {
          debugPrint('消息转发服务停止失败: $e');
        });
        break;
      case AppLifecycleState.hidden:
        // 应用被隐藏
        pollingService.pause();
        break;
    }
  }
}
