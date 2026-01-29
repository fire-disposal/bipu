import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:go_router/go_router.dart';
import '../../core/bluetooth/ble_ui_components.dart';
import '../../core/bluetooth/ble_state_manager.dart';
import '../../services/ble_service.dart';
import '../../core/services/toast_service.dart';

/// 重构后的蓝牙扫描页面
class BluetoothScanPage extends StatefulWidget {
  const BluetoothScanPage({super.key});

  @override
  State<BluetoothScanPage> createState() => _BluetoothScanPageState();
}

class _BluetoothScanPageState extends State<BluetoothScanPage> {
  final BleService _bleService = BleService();
  late final BleStateManager _stateManager;

  @override
  void initState() {
    super.initState();
    _stateManager = _bleService.stateManager;
    _stateManager.addListener(_onBleStateChanged);
    _startScan();
  }

  @override
  void dispose() {
    _stateManager.removeListener(_onBleStateChanged);
    _bleService.stopScan();
    super.dispose();
  }

  void _onBleStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _startScan() async {
    await _bleService.startScan();
  }

  Future<void> _connect(BluetoothDevice device) async {
    if (_bleService.isConnecting) {
      ToastService().showInfo('Connection already in progress');
      return;
    }

    try {
      _showConnectingDialog(device);

      await _bleService.connect(device);

      if (mounted) {
        Navigator.pop(context); // Close loading
        ToastService().showSuccess('Connected to ${device.platformName}');
        context.push('/bluetooth/control');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ToastService().showError('Connection failed: $e');
      }
    }
  }

  void _showConnectingDialog(BluetoothDevice device) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Connecting to ${device.platformName}...',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Devices'),
        actions: [
          if (_stateManager.isScanning)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.refresh), onPressed: _startScan),
        ],
      ),
      body: Column(
        children: [
          // 状态信息
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.withValues(alpha: 0.1),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.blue),
                SizedBox(width: 10),
                Expanded(child: Text("Only 'BIPUPU' devices will be shown.")),
              ],
            ),
          ),

          // 设备列表
          Expanded(
            child: AnimatedBuilder(
              animation: _stateManager,
              builder: (context, child) {
                final devices = _stateManager.devices;

                if (devices.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final deviceInfo = devices[index];
                    return BleDeviceListItem(
                      deviceInfo: deviceInfo,
                      isConnecting:
                          _stateManager.isConnecting &&
                          deviceInfo.isLastConnected,
                      onConnect: () => _connect(deviceInfo.device),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bluetooth_searching, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _stateManager.isScanning ? 'Scanning...' : 'No devices found',
            style: TextStyle(color: Colors.grey[500]),
          ),
          if (!_stateManager.isScanning)
            TextButton(onPressed: _startScan, child: const Text("Scan Again")),
        ],
      ),
    );
  }
}
