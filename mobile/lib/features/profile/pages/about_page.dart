import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于 Bipupu')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // App Logo and Name
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.bluetooth,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bipupu',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version ${_packageInfo?.version ?? '1.0.0'}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Description
          const Text(
            'Bipupu 是一款专为智能硬件交互设计的移动应用，提供便捷的蓝牙连接、语音交互和用户管理功能。',
            style: TextStyle(fontSize: 16, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Features
          const Text(
            '主要功能',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            icon: Icons.bluetooth,
            title: '蓝牙连接',
            description: '快速连接和控制蓝牙设备',
          ),
          _buildFeatureItem(
            icon: Icons.mic,
            title: '语音交互',
            description: '智能语音识别和语音合成',
          ),
          _buildFeatureItem(
            icon: Icons.message,
            title: '即时通讯',
            description: '与好友实时交流',
          ),
          _buildFeatureItem(
            icon: Icons.people,
            title: '社交功能',
            description: '添加好友，管理联系人',
          ),

          const SizedBox(height: 32),

          // Contact Info
          const Text(
            '联系我们',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('邮箱'),
            subtitle: const Text('support@bipupu.com'),
            onTap: () {
              // TODO: Implement email action
            },
          ),
          ListTile(
            leading: const Icon(Icons.web),
            title: const Text('官方网站'),
            subtitle: const Text('www.bipupu.com'),
            onTap: () {
              // TODO: Implement web action
            },
          ),

          const SizedBox(height: 32),

          // Copyright
          Center(
            child: Text(
              '© 2024 Bipupu Team. All rights reserved.',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
