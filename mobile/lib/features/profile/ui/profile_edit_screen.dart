import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/theme/design_system.dart';
import '../../../shared/widgets/avatar_uploader.dart';
import '../../auth/logic/auth_notifier.dart';
import '../../../core/api/api_provider.dart';
import 'password_edit_screen.dart';

/// 个人资料编辑页面
class ProfileEditScreen extends HookConsumerWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateNotifierProvider);
    final user = authState.user;
    final theme = Theme.of(context);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nicknameController = useTextEditingController();
    final timezoneController = useTextEditingController();
    final isLoading = useState(false);

    // 初始化表单数据
    useEffect(() {
      if (user != null) {
        nicknameController.text = user.nickname ?? '';
        timezoneController.text = user.timezone;
      }
      return null;
    }, [user]);

    // 处理保存
    Future<void> handleSave() async {
      if (!formKey.currentState!.validate()) return;

      isLoading.value = true;

      try {
        final restClient = ref.read(restClientProvider);
        final response = await restClient.updateUserProfile({
          'nickname': nicknameController.text.trim(),
        });

        if (response.response.statusCode == 200) {
          // 刷新用户信息
          final authNotifier = ref.read(authStateNotifierProvider.notifier);
          await authNotifier.loadUserProfile();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('个人资料更新成功'),
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
              content: const Text('更新失败，请重试'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      } catch (e) {
        debugPrint('更新个人资料失败: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('更新失败，请检查网络连接'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      } finally {
        isLoading.value = false;
      }
    }

    // 处理时区更新
    Future<void> handleTimezoneUpdate() async {
      if (timezoneController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('请输入时区'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
        return;
      }

      try {
        final restClient = ref.read(restClientProvider);
        final response = await restClient.updateTimezone({
          'timezone': timezoneController.text.trim(),
        });

        if (response.response.statusCode == 200) {
          // 刷新用户信息
          final authNotifier = ref.read(authStateNotifierProvider.notifier);
          await authNotifier.loadUserProfile();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('时区已更新为: ${timezoneController.text}'),
              backgroundColor: theme.colorScheme.primary,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('时区更新失败'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      } catch (e) {
        debugPrint('更新时区失败: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('时区更新失败，请检查网络连接'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }

    // 跳转到密码管理页面
    void openPasswordEdit() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PasswordEditScreen()),
      );
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('编辑个人资料'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text('请先登录')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑个人资料'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头像上传区域
              Center(
                child: Column(
                  children: [
                    AvatarUploader(
                      bipupuId: user.bipupuId,
                      radius: 60,
                      currentAvatarUrl: user.avatarUrl,
                      onUploadComplete: () async {
                        // 头像上传完成后刷新用户信息
                        final authNotifier = ref.read(
                          authStateNotifierProvider.notifier,
                        );
                        await authNotifier.loadUserProfile();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('头像上传成功'),
                            backgroundColor: theme.colorScheme.primary,
                          ),
                        );
                      },
                      onError: (error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('头像上传失败: $error'),
                            backgroundColor: theme.colorScheme.error,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '点击头像修改',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // 基本信息
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '基本信息',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 用户名（不可编辑）
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: const Text('用户名'),
                        subtitle: Text(user.username),
                        enabled: false,
                      ),

                      // Bipupu ID（不可编辑）
                      ListTile(
                        leading: const Icon(Icons.badge_outlined),
                        title: const Text('Bipupu ID'),
                        subtitle: Text(user.bipupuId),
                        enabled: false,
                      ),

                      // 昵称编辑
                      TextFormField(
                        controller: nicknameController,
                        decoration: const InputDecoration(
                          labelText: '昵称',
                          hintText: '请输入昵称',
                          prefixIcon: Icon(Icons.edit_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value != null && value.length > 20) {
                            return '昵称不能超过20个字符';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // 时区设置
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '偏好设置',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      TextFormField(
                        controller: timezoneController,
                        decoration: const InputDecoration(
                          labelText: '时区',
                          hintText: '例如: Asia/Shanghai',
                          prefixIcon: Icon(Icons.access_time_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: handleTimezoneUpdate,
                          child: const Text('更新时区'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // 宇宙档案
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '宇宙档案',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      ListTile(
                        leading: const Icon(Icons.star_outline),
                        title: const Text('星座'),
                        subtitle: Text(user.cosmicProfile?.zodiac ?? '未设置'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.psychology),
                        title: const Text('MBTI'),
                        subtitle: Text(user.cosmicProfile?.mbti ?? '未设置'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: const Text('性别'),
                        subtitle: Text(user.cosmicProfile?.gender ?? '未设置'),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            // TODO: 跳转到宇宙档案编辑页面
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('宇宙档案编辑功能开发中')),
                            );
                          },
                          child: const Text('编辑宇宙档案'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // 账号安全
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '账号安全',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      ListTile(
                        leading: const Icon(Icons.lock_outline),
                        title: const Text('修改密码'),
                        subtitle: const Text('定期修改密码保护账号安全'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: openPasswordEdit,
                      ),
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
                  onPressed: isLoading.value ? null : handleSave,
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
                              Icons.save_outlined,
                              color: theme.colorScheme.onPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '保存个人资料',
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
    );
  }
}
