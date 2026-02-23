import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:animate_do/animate_do.dart';

import '../logic/auth_notifier.dart';

class RegisterPage extends HookConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final nicknameController = useTextEditingController();
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);
    final successMessage = useState<String?>(null);

    void handleRegister() async {
      // 验证输入
      if (usernameController.text.isEmpty) {
        errorMessage.value = '请输入用户名';
        return;
      }

      if (passwordController.text.isEmpty) {
        errorMessage.value = '请输入密码';
        return;
      }

      if (passwordController.text.length < 6) {
        errorMessage.value = '密码长度至少为 6 位';
        return;
      }

      if (passwordController.text != confirmPasswordController.text) {
        errorMessage.value = '两次输入的密码不一致';
        return;
      }

      isLoading.value = true;
      errorMessage.value = null;
      successMessage.value = null;

      try {
        final authNotifier = ref.read(authStatusNotifierProvider.notifier);
        final success = await authNotifier.register(
          usernameController.text,
          passwordController.text,
          nickname: nicknameController.text.isEmpty
              ? null
              : nicknameController.text,
        );

        if (success) {
          successMessage.value = '注册成功！请登录';
          // 清空输入
          usernameController.clear();
          passwordController.clear();
          confirmPasswordController.clear();
          nicknameController.clear();

          // 2 秒后返回登录页面
          await Future.delayed(const Duration(seconds: 2));
          if (context.mounted) {
            Navigator.pop(context);
          }
        } else {
          errorMessage.value = '注册失败，请稍后重试';
        }
      } catch (e) {
        errorMessage.value = '注册失败：$e';
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('注册账号'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FadeInUp(
            duration: const Duration(milliseconds: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // 标题
                Text(
                  '创建账号',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '加入 Bipupu - 宇宙传讯',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                // 错误提示
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

                // 成功提示
                if (successMessage.value != null)
                  FadeIn(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              successMessage.value!,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (successMessage.value != null) const SizedBox(height: 16),

                // 用户名输入框
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '用户名 *',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShadInput(
                      controller: usernameController,
                      placeholder: const Text('请输入用户名（用于登录）'),
                      onChanged: (_) => errorMessage.value = null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '用户名将作为登录凭证',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 昵称输入框（可选）
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '昵称（可选）',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShadInput(
                      controller: nicknameController,
                      placeholder: const Text('请输入昵称'),
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
                      '密码 *',
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
                    const SizedBox(height: 4),
                    Text(
                      '至少 6 位字符',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 确认密码输入框
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '确认密码 *',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShadInput(
                      controller: confirmPasswordController,
                      placeholder: const Text('请再次输入密码'),
                      obscureText: true,
                      onChanged: (_) => errorMessage.value = null,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 注册按钮
                SizedBox(
                  width: double.infinity,
                  child: ShadButton(
                    onPressed: isLoading.value ? null : handleRegister,
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
                              Text('注册中...'),
                            ],
                          )
                        : const Text('注册'),
                  ),
                ),
                const SizedBox(height: 24),

                // 登录提示
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '已有账号？',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        '立即登录',
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
