import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:animate_do/animate_do.dart';

import '../../../core/theme/design_system.dart';
import '../../../shared/models/user_model.dart';
import '../logic/profile_notifier.dart';
import '../../auth/logic/auth_notifier.dart';
import '../../auth/ui/login_page.dart';
import 'settings_page.dart';
import 'profile_edit_screen.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/avatar_uploader.dart';

/// 个人中心主页
class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(profileNotifierProvider);
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final settings = ref.watch(settingsListProvider);

    void handleLogin() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }

    void handleLogout() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认登出'),
          content: const Text('确定要登出当前账号吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                '登出',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await ref.read(authStatusNotifierProvider.notifier).logout();
      }
    }

    void openSettings() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsPage()),
      );
    }

    void openProfileEdit() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: openSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.lg),

              // 用户信息卡片
              FadeInDown(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: isLoggedIn
                      ? asyncUser.when(
                          data: (user) => _buildUserInfoCard(
                            context,
                            user,
                            handleLogout,
                            ref,
                            openProfileEdit,
                          ),
                          loading: () => _buildLoadingCard(context),
                          error: (_, __) => _buildUserInfoCard(
                            context,
                            null,
                            handleLogout,
                            ref,
                            openProfileEdit,
                          ),
                        )
                      : _buildGuestCard(context, handleLogin),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // 设置项列表
              FadeInUp(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '设置',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildSettingsList(context, settings),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // 版本信息
              FadeIn(
                child: Text(
                  'Bipupu v1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(
    BuildContext context,
    dynamic user,
    VoidCallback handleLogout,
    WidgetRef ref,
    VoidCallback openProfileEdit,
  ) {
    final theme = Theme.of(context);
    final userModel = user as UserModel?;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          // 头像 - 使用 AvatarUploader 组件
          AvatarUploader(
            bipupuId: userModel?.bipupuId ?? '',
            radius: 32,
            showEditButton: true,
            onUploadComplete: () {
              // 刷新用户数据
              ref.invalidate(profileNotifierProvider);
            },
          ),
          const SizedBox(width: AppSpacing.md),

          // 用户信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userModel?.nickname ?? userModel?.username ?? '用户',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'ID: ${userModel?.bipupuId ?? "未登录"}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),

          // 编辑和登出按钮
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 20,
                ),
                onPressed: openProfileEdit,
                tooltip: '编辑资料',
              ),
              const SizedBox(height: AppSpacing.xs),
              ShadButton.outline(
                onPressed: handleLogout,
                child: const Text('登出'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildGuestCard(BuildContext context, VoidCallback handleLogin) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          // 未登录用户头像
          UserAvatar(bipupuId: 'guest', radius: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '未登录',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('登录以享受完整功能', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          ShadButton(onPressed: handleLogin, child: const Text('登录')),
        ],
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, List<SettingItem> settings) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        children: settings.asMap().entries.map((entry) {
          final index = entry.key;
          final setting = entry.value;
          return Column(
            children: [
              if (index > 0)
                Divider(
                  height: 1,
                  indent: 56,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ListTile(
                leading: Icon(
                  setting.icon,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                title: Text(setting.title),
                trailing: Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onTap: () {
                  // TODO: 跳转到对应设置页面
                },
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
