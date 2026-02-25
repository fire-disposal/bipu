import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/auth_controller.dart';

import 'pages/home_page.dart';

/// 极简应用根Widget - GetX风格
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final authController = AuthController.to;

      // 检查登录状态
      if (authController.isLoading.value) {
        return _buildLoadingScreen();
      }

      if (!authController.isLoggedIn.value) {
        return HomePage();
      }

      return HomePage();
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
