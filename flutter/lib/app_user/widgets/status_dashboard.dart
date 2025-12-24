/// 状态仪表板组件
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state/device_control_state.dart';
import '../../core/core.dart';
import 'user_widgets.dart';

/// 状态仪表板
class StatusDashboard extends StatelessWidget {
  const StatusDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceControlCubit, DeviceControlState>(
      builder: (context, state) {
        if (state is DeviceConnected) {
          return _ConnectedDeviceStatus(deviceInfo: state.deviceInfo);
        } else if (state is DeviceConnecting) {
          return _ConnectingStatus();
        } else {
          return _DisconnectedStatus();
        }
      },
    );
  }
}

/// 已连接设备状态
class _ConnectedDeviceStatus extends StatelessWidget {
  final DeviceStatus? deviceInfo;

  const _ConnectedDeviceStatus({this.deviceInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: CoreCard.elevated(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bluetooth_connected,
                    color: Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '设备已连接',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => _showDeviceDetails(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DeviceStatusRow(deviceInfo: deviceInfo),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeviceDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设备详情'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('电池电量: ${deviceInfo?.batteryLevel ?? '--'}%'),
            Text('设备温度: ${deviceInfo?.temperature ?? '--'}°C'),
            Text('连接状态: 已连接'),
            Text('最后同步: ${deviceInfo?.lastSyncTime ?? '--'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

/// 设备状态行
class _DeviceStatusRow extends StatelessWidget {
  final DeviceStatus? deviceInfo;

  const _DeviceStatusRow({this.deviceInfo});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatusItem(
          icon: Icons.battery_std,
          label: '电量',
          value: '${deviceInfo?.batteryLevel ?? '--'}%',
          color: _getBatteryColor(deviceInfo?.batteryLevel),
        ),
        _StatusItem(
          icon: Icons.thermostat,
          label: '温度',
          value: '${deviceInfo?.temperature ?? '--'}°C',
          color: _getTemperatureColor(deviceInfo?.temperature),
        ),
        _StatusItem(
          icon: Icons.signal_wifi_4_bar,
          label: '信号',
          value: '良好',
          color: Colors.green,
        ),
      ],
    );
  }

  Color _getBatteryColor(int? level) {
    if (level == null) return Colors.grey;
    if (level >= 50) return Colors.green;
    if (level >= 20) return Colors.orange;
    return Colors.red;
  }

  Color _getTemperatureColor(double? temp) {
    if (temp == null) return Colors.grey;
    if (temp <= 35) return Colors.blue;
    if (temp <= 40) return Colors.green;
    if (temp <= 45) return Colors.orange;
    return Colors.red;
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
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// 连接中状态
class _ConnectingStatus extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: CoreCard.outlined(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text('正在连接设备...', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

/// 未连接状态
class _DisconnectedStatus extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: CoreCard.outlined(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.bluetooth_disabled,
                color: Colors.grey.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '设备未连接',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '请连接您的寻呼机设备',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _scanForDevices(context),
                icon: const Icon(Icons.search, size: 16),
                label: const Text('扫描设备'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scanForDevices(BuildContext context) {
    // 触发设备扫描
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('正在扫描设备...')));
  }
}
