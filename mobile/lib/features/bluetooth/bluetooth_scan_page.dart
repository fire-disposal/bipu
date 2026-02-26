import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_user/core/services/bluetooth_device_service.dart';
import 'package:flutter_user/features/bluetooth/device_detail_page.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothScanPage extends StatefulWidget {
  const BluetoothScanPage({super.key});

  @override
  State<BluetoothScanPage> createState() => _BluetoothScanPageState();
}

class _BluetoothScanPageState extends State<BluetoothScanPage> {
  final BluetoothDeviceService _bluetoothService = BluetoothDeviceService();
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  BluetoothDevice? _connectingDevice;

  static const String _pagerServiceUUID =
      '6e400001-b5a3-f393-e0a9-e50e24dcca9e'; // Nordic UART Service

  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;
  late StreamSubscription<BluetoothAdapterState> _adapterStateSubscription;
  VoidCallback? _connectionStateListener;

  @override
  void initState() {
    super.initState();
    _setupListeners();
    _checkPermissions();
  }

  void _setupListeners() {
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      if (mounted) setState(() {});
    });

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      results.sort((a, b) => b.rssi.compareTo(a.rssi));
      _scanResults = results;
      if (mounted) setState(() {});
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      _isScanning = state;
      if (mounted) setState(() {});
    });

    _connectionStateListener = () {
      final state = _bluetoothService.connectionState.value;
      if (state == BluetoothConnectionState.connected) {
        setState(() => _connectingDevice = null);
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const DeviceDetailPage()),
          );
        }
      } else if (state == BluetoothConnectionState.disconnected) {
        setState(() => _connectingDevice = null);
      }
    };
    _bluetoothService.connectionState.addListener(_connectionStateListener!);
  }

  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      var scanPermission = await Permission.bluetoothScan.request();
      var connectPermission = await Permission.bluetoothConnect.request();
      var locationPermission = await Permission.location.request();

      if (scanPermission.isDenied ||
          connectPermission.isDenied ||
          locationPermission.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('需要蓝牙和位置权限才能扫描设备。'),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    _adapterStateSubscription.cancel();
    if (_connectionStateListener != null) {
      _bluetoothService.connectionState.removeListener(_connectionStateListener!);
      _connectionStateListener = null;
    }
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  Future<void> _startScan() async {
    if (_adapterState != BluetoothAdapterState.on) {
      if (Platform.isAndroid) {
        await FlutterBluePlus.turnOn();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请先开启蓝牙。')),
          );
        }
      }
      return;
    }

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('扫描失败：$e')),
        );
      }
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (_connectingDevice != null) return;

    setState(() => _connectingDevice = device);
    await FlutterBluePlus.stopScan();
    await _bluetoothService.connect(device);
  }

  bool _isPagerDevice(BluetoothDevice device) {
    final name = device.platformName.toLowerCase();
    return name.contains('pager') ||
        name.contains('beeper') ||
        name.contains('bp-') ||
        name.contains('bipupu') ||
        name.startsWith('bp') ||
        name.startsWith('pg');
  }

  List<ScanResult> get _filteredScanResults {
    return _scanResults.where((result) => _isPagerDevice(result.device)).toList();
  }

  Widget _buildScanResultTile(ScanResult result) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isConnecting = _connectingDevice?.remoteId == result.device.remoteId;
    final deviceName = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : '未知设备';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isConnecting ? null : () => _connectToDevice(result.device),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 设备信息（无图标）
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deviceName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14,
                            color: colorScheme.onSurface.withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            result.device.remoteId.str,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.signal_cellular_alt,
                          size: 14,
                          color: _getSignalColor(result.rssi),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${result.rssi} dBm',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    if (isConnecting)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '连接中...',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // 连接按钮
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isConnecting
                      ? colorScheme.surface
                      : colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isConnecting
                        ? colorScheme.outline
                        : colorScheme.primary,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isConnecting)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                        ),
                      )
                    else
                      Icon(
                        Icons.bluetooth_connected,
                        size: 16,
                        color: colorScheme.onPrimary,
                      ),
                    const SizedBox(width: 6),
                    Text(
                      isConnecting ? '连接中' : '连接',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isConnecting
                            ? colorScheme.onSurface
                            : colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filteredResults = _filteredScanResults;

    return Scaffold(
      appBar: AppBar(
        title: const Text('连接蓝牙设备'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _adapterState == BluetoothAdapterState.on
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _adapterState == BluetoothAdapterState.on
                    ? Colors.green
                    : Colors.red,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _adapterState == BluetoothAdapterState.on
                      ? Icons.bluetooth
                      : Icons.bluetooth_disabled,
                  size: 16,
                  color: _adapterState == BluetoothAdapterState.on
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  _adapterState == BluetoothAdapterState.on ? '开启' : '关闭',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _adapterState == BluetoothAdapterState.on
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 状态提示区
            if (_adapterState != BluetoothAdapterState.on)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '蓝牙未开启',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '请开启蓝牙以搜索和连接设备',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: colorScheme.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '正在搜索附近的寻呼机设备...\n找到设备后点击"连接"进行配对。',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shield_outlined, size: 14, color: colorScheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  '智能设备识别中',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // 设备列表
            Expanded(
              child: filteredResults.isEmpty && !_isScanning
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bluetooth_searching,
                            size: 64,
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '未找到寻呼机设备',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '确保设备已开启并在蓝牙范围内',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _startScan,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredResults.length,
                        itemBuilder: (context, index) {
                          return _buildScanResultTile(filteredResults[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton.extended(
          onPressed: _isScanning ? null : _startScan,
          backgroundColor:
              _isScanning ? colorScheme.surface : colorScheme.primary,
          foregroundColor:
              _isScanning ? colorScheme.onSurface : colorScheme.onPrimary,
          elevation: 4,
          icon: _isScanning
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.bluetooth_searching),
          label: Text(_isScanning ? '扫描中...' : '扫描设备'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Color _getSignalColor(int rssi) {
    if (rssi >= -50) return Colors.green;
    if (rssi >= -70) return Colors.orange;
    return Colors.red;
  }
}