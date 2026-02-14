import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../common/widgets/setting_tile.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          const SizedBox(height: 12),
          SettingSection(
            title: '设置',
            children: [
              SettingTile(
                icon: Icons.language,
                title: '语言',
                subtitle: '切换应用语言',
                onTap: () => context.push('/profile/language'),
              ),
              SettingTile(
                icon: Icons.cleaning_services_outlined,
                title: '清除本地缓存',
                subtitle: '清除所有本地存储数据',
                onTap: () => _showClearCacheDialog(context),
              ),
              SettingTile(
                icon: Icons.logout,
                title: '退出登录',
                onTap: () => _showLogoutDialog(context),
                textColor: Colors.red,
                iconColor: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService().logout();
              if (context.mounted) context.go('/login');
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除本地缓存'),
        content: const Text('确定要清除所有本地缓存数据吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Hive.deleteFromDisk();
                await Hive.initFlutter();
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('本地缓存已清除')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('清除缓存失败: $e')));
                }
              }
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
