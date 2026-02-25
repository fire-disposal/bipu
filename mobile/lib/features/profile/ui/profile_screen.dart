import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:animate_do/animate_do.dart';

import '../../../core/theme/design_system.dart';
import '../../../shared/models/user_model.dart';
import '../../auth/logic/auth_notifier.dart';
import '../../auth/ui/login_page.dart';
import 'profile_edit_screen.dart';
import 'password_edit_screen.dart';
import '../../../shared/widgets/user_avatar.dart';

/// 个人中心主页
class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateNotifierProvider);
    final isAuthenticated = authState.isAuthenticated;
    final user = authState.user;
    final settings = [
      _SettingItem(id: 'profile', title: '个人资料', icon: Icons.person_outline),
      _SettingItem(id: 'security', title: '账号安全', icon: Icons.security),
      _SettingItem(
        id: 'notifications',
        title: '通知设置',
        icon: Icons.notifications_outlined,
      ),
      _SettingItem(id: 'privacy', title: '隐私设置', icon: Icons.lock_outline),
      _SettingItem(
        id: 'appearance',
        title: '外观设置',
        icon: Icons.palette_outlined,
      ),
      _SettingItem(id: 'about', title: '关于', icon: Icons.info_outline),
    ];

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
        await ref.read(authStateNotifierProvider.notifier).logout();
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('我的'), centerTitle: true, elevation: 0),
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
                  child: isAuthenticated
                      ? _buildUserInfoCard(context, user, handleLogout)
                      : _buildLoginPrompt(context, handleLogin),
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
    UserModel? user,
    VoidCallback handleLogout,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          // 头像 - 只显示，不提供编辑功能
          UserAvatar(
            bipupuId: user?.bipupuId ?? '',
            radius: 32,
            avatarUrl: user?.avatarUrl,
          ),
          const SizedBox(width: AppSpacing.md),

          // 用户信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.nickname ?? user?.username ?? '用户',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'ID: ${user?.bipupuId ?? "未登录"}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),

          // 只保留登出按钮
          ShadButton.outline(onPressed: handleLogout, child: const Text('登出')),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context, VoidCallback handleLogin) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '请先登录',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '登录后即可使用完整功能',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ShadButton(
              onPressed: handleLogin,
              child: const Text('立即登录'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, List<_SettingItem> settings) {
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
                  if (setting.id == 'profile') {
                    // 跳转到个人资料编辑页面
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileEditScreen(),
                      ),
                    );
                  } else if (setting.id == 'security') {
                    // 跳转到密码管理页面
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PasswordEditScreen(),
                      ),
                    );
                  }
                  // 其他设置项暂时保持TODO
                },
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

/// 个人设置项（本地定义）
class _SettingItem {
  final String id;
  final String title;
  final IconData icon;

  _SettingItem({required this.id, required this.title, required this.icon});
}
