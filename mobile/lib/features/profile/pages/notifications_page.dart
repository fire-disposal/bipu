import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _messageNotifications = true;
  bool _friendRequestNotifications = true;
  bool _systemNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('通知设置')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '推送通知',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Message Notifications
          SwitchListTile(
            title: const Text('消息通知'),
            subtitle: const Text('接收新消息推送'),
            value: _messageNotifications,
            onChanged: (value) {
              setState(() {
                _messageNotifications = value;
              });
            },
          ),

          // Friend Request Notifications
          SwitchListTile(
            title: const Text('好友请求通知'),
            subtitle: const Text('接收好友请求推送'),
            value: _friendRequestNotifications,
            onChanged: (value) {
              setState(() {
                _friendRequestNotifications = value;
              });
            },
          ),

          // System Notifications
          SwitchListTile(
            title: const Text('系统通知'),
            subtitle: const Text('接收系统更新和公告'),
            value: _systemNotifications,
            onChanged: (value) {
              setState(() {
                _systemNotifications = value;
              });
            },
          ),

          const Divider(),

          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '通知方式',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Sound
          SwitchListTile(
            title: const Text('声音'),
            subtitle: const Text('播放通知声音'),
            value: _soundEnabled,
            onChanged: (value) {
              setState(() {
                _soundEnabled = value;
              });
            },
          ),

          // Vibration
          SwitchListTile(
            title: const Text('震动'),
            subtitle: const Text('设备震动提醒'),
            value: _vibrationEnabled,
            onChanged: (value) {
              setState(() {
                _vibrationEnabled = value;
              });
            },
          ),

          const Divider(),

          // Notification Schedule
          ListTile(
            title: const Text('通知时间'),
            subtitle: const Text('设置接收通知的时间段'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Open notification schedule settings
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('功能开发中')));
            },
          ),

          // Do Not Disturb
          ListTile(
            title: const Text('免打扰模式'),
            subtitle: const Text('设置免打扰时间'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Open do not disturb settings
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('功能开发中')));
            },
          ),

          const SizedBox(height: 32),

          // Test Notification
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('测试通知已发送')));
              },
              child: const Text('发送测试通知'),
            ),
          ),
        ],
      ),
    );
  }
}
