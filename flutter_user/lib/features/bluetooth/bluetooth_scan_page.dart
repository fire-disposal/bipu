import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:go_router/go_router.dart';
import '../../core/bluetooth/ble_pipeline.dart';
import '../../core/bluetooth/ble_simple_ui.dart';
import '../../core/services/toast_service.dart';

/// 简化的蓝牙扫描页面
class BluetoothScanPage extends StatefulWidget {
  const BluetoothScanPage({super.key});

  @override
  State<BluetoothScanPage> createState() => _BluetoothScanPageState();
}

class _BluetoothScanPageState extends State<BluetoothScanPage> {
  final BlePipeline _blePipeline = BlePipeline();
  late final SimpleBleState _state;

  @override
  void initState() {
    super.initState();
    _state = SimpleBleState();
    _state.addListener(_onBleStateChanged);
    _startScan();
  }

  @override
  void dispose() {
    _state.removeListener(_onBleStateChanged);
    _blePipeline.stopScan();
    _state.dispose();
    super.dispose();
  }

  void _onBleStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _startScan() async {
    await _blePipeline.startScan();
  }

  Future<void> _connect(BluetoothDevice device) async {
    if (_blePipeline.isConnecting) {
      ToastService().showInfo('Connection already in progress');
      return;
    }

    try {
      _showConnectingDialog(device);

      await _blePipeline.connect(device);

      if (mounted) {
        Navigator.pop(context); // Close loading
        ToastService().showSuccess('Connected to ${device.platformName}');

        // 连接成功后立即触发时间同�?
        try {
          await _blePipeline.syncTime();
          ToastService().showSuccess('Time synchronized successfully');
        } catch (e) {
          ToastService().showWarning('Time sync failed: $e');
        }

        context.pushReplacement('/bluetooth/control');
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
          if (_state.isScanning)
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
          // 状态信�?
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

          // 状态指示器
          SimpleBleStatusIndicator(state: _state),

          // 设备列表
          Expanded(
            child: AnimatedBuilder(
              animation: _state,
              builder: (context, child) {
                final scanResults = _state.scanResults;

                if (scanResults.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  itemCount: scanResults.length,
                  itemBuilder: (context, index) {
                    final result = scanResults[index];
                    final device = result.device;
                    final isLastConnected =
                        device.remoteId.toString() ==
                        _blePipeline.lastConnectedDeviceId;

                    return SimpleBleDeviceListItem(
                      deviceInfo: SimpleBleDeviceInfo(
                        device: device,
                        isLastConnected: isLastConnected,
                      ),
                      isConnecting: _state.isConnecting && isLastConnected,
                      onConnect: () => _connect(device),
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
            _state.isScanning ? 'Scanning...' : 'No devices found',
            style: TextStyle(color: Colors.grey[500]),
          ),
          if (!_state.isScanning)
            TextButton(onPressed: _startScan, child: const Text("Scan Again")),
        ],
      ),
    );
  }
}
