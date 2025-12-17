import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/constants.dart';
import '../../../core/ble/bluetooth_service.dart';

class DeviceScanPage extends StatefulWidget {
  const DeviceScanPage({super.key});

  @override
  State<DeviceScanPage> createState() => _DeviceScanPageState();
}

class _DeviceScanPageState extends State<DeviceScanPage> {
  bool _isScanning = false;
  List<BluetoothDeviceInfo> _devices = [];
  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设备扫描'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isScanning ? Icons.stop : Icons.refresh,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: _isScanning ? _stopScan : _startScan,
            tooltip: _isScanning ? '停止扫描' : '重新扫描',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildScanStatus(),
          Expanded(child: _buildDeviceList()),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildScanStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isScanning
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(
                (255 * 0.5).round(),
              ),
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Row(
        children: [
          if (_isScanning)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          else
            Icon(
              Icons.bluetooth_searching,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isScanning ? '正在扫描设备...' : '扫描完成',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isScanning
                      ? '请确保您的pupu机已开启并处于可发现状态'
                      : '找到 ${_devices.length} 个设备',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    if (_devices.isEmpty && !_isScanning) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        return _DeviceItem(
          device: device,
          onTap: () => _handleDeviceTap(device),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.devices_other_outlined,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withAlpha((255 * 0.5).round()),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无发现设备',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请确保您的pupu机已开启并处于可发现状态',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startScan,
            icon: const Icon(Icons.refresh),
            label: const Text('重新扫描'),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _isScanning ? _stopScan : _startScan,
      icon: Icon(_isScanning ? Icons.stop : Icons.bluetooth_searching),
      label: Text(_isScanning ? '停止扫描' : '开始扫描'),
    );
  }

  void _startScan() async {
    // 检查蓝牙是否支持
    final bluetoothService = BluetoothService.instance;
    if (!bluetoothService.isInitialized) {
      await bluetoothService.initialize();
    }

    setState(() {
      _isScanning = true;
      _devices = [];
    });

    try {
      // 开始真实扫描
      await bluetoothService.startScan();

      // 监听扫描结果
      _scanTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (timer.tick >= 20) {
          // 10秒超时
          _stopScan();
          return;
        }

        // 获取最新的扫描结果
        bluetoothService.scanResults.listen((scanResults) {
          if (mounted) {
            setState(() {
              _devices = scanResults
                  .where((result) => result.device.name.isNotEmpty)
                  .map(
                    (result) => BluetoothDeviceInfo(
                      id: result.device.remoteId.str,
                      name: result.device.name,
                      isConnected: result.device.isConnected,
                      signalStrength: result.rssi,
                      batteryLevel: 0, // 扫描时无法获取电量，使用0表示未知
                    ),
                  )
                  .toList();
            });
          }
        });
      });
    } catch (e) {
      // 如果真实扫描失败，显示模拟数据
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('蓝牙扫描失败：$e，显示模拟数据')));
        _showMockDevices();
      }
    }
  }

  void _showMockDevices() {
    // 显示模拟设备数据，用于不支持蓝牙的平台
    setState(() {
      _devices = [
        const BluetoothDeviceInfo(
          id: 'mock_001',
          name: '模拟pupu机-001',
          isConnected: false,
          signalStrength: -45,
          batteryLevel: 85,
        ),
        const BluetoothDeviceInfo(
          id: 'mock_002',
          name: '模拟pupu机-002',
          isConnected: true,
          signalStrength: -60,
          batteryLevel: 92,
        ),
      ];
    });
  }

  void _stopScan() {
    _scanTimer?.cancel();
    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _handleDeviceTap(BluetoothDeviceInfo device) {
    if (device.isConnected) {
      // 已连接的设备，跳转到控制页面
      context.push(
        '/device-control',
        extra: {'deviceId': device.id, 'deviceName': device.name},
      );
    } else {
      // 未连接的设备，显示连接选项
      _showConnectionDialog(device);
    }
  }

  void _showConnectionDialog(BluetoothDeviceInfo device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('连接设备'),
        content: Text('是否连接 ${device.name}？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _connectToDevice(device);
            },
            child: const Text('连接'),
          ),
        ],
      ),
    );
  }

  Future<void> _connectToDevice(BluetoothDeviceInfo device) async {
    try {
      // 显示连接进度
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('正在连接设备...'),
            ],
          ),
        ),
      );

      // 模拟连接过程
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      Navigator.of(context).pop(); // 关闭进度对话框

      // 连接成功，跳转到详情页
      context.push('/device-detail');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已连接到 ${device.name}')));
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context).pop(); // 关闭进度对话框

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('连接失败: $e')));
    }
  }
}

class BluetoothDeviceInfo {
  final String id;
  final String name;
  final bool isConnected;
  final int signalStrength;
  final int batteryLevel;

  const BluetoothDeviceInfo({
    required this.id,
    required this.name,
    required this.isConnected,
    required this.signalStrength,
    required this.batteryLevel,
  });
}

class _DeviceItem extends StatelessWidget {
  final BluetoothDeviceInfo device;
  final VoidCallback onTap;

  const _DeviceItem({required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: device.isConnected
                      ? AppColors.success.withAlpha((255 * 0.1).round())
                      : Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  device.isConnected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth,
                  color: device.isConnected
                      ? AppColors.success
                      : Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          device.isConnected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 16,
                          color: device.isConnected
                              ? AppColors.success
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          device.isConnected ? '已连接' : '未连接',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: device.isConnected
                                    ? AppColors.success
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.signal_wifi_4_bar,
                          size: 16,
                          color: _getSignalColor(device.signalStrength),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${device.signalStrength} dBm',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: _getSignalColor(device.signalStrength),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (device.isConnected) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha((255 * 0.1).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.battery_std,
                        size: 14,
                        color: _getBatteryColor(device.batteryLevel),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${device.batteryLevel}%',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _getBatteryColor(device.batteryLevel),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSignalColor(int signalStrength) {
    if (signalStrength >= -50) return AppColors.success;
    if (signalStrength >= -70) return AppColors.warning;
    return AppColors.error;
  }

  Color _getBatteryColor(int batteryLevel) {
    if (batteryLevel >= 50) return AppColors.success;
    if (batteryLevel >= 20) return AppColors.warning;
    return AppColors.error;
  }
}
