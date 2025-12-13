/// 管理端应用入口文件
/// 加载 admin_app 模块，提供管理功能
library;

import 'package:flutter/material.dart';
import 'core/utils/logger.dart';
import 'admin_app/pages/admin_main_page.dart';
import 'admin_app/pages/login_page.dart';

void main() {
  runApp(const AdminApp());
}

/// 管理端应用主类
class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bipupu 管理端',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AdminMainPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// 管理端应用主页（简化版，直接跳转到主页面）
class AdminAppHome extends StatelessWidget {
  const AdminAppHome({super.key});

  @override
  Widget build(BuildContext context) {
    // 直接跳转到主页面，后续可以添加登录验证逻辑
    return const AdminMainPage();
  }
}
