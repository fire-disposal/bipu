import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/components/ui_components.dart';

/// 蓝牙扫描页面
class BluetoothScanPage extends StatelessWidget {
  const BluetoothScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return UIPageContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题区域
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bluetooth,
                        color: theme.colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '蓝牙扫描',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.foreground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '扫描并连接附近的BIPUPU设备',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 状态卡片
            UICard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '蓝牙状态',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.foreground,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '蓝牙已开启',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.foreground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '正在搜索可用设备...',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 扫描按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: UIButton(
                onPressed: () {
                  Get.snackbar('扫描', '开始扫描蓝牙设备...');
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search, size: 20),
                    SizedBox(width: 8),
                    Text('开始扫描'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 设备列表标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '可用设备',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.foreground,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 设备列表
            _buildDeviceList(context),

            const SizedBox(height: 32),

            // 连接说明
            UICard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '使用说明',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.foreground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionItem(
                    context,
                    icon: Icons.power_settings_new,
                    text: '确保BIPUPU设备已开机',
                  ),
                  _buildInstructionItem(
                    context,
                    icon: Icons.bluetooth,
                    text: '设备蓝牙处于可被发现状态',
                  ),
                  _buildInstructionItem(
                    context,
                    icon: Icons.near_me,
                    text: '将手机靠近设备（10米内）',
                  ),
                  _buildInstructionItem(
                    context,
                    icon: Icons.link,
                    text: '点击设备名称进行连接',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建设备列表
  Widget _buildDeviceList(BuildContext context) {
    final theme = ShadTheme.of(context);

    // 模拟设备数据
    final devices = [
      {'name': 'BIPUPU-001', 'signal': '强', 'type': '主设备'},
      {'name': 'BIPUPU-002', 'signal': '中', 'type': '从设备'},
      {'name': 'BIPUPU-003', 'signal': '弱', 'type': '主设备'},
    ];

    if (devices.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.muted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.devices_other,
              color: theme.colorScheme.mutedForeground,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              '未发现设备',
              style: TextStyle(
                color: theme.colorScheme.mutedForeground,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '请确保设备已开启并处于可被发现状态',
              style: TextStyle(
                color: theme.colorScheme.mutedForeground,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: devices.map((device) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: UICard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.bluetooth_connected,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device['name']!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.foreground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              device['type']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '信号: ${device['signal']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                UISecondaryButton(
                  onPressed: () {
                    Get.snackbar('连接', '正在连接 ${device['name']}...');
                  },
                  child: const Text('连接'),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 构建说明项
  Widget _buildInstructionItem(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final theme = ShadTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
