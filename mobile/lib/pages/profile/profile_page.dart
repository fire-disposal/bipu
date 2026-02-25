import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/app_controller.dart';

/// 我的页面
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = AuthController.to;
    final appController = AppController.to;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户信息卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Obx(() {
                  final user = authController.currentUser;
                  return Column(
                    children: [
                      // 用户头像
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          user?.username.substring(0, 1).toUpperCase() ?? 'U',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 用户名
                      Text(
                        user?.username ?? '游客',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Bipupu ID
                      Text(
                        user?.bipupuId ?? '未登录',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 编辑资料按钮
                      OutlinedButton(
                        onPressed: () {
                          Get.snackbar('提示', '编辑资料功能开发中');
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('编辑资料'),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),

            const SizedBox(height: 16),

            // 功能菜单
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '账号设置',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      context,
                      icon: Icons.settings,
                      label: '账号设置',
                      subtitle: '修改密码、安全设置',
                      color: Theme.of(context).colorScheme.primary,
                      onTap: () {
                        Get.toNamed('/settings');
                      },
                    ),
                    const Divider(height: 1),
                    _buildMenuItem(
                      context,
                      icon: Icons.notifications,
                      label: '通知设置',
                      subtitle: '管理通知偏好',
                      color: Colors.orange,
                      onTap: () {
                        Get.snackbar('提示', '通知设置功能开发中');
                      },
                    ),
                    const Divider(height: 1),
                    _buildMenuItem(
                      context,
                      icon: Icons.privacy_tip,
                      label: '隐私设置',
                      subtitle: '管理隐私选项',
                      color: Colors.green,
                      onTap: () {
                        Get.snackbar('提示', '隐私设置功能开发中');
                      },
                    ),
                    const Divider(height: 1),
                    _buildMenuItem(
                      context,
                      icon: Icons.palette,
                      label: '主题设置',
                      subtitle: '切换亮色/暗色主题',
                      color: Colors.purple,
                      onTap: () {
                        appController.toggleTheme();
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 其他功能
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '其他功能',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      context,
                      icon: Icons.info,
                      label: '关于应用',
                      subtitle: '版本信息、帮助',
                      color: Colors.blue,
                      onTap: () {
                        _showAboutDialog(context);
                      },
                    ),
                    const Divider(height: 1),
                    _buildMenuItem(
                      context,
                      icon: Icons.help,
                      label: '帮助与反馈',
                      subtitle: '常见问题、提交反馈',
                      color: Colors.teal,
                      onTap: () {
                        Get.snackbar('提示', '帮助与反馈功能开发中');
                      },
                    ),
                    const Divider(height: 1),
                    _buildMenuItem(
                      context,
                      icon: Icons.share,
                      label: '分享应用',
                      subtitle: '分享给朋友',
                      color: Colors.indigo,
                      onTap: () {
                        Get.snackbar('提示', '分享功能开发中');
                      },
                    ),
                    const Divider(height: 1),
                    _buildMenuItem(
                      context,
                      icon: Icons.star,
                      label: '评价应用',
                      subtitle: '给我们评分',
                      color: Colors.amber,
                      onTap: () {
                        Get.snackbar('提示', '评价功能开发中');
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 退出登录按钮
            ElevatedButton(
              onPressed: () {
                _showLogoutConfirmation(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.logout, size: 16),
                  SizedBox(width: 8),
                  Text('退出登录'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 版本信息
            Center(
              child: Column(
                children: [
                  Text(
                    'Bipupu - 宇宙传讯',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '版本 1.0.0',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // 构建菜单项
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // 图标
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),

            // 文本内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // 箭头
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // 显示关于对话框
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            '关于 Bipupu',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '宇宙传讯系统',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text('版本: 1.0.0', style: Theme.of(context).textTheme.bodySmall),
              Text(
                '构建日期: 2024-01-01',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text(
                'Bipupu是一个创新的宇宙传讯平台，'
                '致力于为用户提供安全、高效的通信体验。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  // 显示退出登录确认
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            '退出登录',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          content: Text(
            '确定要退出登录吗？退出后需要重新登录才能使用应用。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                AuthController.to.logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('退出登录'),
            ),
          ],
        );
      },
    );
  }
}
