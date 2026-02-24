import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:animate_do/animate_do.dart';

import '../logic/auth_notifier.dart';
import 'register_page.dart';
import '../../../core/services/toast_service.dart';

class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);

    void handleLogin() async {
      if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
        ToastUtils.showError(ref, '请输入用户名和密码');
        return;
      }

      // 保存当前 widget 的 ref
      final currentRef = ref;
      isLoading.value = true;
      debugPrint('[LoginPage] 开始登录，用户名: ${usernameController.text}');

      try {
        final authNotifier = currentRef.read(
          authStatusNotifierProvider.notifier,
        );
        final success = await authNotifier.login(
          usernameController.text,
          passwordController.text,
        );

        // 检查 widget 是否仍然 mounted
        if (!context.mounted) {
          debugPrint('[LoginPage] Widget 已卸载，跳过后续处理');
          return;
        }

        if (success) {
          debugPrint('[LoginPage] 登录成功');
          ToastUtils.showSuccess(currentRef, '登录成功！');
          // 登录成功后不需要手动导航，因为App widget会根据auth状态自动切换
          // 只需要等待状态更新即可
        } else {
          debugPrint('[LoginPage] 登录失败');
          ToastUtils.showError(currentRef, '登录失败，请检查用户名和密码');
        }
      } catch (e) {
        // 检查 widget 是否仍然 mounted
        if (!context.mounted) {
          debugPrint('[LoginPage] Widget 已卸载，跳过错误处理');
          return;
        }

        debugPrint('[LoginPage] 登录异常: $e');
        final errorMsg = e.toString();
        if (errorMsg.contains('Connection refused') ||
            errorMsg.contains('网络连接错误')) {
          ToastUtils.showError(currentRef, '无法连接到服务器，请检查网络连接');
        } else if (errorMsg.contains('timeout')) {
          ToastUtils.showError(currentRef, '连接超时，请稍后重试');
        } else {
          ToastUtils.showError(
            currentRef,
            '登录失败：${e.toString().split(':').last.trim()}',
          );
        }
      } finally {
        // 检查 widget 是否仍然 mounted 且 isLoading 仍然有效
        if (context.mounted && isLoading.value) {
          isLoading.value = false;
        } else {
          debugPrint('[LoginPage] Widget 已卸载或 isLoading 已 dispose，跳过状态更新');
        }
      }
    }

    void handleRegister() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RegisterPage()),
      );
    }

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

                // 错误提示（保留原有错误提示，但主要使用Toast）
                if (errorMessage.value != null)
                  FadeIn(
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
                              errorMessage.value!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (errorMessage.value != null) const SizedBox(height: 16),

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
                      onChanged: (_) => errorMessage.value = null,
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
                    ShadInput(
                      controller: passwordController,
                      placeholder: const Text('请输入密码'),
                      obscureText: true,
                      onChanged: (_) => errorMessage.value = null,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 登录按钮
                SizedBox(
                  width: double.infinity,
                  child: ShadButton(
                    onPressed: handleLogin,
                    enabled: !isLoading.value,
                    child: isLoading.value
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('登录中...'),
                            ],
                          )
                        : const Text('登录'),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '还没有账号？',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: handleRegister,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
