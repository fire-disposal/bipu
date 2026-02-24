import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logic/auth_notifier.dart';
import '../../../core/services/toast_service.dart';

class LoginDebugPage extends HookConsumerWidget {
  const LoginDebugPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isLoading = useState(false);
    final debugLogs = useState<List<String>>([]);
    final authStatus = ref.watch(authStatusNotifierProvider);

    void addLog(String message) {
      debugLogs.value = [
        '${DateTime.now().toIso8601String().substring(11, 19)}: $message',
        ...debugLogs.value.take(20),
      ];
    }

    void showToast(String message, {bool isError = false}) {
      if (!context.mounted) {
        debugPrint('[LoginDebugPage] Widget 已卸载，跳过显示Toast: $message');
        return;
      }
      if (isError) {
        ToastUtils.showError(ref, message);
      } else {
        ToastUtils.showInfo(ref, message);
      }
    }

    void handleLogin() async {
      if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
        addLog('请输入用户名和密码');
        showToast('请输入用户名和密码', isError: true);
        return;
      }

      // 保存当前 widget 的 mounted 状态和 ref
      final currentRef = ref;
      isLoading.value = true;
      addLog('开始登录...');
      showToast('正在登录...');

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
          debugPrint('[LoginDebugPage] Widget 已卸载，跳过后续处理');
          return;
        }

        if (success) {
          addLog('登录成功');
          showToast('登录成功');
        } else {
          addLog('登录失败');
          showToast('登录失败，请检查用户名和密码', isError: true);
        }
      } catch (e) {
        // 检查 widget 是否仍然 mounted
        if (!context.mounted) {
          debugPrint('[LoginDebugPage] Widget 已卸载，跳过错误处理');
          return;
        }

        addLog('登录异常: $e');
        final errorMsg = e.toString();
        if (errorMsg.contains('Connection refused') ||
            errorMsg.contains('网络连接错误')) {
          showToast('无法连接到服务器，请检查网络连接', isError: true);
        } else if (errorMsg.contains('timeout')) {
          showToast('连接超时，请稍后重试', isError: true);
        } else {
          showToast(
            '登录失败：${e.toString().split(':').last.trim()}',
            isError: true,
          );
        }
      } finally {
        // 检查 widget 是否仍然 mounted 且 isLoading 仍然有效
        if (context.mounted && isLoading.value) {
          isLoading.value = false;
        } else {
          debugPrint('[LoginDebugPage] Widget 已卸载或 isLoading 已 dispose，跳过状态更新');
        }
      }
    }

    void handleCheckAuth() async {
      if (!context.mounted) return;
      addLog('检查认证状态...');
      showToast('正在检查认证状态...');
      final authNotifier = ref.read(authStatusNotifierProvider.notifier);
      await authNotifier.debugCheckAuth();

      if (!context.mounted) return;
      addLog('当前认证状态: $authStatus');
      showToast('当前认证状态: $authStatus');
    }

    void handleCheckStorage() async {
      addLog('检查本地存储...');
      showToast('正在检查本地存储...');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final refreshToken = prefs.getString('refresh_token');
      final expiry = prefs.getInt('token_expiry');
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      addLog('access_token: ${token != null ? "存在" : "不存在"}');
      if (token != null) {
        addLog('token长度: ${token.length}');
        addLog(
          'token前20位: ${token.substring(0, token.length > 20 ? 20 : token.length)}...',
        );
      }
      addLog('refresh_token: ${refreshToken != null ? "存在" : "不存在"}');
      addLog('token_expiry: $expiry');
      addLog('当前时间戳: $now');
      if (expiry != null) {
        addLog('token是否过期: ${expiry <= now ? "是" : "否"}');
        addLog('过期时间差: ${expiry - now}秒');
      }
      showToast('本地存储检查完成');
    }

    void handleClearStorage() async {
      if (!context.mounted) return;
      addLog('清除本地存储...');
      showToast('正在清除本地存储...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('token_expiry');

      if (!context.mounted) return;
      addLog('本地存储已清除');
      showToast('本地存储已清除');
    }

    return Scaffold(
      appBar: AppBar(title: const Text('登录调试页面')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 调试信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '调试信息',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('当前认证状态: $authStatus'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ShadButton(
                            onPressed: handleCheckAuth,
                            child: const Text('检查认证状态'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ShadButton(
                            onPressed: handleCheckStorage,
                            child: const Text('检查本地存储'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ShadButton(
                            onPressed: handleClearStorage,
                            child: const Text('清除本地存储'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 登录表单
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '登录测试',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 用户名输入框
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '用户名',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        ShadInput(
                          controller: usernameController,
                          placeholder: const Text('请输入用户名'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 密码输入框
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '密码',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        ShadInput(
                          controller: passwordController,
                          placeholder: const Text('请输入密码'),
                          obscureText: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 调试日志
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '调试日志',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => debugLogs.value = [],
                          child: const Text('清空日志'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        reverse: true,
                        itemCount: debugLogs.value.length,
                        itemBuilder: (context, index) {
                          final log = debugLogs.value[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Text(
                              log,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
