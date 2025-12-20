import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state/device_control_state.dart';

/// 设备信息卡片组件
/// 显示详细的设备信息和状态
class DeviceInfoCard extends StatelessWidget {
  const DeviceInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceControlCubit, DeviceControlState>(
      builder: (context, state) {
        final isConnected = state is DeviceConnected;

        if (!isConnected) {
          return _DisconnectedDeviceCard();
        }

        final deviceState = state;
        return _ConnectedDeviceCard(deviceState: deviceState);
      },
    );
  }
}

/// 未连接设备卡片
class _DisconnectedDeviceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.grey.shade100, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // 设备图标
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.watch_off,
                size: 40,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),

            // 标题
            Text(
              '未连接设备',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),

            // 描述
            Text(
              '请连接您的蓝牙手环设备',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            // 连接按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToDeviceConnection(context),
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text('连接设备'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDeviceConnection(BuildContext context) {
    // 这里可以导航到设备连接页面
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('请前往设备页面连接手环')));
  }
}

/// 已连接设备卡片
class _ConnectedDeviceCard extends StatelessWidget {
  final DeviceConnected deviceState;

  const _ConnectedDeviceCard({required this.deviceState});

  @override
  Widget build(BuildContext context) {
    final deviceInfo = deviceState.deviceInfo ?? {};

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // 顶部设备信息头
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // 设备图标
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.watch,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 设备名称和状态
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deviceState.deviceName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${deviceState.deviceId}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 连接状态
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: Colors.greenAccent),
                        SizedBox(width: 6),
                        Text(
                          '已连接',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 详细信息区域
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 基本信息行
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _InfoItem(
                        icon: Icons.battery_charging_full,
                        label: '电量',
                        value: '${deviceInfo['batteryLevel'] ?? '--'}%',
                        color: Colors.green,
                      ),
                      _InfoItem(
                        icon: Icons.network_wifi,
                        label: '信号强度',
                        value: '${deviceInfo['rssi'] ?? '--'} dBm',
                        color: Colors.blue,
                      ),
                      _InfoItem(
                        icon: Icons.update,
                        label: '固件版本',
                        value: deviceInfo['firmwareVersion'] ?? '--',
                        color: Colors.purple,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 设备功能状态
                  _DeviceFeaturesStatus(deviceInfo: deviceInfo),

                  const SizedBox(height: 20),

                  // 操作按钮
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _disconnectDevice(context),
                          icon: const Icon(Icons.link_off, size: 18),
                          label: const Text('断开连接'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showDeviceSettings(context),
                          icon: const Icon(Icons.settings, size: 18),
                          label: const Text('设备设置'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _disconnectDevice(BuildContext context) {
    context.read<DeviceControlCubit>().disconnectDevice();
  }

  void _showDeviceSettings(BuildContext context) {
    // 这里可以导航到设备设置页面
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('设备设置功能开发中')));
  }
}

/// 信息项组件
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}

/// 设备功能状态组件
class _DeviceFeaturesStatus extends StatelessWidget {
  final Map<String, dynamic> deviceInfo;

  const _DeviceFeaturesStatus({required this.deviceInfo});

  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'icon': Icons.vibration,
        'label': '震动',
        'enabled': deviceInfo['hasVibration'] ?? true,
        'color': Colors.orange,
      },
      {
        'icon': Icons.lightbulb_outline,
        'label': 'LED',
        'enabled': deviceInfo['hasLed'] ?? true,
        'color': Colors.yellow,
      },
      {
        'icon': Icons.bluetooth,
        'label': '蓝牙',
        'enabled': true, // 如果已连接，蓝牙肯定是可用的
        'color': Colors.blue,
      },
      {
        'icon': Icons.battery_alert,
        'label': '低电量',
        'enabled': deviceInfo['lowBattery'] ?? false,
        'color': Colors.red,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '设备功能状态',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: features.map((feature) {
              return _FeatureStatusItem(
                icon: feature['icon'] as IconData,
                label: feature['label'] as String,
                enabled: feature['enabled'] as bool,
                color: feature['color'] as Color,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// 功能状态项
class _FeatureStatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final Color color;

  const _FeatureStatusItem({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: enabled
                ? color.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: enabled ? color : Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: enabled ? Colors.grey.shade700 : Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          enabled ? '正常' : '关闭',
          style: TextStyle(
            fontSize: 10,
            color: enabled ? Colors.green : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
