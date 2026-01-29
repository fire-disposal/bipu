import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ble_pipeline.dart';

/// 简化的蓝牙UI组件适配器
/// 为新的BlePipeline提供兼容的UI组件
class SimpleBleState extends ChangeNotifier {
  final BlePipeline _pipeline = BlePipeline();

  SimpleBleState() {
    _pipeline.addListener(notifyListeners);
  }

  // 兼容的属性
  bool get isScanning => _pipeline.isScanning;
  bool get isConnecting => _pipeline.isConnecting;
  bool get isConnected => _pipeline.isConnected;
  BluetoothDevice? get connectedDevice => _pipeline.connectedDevice;
  int? get batteryLevel => _pipeline.batteryLevel;
  List<ScanResult> get scanResults => _pipeline.scanResults;

  // 兼容的方法
  Future<void> startScan() => _pipeline.startScan();
  Future<void> stopScan() => _pipeline.stopScan();
  Future<void> connect(BluetoothDevice device) => _pipeline.connect(device);
  Future<void> disconnect() => _pipeline.disconnect();

  @override
  void dispose() {
    _pipeline.removeListener(notifyListeners);
    super.dispose();
  }
}

/// 简化的设备信息模型
class SimpleBleDeviceInfo {
  final BluetoothDevice device;
  final bool isLastConnected;

  SimpleBleDeviceInfo({required this.device, this.isLastConnected = false});

  String get name =>
      device.platformName.isEmpty ? 'Unknown Device' : device.platformName;
  String get id => device.remoteId.toString();
}

/// 简化的设备列表项
class SimpleBleDeviceListItem extends StatelessWidget {
  final SimpleBleDeviceInfo deviceInfo;
  final bool isConnecting;
  final VoidCallback? onConnect;

  const SimpleBleDeviceListItem({
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

/// 简化的连接状态指示器
class SimpleBleStatusIndicator extends StatelessWidget {
  final SimpleBleState state;

  const SimpleBleStatusIndicator({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, child) {
        if (state.isConnecting) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.orange.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(
                  Icons.bluetooth_searching,
                  color: Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Connecting to device...',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (state.isConnected) {
          final deviceName =
              state.connectedDevice?.platformName ?? 'Unknown Device';
          final batteryLevel = state.batteryLevel;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.green.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(
                  Icons.bluetooth_connected,
                  color: Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Connected to $deviceName',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                    ),
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
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
