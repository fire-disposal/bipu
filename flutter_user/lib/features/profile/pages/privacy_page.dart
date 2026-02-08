import 'package:flutter/material.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool _profileVisible = true;
  bool _onlineStatusVisible = true;
  bool _lastSeenVisible = false;
  bool _readReceiptsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('隐私设置')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '隐私设置',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Profile Visibility
          SwitchListTile(
            title: const Text('个人资料可见性'),
            subtitle: const Text('允许其他用户查看您的个人资料'),
            value: _profileVisible,
            onChanged: (value) {
              setState(() {
                _profileVisible = value;
              });
            },
          ),

          const Divider(),

          // Online Status
          SwitchListTile(
            title: const Text('在线状态'),
            subtitle: const Text('显示您的在线状态'),
            value: _onlineStatusVisible,
            onChanged: (value) {
              setState(() {
                _onlineStatusVisible = value;
              });
            },
          ),

          // Last Seen
          SwitchListTile(
            title: const Text('最后在线时间'),
            subtitle: const Text('显示您最后在线的时间'),
            value: _lastSeenVisible,
            onChanged: (value) {
              setState(() {
                _lastSeenVisible = value;
              });
            },
          ),

          // Read Receipts
          SwitchListTile(
            title: const Text('已读回执'),
            subtitle: const Text('显示消息已读状态'),
            value: _readReceiptsEnabled,
            onChanged: (value) {
              setState(() {
                _readReceiptsEnabled = value;
              });
            },
          ),

          const Divider(),

          // Blocked Users
          ListTile(
            title: const Text('黑名单'),
            subtitle: const Text('管理被屏蔽的用户'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to blocked users page
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('功能开发中')));
            },
          ),

          // Data Privacy
          ListTile(
            title: const Text('数据隐私'),
            subtitle: const Text('管理您的隐私数据'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to data privacy page
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('功能开发中')));
            },
          ),

          const SizedBox(height: 32),

          // Privacy Policy
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '隐私政策',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '我们重视您的隐私。所有个人数据都经过加密处理，仅用于提供服务。我们不会向第三方出售或分享您的个人信息。',
                  style: TextStyle(color: Colors.grey[600], height: 1.5),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Open full privacy policy
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('完整隐私政策')));
                  },
                  child: const Text('查看完整隐私政策'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
