import 'package:flutter/material.dart';

/// 个人中心 (D) - 头像、ID、菜单卡片式列表
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  static const String userId = '12345678';

  static final List<_ProfileMenu> _menus = [
    const _ProfileMenu(icon: Icons.person_outline, title: '个人资料'),
    const _ProfileMenu(icon: Icons.devices_other, title: 'PuPu机'),
    const _ProfileMenu(icon: Icons.security, title: '账号与安全'),
    const _ProfileMenu(icon: Icons.settings, title: '设置'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header 区
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: Colors.blue[100],
                  child: const Icon(Icons.person, size: 48, color: Colors.blue),
                ),
                const SizedBox(width: 20),
                const Expanded(
                  child: Text(
                    'BiPuPu ID: $userId',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 菜单卡片
          Expanded(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.separated(
                itemCount: _menus.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final menu = _menus[index];
                  return ListTile(
                    leading: Icon(menu.icon, color: Colors.blue[700]),
                    title: Text(menu.title),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenu {
  final IconData icon;
  final String title;

  const _ProfileMenu({required this.icon, required this.title});
}
