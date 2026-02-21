import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../common/widgets/setting_tile.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final username = user?.nickname ?? user?.username ?? "未登录";

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
                    UserAvatar(
                      avatarUrl: user?.avatarUrl,
                      displayName: user?.nickname ?? user?.username,
                      radius: 32,
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
