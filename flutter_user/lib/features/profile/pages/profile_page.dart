import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_user/api/api.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/theme_service.dart';
import '../../common/widgets/setting_tile.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final username = user?.nickname ?? user?.username ?? "Guest";
    final email = user?.email ?? "Offline Mode";

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      backgroundImage: user?.avatarUrl != null
                          ? CachedNetworkImageProvider(
                              user!.avatarUrl!.startsWith('http')
                                  ? user.avatarUrl!
                                  : '${bipupuHttp.options.baseUrl.replaceFirst(RegExp(r"/api$"), '')}${user.avatarUrl}',
                            )
                          : null,
                      child: user?.avatarUrl == null
                          ? Icon(
                              Icons.person,
                              size: 40,
                              color: Theme.of(context).primaryColor,
                            )
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      username,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(email, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 12),

              SettingSection(
                title: '设备管理',
                children: [
                  SettingTile(
                    icon: Icons.bluetooth_connected,
                    title: '设备绑定',
                    subtitle: '管理已连接的传呼机',
                    onTap: () => context.push('/bluetooth/scan'),
                  ),
                ],
              ),

              SettingSection(
                title: '账户与安全',
                children: [
                  SettingTile(
                    icon: Icons.person_outline,
                    title: '个人资料',
                    onTap: () => context.push('/profile/personal_info'),
                  ),
                  SettingTile(
                    icon: Icons.edit,
                    title: '编辑资料',
                    onTap: () => context.push('/profile/edit'),
                  ),
                  SettingTile(
                    icon: Icons.security,
                    title: '账号安全',
                    subtitle: '密码、二步验证',
                    onTap: () => context.push('/profile/security'),
                  ),
                  SettingTile(
                    icon: Icons.lock_outline,
                    title: '隐私设置',
                    onTap: () => context.push('/profile/privacy'),
                  ),
                ],
              ),

              SettingSection(
                title: '应用设置',
                children: [
                  SettingTile(
                    icon: Icons.palette_outlined,
                    title: '外观',
                    subtitle: '浅色、深色、跟随系统',
                    onTap: () => _showThemeSelector(context),
                  ),
                  SettingTile(
                    icon: Icons.notifications_outlined,
                    title: '通知',
                    onTap: () => context.push('/profile/notifications'),
                  ),
                  SettingTile(
                    icon: Icons.language,
                    title: '语言',
                    onTap: () => context.push('/profile/language'),
                  ),
                  SettingTile(
                    icon: Icons.info_outline,
                    title: '关于 Bipupu',
                    onTap: () => context.push('/profile/about'),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Card(
                  child: SettingTile(
                    icon: Icons.logout,
                    title: '退出登录',
                    textColor: Colors.red,
                    iconColor: Colors.red,
                    onTap: () => _showLogoutDialog(context),
                  ),
                ),
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

  // 旧的 Section/Tile 已替换为可复用组�?
}
