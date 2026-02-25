import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:animate_do/animate_do.dart';

import '../controllers/auth_controller.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final showPassword = false.obs;

  void login() {
    final auth = AuthController.to;

    if (usernameController.text.isEmpty) {
      Get.snackbar('提示', '请输入用户名');
      return;
    }

    if (passwordController.text.isEmpty) {
      Get.snackbar('提示', '请输入密码');
      return;
    }

    auth.login(usernameController.text, passwordController.text);
  }

  void goToRegister() {
    Get.toNamed('/register');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FadeInUp(
            duration: const Duration(milliseconds: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                Text(
                  '欢迎来到',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bipupu - 宇宙传讯',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 48),

                // 用户名输入框
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '用户名',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShadInput(
                      controller: usernameController,
                      placeholder: const Text('请输入用户名'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 密码输入框
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '密码',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => ShadInput(
                        controller: passwordController,
                        placeholder: const Text('请输入密码'),
                        obscureText: !showPassword.value,
                        onSubmitted: (_) => login(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 登录按钮
                Obx(() {
                  final auth = AuthController.to;
                  return SizedBox(
                    width: double.infinity,
                    child: ShadButton(
                      onPressed: auth.isLoading.value ? null : login,
                      child: auth.isLoading.value
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('登录中...'),
                              ],
                            )
                          : const Text('登录'),
                    ),
                  );
                }),
                const SizedBox(height: 24),

                // 显示/隐藏密码切换
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Obx(
                      () => Checkbox(
                        value: showPassword.value,
                        onChanged: (value) {
                          showPassword.value = value ?? false;
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    Text(
                      '显示密码',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 注册链接
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '还没有账号？',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: goToRegister,
                      child: Text(
                        '立即注册',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                // 错误提示
                Obx(() {
                  final auth = AuthController.to;
                  if (auth.error.value.isEmpty) return const SizedBox();
                  return FadeIn(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              auth.error.value,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
