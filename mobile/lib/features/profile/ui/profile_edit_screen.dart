import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/design_system.dart';
import '../logic/profile_notifier.dart';
import '../../../shared/widgets/avatar_uploader.dart';


/// 个人资料编辑页面
class ProfileEditScreen extends HookConsumerWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(profileNotifierProvider);
    final theme = Theme.of(context);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nicknameController = useTextEditingController();
    final oldPasswordController = useTextEditingController();
    final newPasswordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final timezoneController = useTextEditingController();

    // 初始化表单数据
    useEffect(() {
      if (asyncUser.value != null) {
        nicknameController.text = asyncUser.value?.nickname ?? '';
        timezoneController.text = asyncUser.value?.timezone ?? 'Asia/Shanghai';
      }
      return null;
    }, [asyncUser.value]);

    // 处理保存
    Future<void> handleSave() async {
      if (!formKey.currentState!.validate()) return;

      final profileNotifier = ref.read(profileNotifierProvider.notifier);
      final success = await profileNotifier.updateProfile(
        nickname: nicknameController.text.trim(),
      );

      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('个人资料更新成功')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('更新失败，请重试')));
      }
    }

    // 处理密码修改
    Future<void> handlePasswordChange() async {
      if (oldPasswordController.text.isEmpty ||
          newPasswordController.text.isEmpty ||
          confirmPasswordController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请填写所有密码字段')));
        return;
      }

      if (newPasswordController.text != confirmPasswordController.text) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('新密码和确认密码不一致')));
        return;
      }

      final profileNotifier = ref.read(profileNotifierProvider.notifier);
      final success = await profileNotifier.updatePassword(
        oldPasswordController.text,
        newPasswordController.text,
      );

      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('密码修改成功')));
        oldPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('密码修改失败，请检查旧密码')));
      }
    }

    // 处理时区更新
    Future<void> handleTimezoneUpdate() async {
      if (timezoneController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请输入时区')));
        return;
      }

      final profileNotifier = ref.read(profileNotifierProvider.notifier);
      final success = await profileNotifier.updateTimezone(
        timezoneController.text.trim(),
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('时区已更新为: ${timezoneController.text}')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('时区更新失败')));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑个人资料'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: handleSave,
            tooltip: '保存',
          ),
        ],
      ),
      body: asyncUser.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('请先登录'));
          }

          return SingleChildScrollView(
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
                          onUploadComplete: () {
                            ref.invalidate(profileNotifierProvider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('头像上传成功')),
                            );
                          },
                          onError: (error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('头像上传失败: $error')),
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
                    ),
                    validator: (value) {
                      if (value != null && value.length > 20) {
                        return '昵称不能超过20个字符';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // 密码修改
                  Text(
                    '账号安全',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  TextFormField(
                    controller: oldPasswordController,
                    decoration: const InputDecoration(
                      labelText: '当前密码',
                      hintText: '请输入当前密码',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  TextFormField(
                    controller: newPasswordController,
                    decoration: const InputDecoration(
                      labelText: '新密码',
                      hintText: '请输入新密码',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value != null && value.length < 6) {
                        return '密码至少6位';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  TextFormField(
                    controller: confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: '确认新密码',
                      hintText: '请再次输入新密码',
                      prefixIcon: Icon(Icons.lock_clock_outlined),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: handlePasswordChange,
                      child: const Text('修改密码'),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // 时区设置
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

                  const SizedBox(height: AppSpacing.xl),

                  // 宇宙档案（预留）
                  Text(
                    '宇宙档案',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '星座: ${user.cosmicProfile?.zodiac ?? '未设置'}',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'MBTI: ${user.cosmicProfile?.mbti ?? '未设置'}',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '性别: ${user.cosmicProfile?.gender ?? '未设置'}',
                            style: theme.textTheme.bodyMedium,
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
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: AppSpacing.md),
              Text('加载失败: $error'),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => ref.invalidate(profileNotifierProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
