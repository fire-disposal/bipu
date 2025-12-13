/// 用户端应用入口文件
/// 现代蓝牙寻呼机设备用户端应用
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/core.dart';
import 'user_app/pages/home/home_page.dart';
import 'user_app/pages/message/message_list_page.dart';
import 'user_app/pages/device/device_scan_page.dart';
import 'user_app/pages/profile/profile_home_page.dart';
import 'core/utils/injected_dependencies.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化核心服务
  await _initializeCoreServices();

  // 设置系统UI样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const UserApp());
}

/// 初始化核心服务
Future<void> _initializeCoreServices() async {
  try {
    // 初始化依赖注入
    await initDependencies();

    // 初始化蓝牙服务
    await BluetoothService.instance.initialize();

    // 初始化API客户端
    await ApiClient.instance.initialize();

    Logger.info('用户端核心服务初始化完成');
  } catch (e) {
    Logger.error('用户端核心服务初始化失败: $e');
    rethrow;
  }
}

/// 用户端应用主类
class UserApp extends StatelessWidget {
  const UserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bipupu 寻呼机',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const UserAppShell(),
      builder: (context, child) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// 用户端应用外壳 - 包含底部导航和页面切换
class UserAppShell extends StatefulWidget {
  const UserAppShell({super.key});

  @override
  State<UserAppShell> createState() => _UserAppShellState();
}

class _UserAppShellState extends State<UserAppShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const MessageListPage(),
    const DeviceScanPage(),
    const ProfileHomePage(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: '首页',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.message_outlined),
      activeIcon: Icon(Icons.message),
      label: '消息',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.device_hub_outlined),
      activeIcon: Icon(Icons.device_hub),
      label: '设备',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person_outlined),
      activeIcon: Icon(Icons.person),
      label: '我的',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: _navItems,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
