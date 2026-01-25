import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/toast_service.dart';
import '../../services/ble_service.dart';

class BluetoothScanPage extends StatefulWidget {
  const BluetoothScanPage({super.key});

  @override
  State<BluetoothScanPage> createState() => _BluetoothScanPageState();
}

class _BluetoothScanPageState extends State<BluetoothScanPage> {
  final BleService _bleService = BleService();

  @override
  void initState() {
    super.initState();
    _bleService.addListener(_onBleStateChanged);
    _startScan();
  }

  @override
  void dispose() {
    _bleService.removeListener(_onBleStateChanged);
    _bleService.stopScan(); // Stop scanning when leaving page
    super.dispose();
  }

  void _onBleStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _startScan() async {
    await _bleService.startScan();
  }

  Future<void> _connect(BluetoothDevice device) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      await _bleService.connect(device);

      if (mounted) {
        Navigator.pop(context); // Close loading
        ToastService().showSuccess('Connected to ${device.platformName}');
        // Navigate to control page after connection
        context.push('/bluetooth/control');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ToastService().showError('Connection failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Devices'),
        actions: [
          if (_bleService.isScanning)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    // color: Colors.white, // Removed to use theme default
                  ),
                ),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.refresh), onPressed: _startScan),
        ],
      ),
      body: Column(
        children: [
          // Header info
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

          Expanded(
            child: _bleService.scanResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_searching,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _bleService.isScanning
                              ? 'Scanning...'
                              : 'No devices found',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        if (!_bleService.isScanning)
                          TextButton(
                            onPressed: _startScan,
                            child: const Text("Scan Again"),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _bleService.scanResults.length,
                    itemBuilder: (context, index) {
                      final result = _bleService.scanResults[index];
                      return ListTile(
                        leading: const Icon(Icons.bluetooth),
                        title: Text(
                          result.device.platformName.isEmpty
                              ? 'Unknown Device'
                              : result.device.platformName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(result.device.remoteId.toString()),
                        trailing: ElevatedButton(
                          onPressed: () => _connect(result.device),
                          child: const Text('Connect'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
