import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_user/api/api.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/theme_service.dart';
import '../../common/widgets/setting_tile.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final username = user?.nickname ?? user?.username ?? "未登录";
    final email = user?.email ?? "未登录";

    final bipupuId = user?.bipupuId ?? '';

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 140,
          backgroundColor: Theme.of(context).primaryColor,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 36),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColorDark,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: InkWell(
                onTap: () => context.push('/profile/edit'),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      backgroundImage: user?.avatarUrl != null
                          ? CachedNetworkImageProvider(
                              user!.avatarUrl!.startsWith('http')
                                  ? user.avatarUrl!
                                  : '${api.baseUrl.replaceFirst(RegExp(r"/api/?$"), '')}${user.avatarUrl}',
                            )
                          : null,
                      child: user?.avatarUrl == null
                          ? Icon(
                              Icons.person,
                              size: 36,
                              color: Theme.of(context).primaryColor,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  if (bipupuId.isNotEmpty) {
                                    await Clipboard.setData(
                                      ClipboardData(text: bipupuId),
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('已复制 Bipupu ID'),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Text(
                                  bipupuId.isNotEmpty ? 'ID: $bipupuId' : '',
                                  style: const TextStyle(color: Colors.white70),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.copy,
                                size: 16,
                                color: Colors.white70,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ),
        ),

        SliverList(
          delegate: SliverChildListDelegate([
            const SizedBox(height: 12),

            SettingSection(
              title: '管理',
              children: [
                SettingTile(
                  icon: Icons.bluetooth_connected,
                  title: 'Pupu机',
                  subtitle: '查看已绑定的设备',
                  onTap: () => context.push('/bluetooth/scan'),
                ),
                SettingTile(
                  icon: Icons.security,
                  title: '账号与安全',
                  subtitle: '重置密码等安全选项',
                  onTap: () => context.push('/profile/security'),
                ),
                SettingTile(
                  icon: Icons.settings,
                  title: '设置',
                  subtitle: '语言、清除缓存、退出登录',
                  onTap: () => context.push('/profile/settings'),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Bipupu v1.0.1',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ],
    );
  }
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
              // 清除所有Hive boxes
              await Hive.deleteFromDisk();
              // 重新初始化Hive
              await Hive.initFlutter();
              // 显示成功消息
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

void _showThemeSelector(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              '选择外观',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListenableBuilder(
              listenable: ThemeService(),
              builder: (context, _) {
                final currentMode = ThemeService().themeMode;
                return Column(
                  children: [
                    _buildThemeOption(
                      context,
                      title: '跟随系统',
                      mode: ThemeMode.system,
                      groupValue: currentMode,
                    ),
                    _buildThemeOption(
                      context,
                      title: '浅色模式',
                      mode: ThemeMode.light,
                      groupValue: currentMode,
                    ),
                    _buildThemeOption(
                      context,
                      title: '深色模式',
                      mode: ThemeMode.dark,
                      groupValue: currentMode,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}

Widget _buildThemeOption(
  BuildContext context, {
  required String title,
  required ThemeMode mode,
  required ThemeMode groupValue,
}) {
  final isSelected = mode == groupValue;
  return ListTile(
    title: Text(title),
    trailing: isSelected
        ? Icon(Icons.check, color: Theme.of(context).primaryColor)
        : null,
    onTap: () {
      ThemeService().updateThemeMode(mode);
      Navigator.pop(context);
    },
    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
  );
}
