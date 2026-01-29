import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../constants/ble_constants.dart';
import 'ble_state_manager.dart';

/// BLE状态指示器
class BleStatusIndicator extends StatelessWidget {
  final BleStateManager stateManager;

  const BleStatusIndicator({super.key, required this.stateManager});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: stateManager,
      builder: (context, child) {
        if (stateManager.isConnecting) {
          return _buildConnectingStatus(context);
        } else if (stateManager.isConnected) {
          return _buildConnectedStatus(context);
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildConnectingStatus(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.bluetooth_searching, color: Colors.orange, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Connecting to device...',
              style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedStatus(BuildContext context) {
    final deviceName =
        stateManager.connectedDevice?.platformName ?? 'Unknown Device';
    final batteryLevel = stateManager.batteryLevel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.green.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.bluetooth_connected, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Connected to $deviceName',
              style: TextStyle(color: Colors.green.shade700, fontSize: 12),
            ),
          ),
          if (batteryLevel != null) ...[
            Icon(
              batteryLevel > 20 ? Icons.battery_std : Icons.battery_alert,
              color: batteryLevel > 20 ? Colors.green : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '$batteryLevel%',
              style: TextStyle(color: Colors.green.shade700, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

/// BLE设备列表项
class BleDeviceListItem extends StatelessWidget {
  final BleDeviceInfo deviceInfo;
  final bool isConnecting;
  final VoidCallback? onConnect;

  const BleDeviceListItem({
    super.key,
    required this.deviceInfo,
    this.isConnecting = false,
    this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        deviceInfo.isLastConnected
            ? Icons.bluetooth_connected
            : Icons.bluetooth,
        color: deviceInfo.isLastConnected ? Colors.green : null,
      ),
      title: Text(
        deviceInfo.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(deviceInfo.id),
          if (deviceInfo.isLastConnected)
            Text(
              'Last connected',
              style: TextStyle(color: Colors.green.shade700, fontSize: 12),
            ),
        ],
      ),
      trailing: ElevatedButton(
        onPressed: isConnecting ? null : onConnect,
        child: isConnecting && deviceInfo.isLastConnected
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Connect'),
      ),
    );
  }
}

/// BLE连接状态卡片
class BleConnectionCard extends StatelessWidget {
  final BleStateManager stateManager;
  final VoidCallback? onDisconnect;

  const BleConnectionCard({
    super.key,
    required this.stateManager,
    this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: stateManager,
      builder: (context, child) {
        if (!stateManager.isConnected) {
          return Container(
            padding: const EdgeInsets.all(12),
            color: Colors.red.withValues(alpha: 0.1),
            child: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  "Device disconnected. Please keep safe.",
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

/// BLE时间同步状态指示器
class BleTimeSyncIndicator extends StatelessWidget {
  final bool isInProgress;
  final bool isCompleted;

  const BleTimeSyncIndicator({
    super.key,
    required this.isInProgress,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    if (isInProgress) {
      return Container(
        padding: const EdgeInsets.all(12),
        color: Colors.blue.withValues(alpha: 0.1),
        child: Row(
          children: [
            const Icon(Icons.schedule, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              "Synchronizing time...",
              style: TextStyle(color: Colors.blue.shade700),
            ),
          ],
        ),
      );
    } else if (isCompleted) {
      return Container(
        padding: const EdgeInsets.all(12),
        color: Colors.green.withValues(alpha: 0.1),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              "Time synchronized successfully",
              style: TextStyle(color: Colors.green.shade700),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
