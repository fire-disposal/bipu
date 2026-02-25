import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:animate_do/animate_do.dart';
import 'package:dio/dio.dart';
import '../../../core/services/network_service.dart' as network_service;

import '../logic/auth_notifier.dart';
import 'register_page.dart';
import '../../../core/services/toast_service.dart';

import '../../../core/config/app_config.dart';
import 'login_debug_page.dart';

class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);
    final showPassword = useState(false);
    final networkStatus = ref.watch(network_service.networkStatusProvider);

    /// 检查网络连接状态
    Future<bool> checkNetworkConnection() async {
      return await network_service.NetworkUtils.checkAndShowToast(
        ref,
        noConnectionMessage: '网络连接不可用，请检查网络设置',
      );
    }

    /// 处理登录逻辑
    Future<void> handleLogin() async {
      // 验证输入
      if (usernameController.text.isEmpty) {
        ToastUtils.showError(ref, '请输入用户名');
        return;
      }

      if (passwordController.text.isEmpty) {
        ToastUtils.showError(ref, '请输入密码');
        return;
      }

      // 检查网络连接
      final hasNetwork = await checkNetworkConnection();
      if (!hasNetwork) {
        // NetworkUtils.checkAndShowToast 已经处理了提示
        return;
      }

      // 保存当前 widget 的 ref
      final currentRef = ref;
      isLoading.value = true;
      errorMessage.value = null;

      debugPrint('[LoginPage] 开始登录，用户名: ${usernameController.text}');

      try {
        final authNotifier = currentRef.read(
          authStateNotifierProvider.notifier,
        );

        // 添加超时处理
        final loginFuture = authNotifier.login(
          usernameController.text,
          passwordController.text,
        );

        final success = await loginFuture.timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('登录请求超时');
          },
        );

        // 检查 widget 是否仍然 mounted
        if (!context.mounted) {
          debugPrint('[LoginPage] Widget 已卸载，跳过后续处理');
          return;
        }

        if (success) {
          debugPrint('[LoginPage] 登录成功');
          ToastUtils.showSuccess(currentRef, '登录成功！');

          // 延迟导航，让用户看到成功提示
          await Future.delayed(const Duration(milliseconds: 500));

          // 登录成功后不需要手动导航，因为App widget会根据auth状态自动切换
          // 只需要等待状态更新即可
        } else {
          debugPrint('[LoginPage] 登录失败');
          final authState = currentRef.read(authStateNotifierProvider);
          errorMessage.value = authState.error ?? '登录失败，请检查用户名和密码';
          ToastUtils.showError(currentRef, authState.error ?? '登录失败，请检查用户名和密码');
        }
      } on TimeoutException catch (e) {
        if (!context.mounted) return;

        debugPrint('[LoginPage] 登录超时: $e');
        errorMessage.value = '登录请求超时，请检查网络连接或稍后重试';
        ToastUtils.showError(currentRef, '登录请求超时，请检查网络连接');
      } on DioException catch (e) {
        if (!context.mounted) return;

        debugPrint('[LoginPage] 网络错误: ${e.type} - ${e.message}');

        // 根据错误类型显示不同的提示
        if (e.response?.statusCode == 401) {
          errorMessage.value = '用户名或密码错误';
          ToastUtils.showError(currentRef, '用户名或密码错误');
        } else if (e.response?.statusCode == 429) {
          errorMessage.value = '登录尝试过于频繁，请稍后再试';
          ToastUtils.showError(currentRef, '登录尝试过于频繁，请稍后再试');
        } else if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          errorMessage.value = '连接超时，请检查网络连接';
          ToastUtils.showError(currentRef, '连接超时，请检查网络连接');
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage.value = '网络连接错误，请检查网络设置';
          ToastUtils.showError(currentRef, '网络连接错误，请检查网络设置');
        } else {
          final errorMsg = e.message ?? '网络错误';
          errorMessage.value = errorMsg;
          ToastUtils.showError(currentRef, '登录失败：$errorMsg');
        }
      } catch (e) {
        if (!context.mounted) return;

        debugPrint('[LoginPage] 登录异常: $e');
        final errorMsg = e.toString();

        // 解析错误信息
        if (errorMsg.contains('Invalid credentials') ||
            errorMsg.contains('用户名或密码错误')) {
          errorMessage.value = '用户名或密码错误';
          ToastUtils.showError(currentRef, '用户名或密码错误');
        } else if (errorMsg.contains('User not found')) {
          errorMessage.value = '用户不存在';
          ToastUtils.showError(currentRef, '用户不存在');
        } else if (errorMsg.contains('Connection refused')) {
          errorMessage.value = '无法连接到服务器';
          ToastUtils.showError(currentRef, '无法连接到服务器，请检查网络连接');
        } else {
          errorMessage.value = '登录失败，请稍后重试';
          ToastUtils.showError(
            currentRef,
            '登录失败：${errorMsg.split(':').last.trim()}',
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
                      obscureText: !showPassword.value,
                      onChanged: (_) => errorMessage.value = null,
                      onSubmitted: (_) => handleLogin(),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 登录按钮
                SizedBox(
                  width: double.infinity,
                  child: ShadButton(
                    onPressed: isLoading.value ? null : handleLogin,
                    child: isLoading.value
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
                ),
                const SizedBox(height: 24),

                // 显示/隐藏密码切换
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Checkbox(
                      value: showPassword.value,
                      onChanged: (value) {
                        showPassword.value = value ?? false;
                      },
                      visualDensity: VisualDensity.compact,
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

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '还没有账号？',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: isLoading.value ? null : handleRegister,
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

                // 网络状态显示（仅在调试模式显示）
                if (AppConfig.debugMode) ...[
                  const SizedBox(height: 24),
                  Divider(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '网络状态',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  networkStatus.when(
                    data: (status) {
                      final networkService = ref.read(
                        network_service.networkServiceProvider,
                      );
                      return Row(
                        children: [
                          Text(networkService.getConnectionIcon(status)),
                          const SizedBox(width: 8),
                          Text(
                            networkService.getConnectionDescription(status),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      );
                    },
                    loading: () => Text(
                      '检查网络中...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    error: (error, stack) => Text(
                      '网络状态未知',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '调试信息',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ShadButton.outline(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginDebugPage(),
                        ),
                      );
                    },
                    child: const Text('进入调试登录页'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
