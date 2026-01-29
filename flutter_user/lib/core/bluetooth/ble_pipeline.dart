import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/ble_constants.dart';
import '../protocol/ble_protocol.dart';

/// 统一的蓝牙管道接口 - 简化版蓝牙管理
class BlePipeline extends ChangeNotifier {
  static final BlePipeline _instance = BlePipeline._internal();
  factory BlePipeline() => _instance;
  BlePipeline._internal() {
    _init();
  }

  // 核心状态
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isConnected = false;
  BluetoothDevice? _connectedDevice;
  int? _batteryLevel;
  List<ScanResult> _scanResults = [];
  String? _lastConnectedDeviceId;

  // 订阅管理
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _batterySubscription;
  StreamSubscription? _adapterStateSubscription;

  // 定时器
  Timer? _connectionTimeoutTimer;
  Timer? _autoReconnectTimer;

  // SharedPreferences
  SharedPreferences? _prefs;

  // Getters
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  int? get batteryLevel => _batteryLevel;
  List<ScanResult> get scanResults => _scanResults;
  String? get lastConnectedDeviceId => _lastConnectedDeviceId;

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _lastConnectedDeviceId = _prefs?.getString(
      BleConstants.lastConnectedDeviceKey,
    );
    _setupBluetoothStateListener();

    // 自动重连
    if (_prefs?.getBool(BleConstants.autoReconnectEnabledKey) ?? true) {
      _scheduleAutoReconnect();
    }
  }

  void _setupBluetoothStateListener() {
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.off) {
        debugPrint('Bluetooth disabled');
        disconnect();
      } else if (state == BluetoothAdapterState.on &&
          (_prefs?.getBool(BleConstants.autoReconnectEnabledKey) ?? true) &&
          _lastConnectedDeviceId != null) {
        _scheduleAutoReconnect();
      }
    });
  }

  /// 检查权限
  Future<bool> checkPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final location = await Permission.location.request();
      final scan = await Permission.bluetoothScan.request();
      final connect = await Permission.bluetoothConnect.request();
      return location.isGranted && scan.isGranted && connect.isGranted;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final bluetooth = await Permission.bluetooth.request();
      return bluetooth.isGranted;
    }
    return false;
  }

  /// 开始扫描
  Future<void> startScan() async {
    if (_isScanning) return;

    if (!await checkPermissions()) {
      debugPrint("BLE Permissions denied");
      return;
    }

    _scanResults = [];
    _isScanning = true;
    notifyListeners();

    try {
      await FlutterBluePlus.startScan(timeout: BleConstants.scanTimeout);

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        _scanResults = results.where((r) {
          final name = r.device.platformName.toUpperCase();
          final hasNameMatch = BleConstants.deviceNameFilters.any(
            (filter) => name.contains(filter),
          );
          final hasServiceMatch = r.advertisementData.serviceUuids.contains(
            BleConstants.serviceGuid,
          );
          return hasNameMatch || hasServiceMatch;
        }).toList();
        notifyListeners();
      });

      FlutterBluePlus.isScanning.listen((scanning) {
        _isScanning = scanning;
        notifyListeners();
      });
    } catch (e) {
      debugPrint("Start scan error: $e");
      _isScanning = false;
      notifyListeners();
    }
  }

  /// 停止扫描
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();
      _isScanning = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Stop scan error: $e");
    }
  }

  /// 连接设备
  Future<void> connect(BluetoothDevice device) async {
    if (_isConnecting) return;

    try {
      _isConnecting = true;
      notifyListeners();

      await stopScan();
      _setupConnectionTimeout(device);

      await device.connect(license: License.free);

      _connectionTimeoutTimer?.cancel();
      _handleConnectionSuccess(device);
    } catch (e) {
      _connectionTimeoutTimer?.cancel();
      _handleConnectionFailure();
      rethrow;
    }
  }

  void _setupConnectionTimeout(BluetoothDevice device) {
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = Timer(BleConstants.connectionTimeout, () async {
      if (_isConnecting) {
        await device.disconnect();
        _handleConnectionFailure();
      }
    });
  }

  void _handleConnectionSuccess(BluetoothDevice device) {
    _connectedDevice = device;
    _isConnected = true;
    _isConnecting = false;
    _lastConnectedDeviceId = device.remoteId.toString();

    _prefs?.setString(
      BleConstants.lastConnectedDeviceKey,
      _lastConnectedDeviceId!,
    );

    _setupConnectionListener(device);
    _discoverServices(device);

    notifyListeners();
    debugPrint('Connected to ${device.platformName}');
  }

  void _handleConnectionFailure() {
    _isConnected = false;
    _isConnecting = false;
    _connectedDevice = null;
    notifyListeners();
  }

  void _setupConnectionListener(BluetoothDevice device) {
    _connectionSubscription?.cancel();
    _connectionSubscription = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _handleDisconnection();
      }
    });
  }

  void _handleDisconnection() {
    _isConnected = false;
    _connectedDevice = null;
    _batterySubscription?.cancel();
    notifyListeners();

    if (_prefs?.getBool(BleConstants.autoReconnectEnabledKey) ?? true) {
      _scheduleAutoReconnect();
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    try {
      await _connectedDevice?.disconnect();
    } catch (e) {
      debugPrint("Disconnect error: $e");
    } finally {
      _isConnected = false;
      _connectedDevice = null;
      _connectionSubscription?.cancel();
      _batterySubscription?.cancel();
      _prefs?.remove(BleConstants.lastConnectedDeviceKey);
      notifyListeners();
    }
  }

  /// 发现服务
  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();

      for (final service in services) {
        final serviceUuid = service.uuid.toString().toUpperCase();

        if (serviceUuid == BleConstants.serviceUuid.toUpperCase()) {
          await _handleCustomService(service);
        } else if (serviceUuid.contains(BleConstants.batteryServiceUuid)) {
          await _handleBatteryService(service);
        }
      }
    } catch (e) {
      debugPrint("Discover services error: $e");
    }
  }

  Future<void> _handleCustomService(BluetoothService service) async {
    for (final characteristic in service.characteristics) {
      final charUuid = characteristic.uuid.toString().toUpperCase();

      if (charUuid == BleConstants.notifyCharUuid.toUpperCase()) {
        await characteristic.setNotifyValue(true);
        characteristic.lastValueStream.listen(_handleNotification);
      }
    }
  }

  Future<void> _handleBatteryService(BluetoothService service) async {
    for (final characteristic in service.characteristics) {
      if (characteristic.uuid.toString().toUpperCase().contains(
        BleConstants.batteryLevelCharUuid,
      )) {
        try {
          final value = await characteristic.read();
          if (value.isNotEmpty) {
            _batteryLevel = value[0];
            notifyListeners();
          }
        } catch (e) {
          debugPrint("Error reading battery: $e");
        }

        if (characteristic.properties.notify) {
          await characteristic.setNotifyValue(true);
          _batterySubscription = characteristic.lastValueStream.listen((value) {
            if (value.isNotEmpty) {
              _batteryLevel = value[0];
              notifyListeners();
            }
          });
        }
        break;
      }
    }
  }

  void _handleNotification(List<int> value) {
    debugPrint("Received notification: $value");
  }

  /// 自动重连
  void _scheduleAutoReconnect() {
    _autoReconnectTimer?.cancel();
    _autoReconnectTimer = Timer(BleConstants.autoReconnectDelay, () {
      if (!_isConnected && !_isConnecting && _lastConnectedDeviceId != null) {
        _attemptAutoReconnect();
      }
    });
  }

  void _attemptAutoReconnect() async {
    try {
      await startScan();
      await Future.delayed(const Duration(seconds: 3));

      final targetDevice = _scanResults.firstWhere(
        (result) => result.device.remoteId.toString() == _lastConnectedDeviceId,
        orElse: () => _scanResults.first,
      );

      if (targetDevice.device.remoteId.toString() == _lastConnectedDeviceId) {
        await connect(targetDevice.device);
      }
    } catch (e) {
      debugPrint('Auto-reconnect failed: $e');
      _scheduleAutoReconnect();
    }
  }

  /// 发送数据 - 统一的数据发送接口
  Future<void> sendData(List<int> data) async {
    if (!_isConnected) {
      throw Exception("Device not connected");
    }

    final writeCharacteristic = await _findWriteCharacteristic();
    if (writeCharacteristic == null) {
      throw Exception("Write characteristic not found");
    }

    // 重试机制
    const maxRetries = 3;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await writeCharacteristic.write(data, withoutResponse: true);
        debugPrint('Data sent successfully');
        return;
      } catch (e) {
        if (attempt == maxRetries) {
          throw Exception('Failed to send data after $maxRetries attempts: $e');
        }
        await Future.delayed(Duration(milliseconds: 100 * attempt));
      }
    }
  }

  Future<BluetoothCharacteristic?> _findWriteCharacteristic() async {
    if (_connectedDevice == null) return null;

    try {
      final services = _connectedDevice!.servicesList;

      for (final service in services) {
        if (service.uuid.toString().toUpperCase() ==
            BleConstants.serviceUuid.toUpperCase()) {
          for (final characteristic in service.characteristics) {
            final charUuid = characteristic.uuid.toString().toUpperCase();
            if (charUuid == BleConstants.writeCharUuid.toUpperCase() &&
                characteristic.properties.write) {
              return characteristic;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error finding write characteristic: $e');
    }
    return null;
  }

  /// 发送协议消息 - 简化的消息发送
  Future<void> sendMessage({
    List<ColorData> colors = const [],
    VibrationType vibration = VibrationType.none,
    ScreenEffect screenEffect = ScreenEffect.none,
    String text = '',
  }) async {
    final packet = BleProtocol.createPacket(
      colors: colors,
      vibration: vibration,
      screenEffect: screenEffect,
      text: text,
    );

    await sendData(packet);
  }

  /// 时间同步
  Future<void> syncTime() async {
    if (!_isConnected) {
      throw Exception('Device not connected');
    }

    final now = DateTime.now();
    final packet = _createTimeSyncPacket(now);
    await sendData(packet);
    debugPrint('Time synchronized: ${now.hour}:${now.minute}');
  }

  List<int> _createTimeSyncPacket(DateTime time) {
    final packet = BytesBuilder();
    packet.addByte(BleConstants.cmdTimeSync);
    packet.addByte(time.hour);
    packet.addByte(time.minute);
    packet.addByte(time.second);
    packet.addByte(time.weekday - 1);

    final bytes = packet.toBytes();
    int checksum = 0;
    for (final byte in bytes) {
      checksum += byte.toInt();
    }
    packet.addByte(checksum & 0xFF);

    return packet.toBytes();
  }

  /// 设置自动重连
  Future<void> setAutoReconnect(bool enabled) async {
    await _prefs?.setBool(BleConstants.autoReconnectEnabledKey, enabled);
    if (!enabled) {
      _autoReconnectTimer?.cancel();
    }
  }

  bool get autoReconnectEnabled =>
      _prefs?.getBool(BleConstants.autoReconnectEnabledKey) ?? true;

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _batterySubscription?.cancel();
    _adapterStateSubscription?.cancel();
    _connectionTimeoutTimer?.cancel();
    _autoReconnectTimer?.cancel();
    super.dispose();
  }
}
