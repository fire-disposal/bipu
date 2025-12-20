import 'package:flutter/material.dart';

/// 消息中心 (C) - ListView.separated 消息分类列表
class MessageTab extends StatelessWidget {
  const MessageTab({super.key});

  static final List<_MessageCategory> _categories = [
    const _MessageCategory(
      icon: Icons.mark_email_unread_outlined,
      title: '收到的消息',
      online: true,
    ),
    const _MessageCategory(icon: Icons.send_outlined, title: '发出的消息', online: false),
    const _MessageCategory(
      icon: Icons.subscriptions_outlined,
      title: '订阅消息',
      online: false,
    ),
    const _MessageCategory(
      icon: Icons.settings_outlined,
      title: '消息管理',
      online: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '消息中心',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[50],
                  child: Icon(cat.icon, color: Colors.blue[700]),
                ),
                if (cat.online)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(cat.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          );
        },
      ),
    );
  }
}

class _MessageCategory {
  final IconData icon;
  final String title;
  final bool online;

  const _MessageCategory({
    required this.icon,
    required this.title,
    required this.online,
  });
}
