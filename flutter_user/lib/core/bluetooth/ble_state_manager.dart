import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../constants/ble_constants.dart';

/// BLE连接状态枚举
enum BleConnectionState { disconnected, connecting, connected, disconnecting }

/// BLE设备信息模型
class BleDeviceInfo {
  final BluetoothDevice device;
  final int? batteryLevel;
  final bool isLastConnected;

  const BleDeviceInfo({
    required this.device,
    this.batteryLevel,
    this.isLastConnected = false,
  });

  String get name =>
      device.platformName.isEmpty ? 'Unknown Device' : device.platformName;
  String get id => device.remoteId.toString();
}

/// BLE状态管理器
class BleStateManager extends ChangeNotifier {
  BleConnectionState _connectionState = BleConnectionState.disconnected;
  BluetoothDevice? _connectedDevice;
  int? _batteryLevel;
  bool _isScanning = false;
  List<BleDeviceInfo> _devices = [];
  String? _lastConnectedDeviceId;

  BleConnectionState get connectionState => _connectionState;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  int? get batteryLevel => _batteryLevel;
  bool get isScanning => _isScanning;
  List<BleDeviceInfo> get devices => _devices;
  bool get isConnected => _connectionState == BleConnectionState.connected;
  bool get isConnecting => _connectionState == BleConnectionState.connecting;

  void updateConnectionState(BleConnectionState state) {
    if (_connectionState != state) {
      _connectionState = state;
      notifyListeners();
    }
  }

  void updateConnectedDevice(BluetoothDevice? device) {
    if (_connectedDevice?.remoteId != device?.remoteId) {
      _connectedDevice = device;
      notifyListeners();
    }
  }

  void updateBatteryLevel(int? level) {
    if (_batteryLevel != level) {
      _batteryLevel = level;
      notifyListeners();
    }
  }

  void updateScanningState(bool scanning) {
    if (_isScanning != scanning) {
      _isScanning = scanning;
      notifyListeners();
    }
  }

  void updateDevices(List<ScanResult> scanResults, String? lastConnectedId) {
    _devices = scanResults.map((result) {
      final isLastConnected =
          lastConnectedId != null &&
          result.device.remoteId.toString() == lastConnectedId;
      return BleDeviceInfo(
        device: result.device,
        isLastConnected: isLastConnected,
      );
    }).toList();
    notifyListeners();
  }

  void updateLastConnectedDeviceId(String? deviceId) {
    _lastConnectedDeviceId = deviceId;
  }

  void clearDevices() {
    _devices = [];
    notifyListeners();
  }

  void reset() {
    _connectionState = BleConnectionState.disconnected;
    _connectedDevice = null;
    _batteryLevel = null;
    _isScanning = false;
    _devices = [];
    notifyListeners();
  }
}
