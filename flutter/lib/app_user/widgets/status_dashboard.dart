import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state/device_control_state.dart';

/// 现代状态栏Dashboard组件
/// 显示设备连接状态、电池电量、信号强度等信息
class StatusDashboard extends StatelessWidget {
  const StatusDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceControlCubit, DeviceControlState>(
      builder: (context, state) {
        final isConnected = state is DeviceConnected;
        final deviceName = isConnected ? state.deviceName : '未连接';
        final deviceInfo = isConnected ? state.deviceInfo : null;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isConnected
                  ? [Colors.blue.shade400, Colors.blue.shade600]
                  : [Colors.grey.shade400, Colors.grey.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (isConnected ? Colors.blue : Colors.grey).withOpacity(
                  0.3,
                ),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // 顶部状态行
              Row(
                children: [
                  // 设备图标
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isConnected
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth_disabled,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 设备信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deviceName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isConnected ? '已连接' : '设备未连接',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 连接状态指示器
                  _ConnectionStatusIndicator(isConnected: isConnected),
                ],
              ),

              const SizedBox(height: 20),

              // 设备状态信息
              if (isConnected && deviceInfo != null) ...[
                _DeviceStatusRow(deviceInfo: deviceInfo),
                const SizedBox(height: 16),
              ],

              // 快速操作按钮
              LayoutBuilder(
                builder: (context, constraints) {
                  final buttonWidth = (constraints.maxWidth - 24) / 3;
                  return Row(
                    children: [
                      SizedBox(
                        width: buttonWidth,
                        child: _QuickActionButton(
                          icon: isConnected ? Icons.link_off : Icons.link,
                          label: isConnected ? '断开' : '连接',
                          onTap: () =>
                              _handleConnectionTap(context, isConnected),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: buttonWidth,
                        child: _QuickActionButton(
                          icon: Icons.battery_std,
                          label: '电量',
                          onTap: () => _checkBattery(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: buttonWidth,
                        child: _QuickActionButton(
                          icon: Icons.notifications,
                          label: '测试',
                          onTap: () => _sendTestNotification(context),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleConnectionTap(BuildContext context, bool isConnected) {
    final cubit = context.read<DeviceControlCubit>();
    if (isConnected) {
      cubit.disconnectDevice();
    } else {
      // 这里可以导航到设备连接页面
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请前往设备页面连接手环')));
    }
  }

  void _checkBattery(BuildContext context) async {
    final cubit = context.read<DeviceControlCubit>();
    final batteryLevel = await cubit.getBatteryLevel();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            batteryLevel != null ? '设备电量: $batteryLevel%' : '无法获取设备电量',
          ),
        ),
      );
    }
  }

  void _sendTestNotification(BuildContext context) {
    final cubit = context.read<DeviceControlCubit>();
    if (cubit.isConnected) {
      cubit.sendSimpleNotification(text: '测试通知');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('测试通知已发送')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先连接设备')));
    }
  }
}

/// 连接状态指示器
class _ConnectionStatusIndicator extends StatelessWidget {
  final bool isConnected;

  const _ConnectionStatusIndicator({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isConnected ? Colors.greenAccent : Colors.orangeAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isConnected ? '在线' : '离线',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// 设备状态行
class _DeviceStatusRow extends StatelessWidget {
  final Map<String, dynamic> deviceInfo;

  const _DeviceStatusRow({required this.deviceInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatusItem(
            icon: Icons.battery_charging_full,
            label: '电量',
            value: '${deviceInfo['batteryLevel'] ?? '--'}%',
            color: Colors.greenAccent,
          ),
          _StatusItem(
            icon: Icons.network_wifi,
            label: '信号',
            value: '${deviceInfo['rssi'] ?? '--'} dBm',
            color: Colors.blueAccent,
          ),
          _StatusItem(
            icon: Icons.update,
            label: '版本',
            value: deviceInfo['firmwareVersion'] ?? '--',
            color: Colors.purpleAccent,
          ),
        ],
      ),
    );
  }
}

/// 状态项
class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatusItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// 快速操作按钮
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
