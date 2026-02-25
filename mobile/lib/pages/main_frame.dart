import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'home/home_page.dart';
import 'pager/pager_page.dart';
import 'messages/messages_page.dart';
import 'profile/profile_page.dart';

/// 主框架页面 - 包含底部导航栏
class MainFrame extends StatefulWidget {
  const MainFrame({super.key});

  @override
  State<MainFrame> createState() => _MainFrameState();
}

class _MainFrameState extends State<MainFrame> {
  int _selectedIndex = 0;

  // 底部导航栏项目
  static const List<NavigationDestination> _navDestinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: '首页',
    ),
    NavigationDestination(
      icon: Icon(Icons.call_outlined),
      selectedIcon: Icon(Icons.call),
      label: '传呼',
    ),
    NavigationDestination(
      icon: Icon(Icons.message_outlined),
      selectedIcon: Icon(Icons.message),
      label: '消息',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outlined),
      selectedIcon: Icon(Icons.person),
      label: '我的',
    ),
  ];

  // 页面列表
  final List<Widget> _pages = [
    const HomePage(),
    const PagerPage(),
    const MessagesPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 应用栏
      appBar: AppBar(
        title: Obx(() {
          final titles = ['首页', '传呼', '消息', '我的'];
          return Text(titles[_selectedIndex]);
        }),
        centerTitle: true,
        elevation: 0,
        actions: [
          // 通知按钮
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Get.snackbar('通知', '通知功能开发中');
            },
          ),
          // 主题切换按钮
          IconButton(
            icon: Obx(() {
              final isDarkMode = Get.isDarkMode;
              return Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode);
            }),
            onPressed: () {
              Get.changeThemeMode(
                Get.isDarkMode ? ThemeMode.light : ThemeMode.dark,
              );
            },
          ),
        ],
      ),

      // 主体内容
      body: IndexedStack(index: _selectedIndex, children: _pages),

      // 底部导航栏
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: _navDestinations,
      ),

      // 悬浮操作按钮（只在传呼页面显示）
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                Get.snackbar('提示', '发起新传呼功能开发中');
              },
              child: const Icon(Icons.add_call),
              tooltip: '发起传呼',
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
