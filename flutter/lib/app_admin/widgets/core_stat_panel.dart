/// 核心统计面板组件
library;

import 'package:flutter/material.dart';
import 'core_card.dart';

/// 统计面板组件
class CoreStatPanel extends StatelessWidget {
  final List<StatCard> stats;
  final String? title;
  final int crossAxisCount;
  final double childAspectRatio;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  const CoreStatPanel({
    super.key,
    required this.stats,
    this.title,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.5,
    this.mainAxisSpacing = 16,
    this.crossAxisSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
        ],
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          children: stats,
        ),
      ],
    );
  }
}

/// 仪表板统计面板
class DashboardStatPanel extends StatelessWidget {
  final int totalDevices;
  final int onlineDevices;
  final int totalUsers;
  final int activeUsers;
  final double? deviceOnlineRate;
  final double? userActiveRate;

  const DashboardStatPanel({
    super.key,
    required this.totalDevices,
    required this.onlineDevices,
    required this.totalUsers,
    required this.activeUsers,
    this.deviceOnlineRate,
    this.userActiveRate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CoreStatPanel(
      title: '概览统计',
      stats: [
        StatCard(
          title: '设备总数',
          value: totalDevices.toString(),
          icon: Icons.devices,
          iconColor: theme.colorScheme.primary,
        ),
        StatCard(
          title: '在线设备',
          value: onlineDevices.toString(),
          subtitle: deviceOnlineRate != null
              ? '在线率 ${(deviceOnlineRate! * 100).toStringAsFixed(1)}%'
              : null,
          icon: Icons.wifi,
          iconColor: Colors.green,
        ),
        StatCard(
          title: '用户总数',
          value: totalUsers.toString(),
          icon: Icons.people,
          iconColor: theme.colorScheme.secondary,
        ),
        StatCard(
          title: '活跃用户',
          value: activeUsers.toString(),
          subtitle: userActiveRate != null
              ? '活跃率 ${(userActiveRate! * 100).toStringAsFixed(1)}%'
              : null,
          icon: Icons.person,
          iconColor: Colors.orange,
        ),
      ],
    );
  }
}

/// 设备状态面板
class DeviceStatusPanel extends StatelessWidget {
  final int batteryLevel;
  final bool isCharging;
  final double temperature;
  final bool isConnected;
  final VoidCallback? onRefresh;

  const DeviceStatusPanel({
    super.key,
    required this.batteryLevel,
    required this.isCharging,
    required this.temperature,
    required this.isConnected,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: '设备状态',
      icon: Icons.device_hub,
      content: Column(
        children: [
          _buildStatusRow(
            '电池电量',
            '$batteryLevel%',
            isCharging ? Icons.battery_charging_full : Icons.battery_std,
            _getBatteryColor(batteryLevel),
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            '设备温度',
            '${temperature.toStringAsFixed(1)}°C',
            Icons.thermostat,
            _getTemperatureColor(temperature),
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            '连接状态',
            isConnected ? '已连接' : '未连接',
            isConnected ? Icons.link : Icons.link_off,
            isConnected ? Colors.green : Colors.red,
          ),
        ],
      ),
      actions: [
        if (onRefresh != null)
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('刷新'),
          ),
      ],
    );
  }

  Widget _buildStatusRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getBatteryColor(int level) {
    if (level >= 50) return Colors.green;
    if (level >= 20) return Colors.orange;
    return Colors.red;
  }

  Color _getTemperatureColor(double temp) {
    if (temp <= 35) return Colors.blue;
    if (temp <= 40) return Colors.green;
    if (temp <= 45) return Colors.orange;
    return Colors.red;
  }
}
