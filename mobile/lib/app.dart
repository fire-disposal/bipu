import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/auth_controller.dart';
import 'pages/login_page.dart';
import 'pages/main_frame.dart';

/// 极简应用根Widget - GetX风格
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final authController = AuthController.to;

      print(
        '🔄 App页面重建 - isLoading: ${authController.isLoading}, isLoggedIn: ${authController.isLoggedIn}',
      );

      // 检查登录状态
      if (authController.isLoading) {
        print('⏳ 显示加载屏幕');
        return _buildLoadingScreen();
      }

      if (!authController.isLoggedIn) {
        print('🔐 用户未登录，显示登录页面');
        return LoginPage();
      }

      print('🏠 用户已登录，显示主框架');
      return const MainFrame();
    });
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Get.theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text('Bipupu - 宇宙传讯', style: Get.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '加载中...',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: Get.theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
