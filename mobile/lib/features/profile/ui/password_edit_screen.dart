import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/theme/design_system.dart';
import '../../../core/api/api_provider.dart';

/// 密码管理页面
class PasswordEditScreen extends HookConsumerWidget {
  const PasswordEditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final oldPasswordController = useTextEditingController();
    final newPasswordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final isLoading = useState(false);

    // 处理密码修改
    Future<void> handlePasswordChange() async {
      if (!formKey.currentState!.validate()) return;

      isLoading.value = true;

      try {
        final restClient = ref.read(restClientProvider);
        final response = await restClient.updatePassword({
          'old_password': oldPasswordController.text,
          'new_password': newPasswordController.text,
        });

        if (response.response.statusCode == 200) {
          // 清除表单
          oldPasswordController.clear();
          newPasswordController.clear();
          confirmPasswordController.clear();

          // 显示成功消息
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('密码修改成功'),
              backgroundColor: theme.colorScheme.primary,
            ),
          );

          // 延迟返回上一页
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (context.mounted) {
              Navigator.pop(context);
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('密码修改失败，请检查旧密码'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      } catch (e) {
        debugPrint('修改密码失败: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('密码修改失败，请检查网络连接'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('修改密码'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 说明文字
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            '为了账号安全，请定期修改密码',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // 当前密码
                Text(
                  '当前密码',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: oldPasswordController,
                  decoration: const InputDecoration(
                    labelText: '请输入当前密码',
                    hintText: '请输入您的当前密码',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入当前密码';
                    }
                    if (value.length < 6) {
                      return '密码至少6位';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                // 新密码
                Text(
                  '新密码',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(
                    labelText: '请输入新密码',
                    hintText: '请输入您的新密码',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入新密码';
                    }
                    if (value.length < 6) {
                      return '密码至少6位';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                // 确认新密码
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: '确认新密码',
                    hintText: '请再次输入新密码',
                    prefixIcon: Icon(Icons.lock_clock_outlined),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请确认新密码';
                    }
                    if (value != newPasswordController.text) {
                      return '两次输入的密码不一致';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.xl),

                // 密码强度提示
                Card(
                  color: theme.colorScheme.surfaceVariant,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '密码强度要求：',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text('• 至少6个字符', style: theme.textTheme.bodySmall),
                        Text(
                          '• 建议使用字母、数字和特殊字符组合',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text('• 不要使用过于简单的密码', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // 保存按钮
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ShadButton(
                    onPressed: isLoading.value ? null : handlePasswordChange,
                    child: isLoading.value
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: theme.colorScheme.onPrimary,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '确认修改密码',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // 取消按钮
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ShadButton.outline(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
