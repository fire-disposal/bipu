import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'bluetooth_config.dart';

class BluetoothScanPage extends StatefulWidget {
  const BluetoothScanPage({super.key});

  @override
  State<BluetoothScanPage> createState() => _BluetoothScanPageState();
}

class _BluetoothScanPageState extends State<BluetoothScanPage> {
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;
  late StreamSubscription<BluetoothAdapterState> _adapterStateSubscription;

  @override
  void initState() {
    super.initState();

    // 1. Setup Adapter State Listener
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      if (mounted) setState(() {});
    });

    // 2. Setup Scan Results Listener
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results;
      if (mounted) setState(() {});
    });

    // 3. Setup Scanning State Listener
    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      _isScanning = state;
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    _adapterStateSubscription.cancel();
    super.dispose();
  }

  Future<void> _startScan() async {
    // 0. Check for Bluetooth State
    if (_adapterState != BluetoothAdapterState.on) {
      try {
        if (Platform.isAndroid) {
          await FlutterBluePlus.turnOn();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('请先开启蓝牙')));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('无法开启蓝牙: $e')));
        }
      }
      return;
    }

    try {
      // 1. Android Specific: Clean up previous connections if needed?
      // Not strictly necessary with latest lib, but good practice to ensure clean state implies stopScan first.

      // 2. Start Scanning
      // Note: android uses withServices to filter, ios uses withServices to perform "background" scan
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        // androidUsesFineLocation: true, // No longer needed in new versions, handled internally
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('扫描失败: $e')));
      }
    }
  }

  Future<void> _stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      debugPrint("Stop scan error: $e");
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    // 1. Stop scanning before connecting
    await _stopScan();

    try {
      // 2. Connect
      // Note: autoConnect can be unstable on some Android devices, use with caution.
      // We use false here for predictable behavior, implementing reconnection logic manually if needed.
      await device.connect(
        license: License.free,
        timeout: BluetoothConfig.connectionTimeout,
        mtu: BluetoothConfig.defaultMtu,
        autoConnect: false,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '已连接到 ${device.platformName.isNotEmpty ? device.platformName : "设备"}',
            ),
          ),
        );
      }

      // TODO: Navigate to device control page
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('连接失败: $e')));
      }
    }
  }

  Future<void> _disconnectFromDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已断开与 ${device.platformName} 的连接')),
        );
      }
    } catch (e) {
      debugPrint("Disconnect error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('蓝牙扫描'),
        actions: [
          if (_isScanning)
            TextButton(onPressed: _stopScan, child: const Text('停止'))
          else
            TextButton(onPressed: _startScan, child: const Text('扫描')),
        ],
      ),
      body: Column(
        children: [
          // Bluetooth Status Banner
          _buildStatusBanner(),

          // Scan Progress Indicator
          if (_isScanning) const LinearProgressIndicator(),

          // Device List
          Expanded(
            child: _scanResults.isEmpty && !_isScanning
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_searching,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text('未找到设备，请点击扫描'),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _scanResults.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final result = _scanResults[index];
                      return _ScanResultTile(
                        result: result,
                        onConnect: () => _connectToDevice(result.device),
                        onDisconnect: () =>
                            _disconnectFromDevice(result.device),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: _adapterState == BluetoothAdapterState.on
          ? Colors.green[50]
          : Colors.red[50],
      child: Row(
        children: [
          Icon(
            _adapterState == BluetoothAdapterState.on
                ? Icons.bluetooth
                : Icons.bluetooth_disabled,
            color: _adapterState == BluetoothAdapterState.on
                ? Colors.green
                : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _adapterState == BluetoothAdapterState.on
                  ? '蓝牙已准备就绪'
                  : '蓝牙未开启/不可用 (${_adapterState.toString().split('.').last})',
              style: TextStyle(
                color: _adapterState == BluetoothAdapterState.on
                    ? Colors.green[700]
                    : Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_adapterState != BluetoothAdapterState.on && Platform.isAndroid)
            TextButton(
              onPressed: () async {
                try {
                  await FlutterBluePlus.turnOn();
                } catch (e) {
                  // ignore
                }
              },
              child: const Text("开启"),
            ),
        ],
      ),
    );
  }
}

class _ScanResultTile extends StatelessWidget {
  final ScanResult result;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const _ScanResultTile({
    required this.result,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    // Use StreamBuilder to listen to connection state of EACH device
    return StreamBuilder<BluetoothConnectionState>(
      stream: result.device.connectionState,
      initialData: BluetoothConnectionState.disconnected,
      builder: (context, snapshot) {
        final connectionState =
            snapshot.data ?? BluetoothConnectionState.disconnected;
        final isConnected =
            connectionState == BluetoothConnectionState.connected;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isConnected ? Colors.green : Colors.grey.shade300,
            child: Icon(
              isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
              color: isConnected ? Colors.white : Colors.grey,
              size: 20,
            ),
          ),
          title: Text(
            result.device.platformName.isNotEmpty
                ? result.device.platformName
                : '未知设备 (${result.device.remoteId})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.device.remoteId.toString(),
                style: const TextStyle(fontSize: 12),
              ),
              Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "RSSI: ${result.rssi} dBm",
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  if (result.advertisementData.connectable) ...[
                    const SizedBox(width: 8),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: const Text(
                        "可连接",
                        style: TextStyle(fontSize: 10, color: Colors.blue),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          trailing: isConnected
              ? TextButton(
                  onPressed: onDisconnect,
                  child: const Text("断开", style: TextStyle(color: Colors.red)),
                )
              : ElevatedButton(
                  onPressed: result.advertisementData.connectable
                      ? onConnect
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(60, 36),
                  ),
                  child: const Text("连接"),
                ),
          onTap: () {
            // Optional: Navigate to detail page if connected
            if (isConnected) {
              // Navigate
            } else if (result.advertisementData.connectable) {
              onConnect();
            }
          },
        );
      },
    );
  }
}
