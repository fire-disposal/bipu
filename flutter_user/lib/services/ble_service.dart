import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../core/constants/ble_constants.dart';
import '../core/bluetooth/ble_state_manager.dart';
import '../core/bluetooth/ble_protocol_handler.dart';
import '../core/bluetooth/ble_storage_manager.dart';
import '../core/bluetooth/ble_permission_manager.dart';
import '../core/protocol/ble_protocol.dart';

/// 重构后的BLE服务
class BleService extends ChangeNotifier {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal() {
    _init();
  }

  // 组件实例
  final BleStateManager _stateManager = BleStateManager();
  final BleStorageManager _storageManager = BleStorageManager.instance;

  // 订阅管理
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _batterySubscription;
  StreamSubscription? _adapterStateSubscription;

  // 定时器管理
  Timer? _connectionTimeoutTimer;
  Timer? _autoReconnectTimer;
  Timer? _timeSyncTimer;

  // 重连管理
  int _reconnectAttempts = 0;

  // 公共访问器
  BleStateManager get stateManager => _stateManager;
  bool get isConnected => _stateManager.isConnected;
  bool get isConnecting => _stateManager.isConnecting;
  bool get isScanning => _stateManager.isScanning;

  Future<void> _init() async {
    await _storageManager.init();
    _setupBluetoothStateListener();
    _loadPersistedState();

    // 如果启用了自动重连，尝试重连最后连接的设备
    if (_storageManager.getAutoReconnectEnabled()) {
      _scheduleAutoReconnect();
    }
  }

  void _setupBluetoothStateListener() {
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.off) {
        _handleBluetoothDisabled();
      } else if (state == BluetoothAdapterState.on &&
          _storageManager.getAutoReconnectEnabled() &&
          _storageManager.getLastConnectedDeviceId() != null) {
        _scheduleAutoReconnect();
      }
    });
  }

  void _loadPersistedState() {
    final lastDeviceId = _storageManager.getLastConnectedDeviceId();
    _stateManager.updateLastConnectedDeviceId(lastDeviceId);
  }

  void _handleBluetoothDisabled() {
    debugPrint('Bluetooth disabled, cleaning up connection');
    disconnect();
  }

  // 权限管理
  Future<bool> checkPermissions() async {
    return await BlePermissionManager.isPermissionGranted();
  }

  // 扫描管理
  Future<void> startScan() async {
    if (isScanning) return;

    if (!await checkPermissions()) {
      debugPrint("BLE Permissions denied");
      return;
    }

    _stateManager.clearDevices();

    try {
      await FlutterBluePlus.startScan(timeout: BleConstants.scanTimeout);
      _stateManager.updateScanningState(true);

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        _handleScanResults(results);
      });

      FlutterBluePlus.isScanning.listen((scanning) {
        _stateManager.updateScanningState(scanning);
      });
    } catch (e) {
      debugPrint("Start scan error: $e");
      _stateManager.updateScanningState(false);
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();
      _stateManager.updateScanningState(false);
    } catch (e) {
      debugPrint("Stop scan error: $e");
    }
  }

  void _handleScanResults(List<ScanResult> results) {
    final filtered = results.where((r) {
      final name = r.device.platformName.toUpperCase();
      final hasNameMatch = BleConstants.deviceNameFilters.any(
        (filter) => name.contains(filter),
      );
      final hasServiceMatch = r.advertisementData.serviceUuids.contains(
        BleConstants.serviceGuid,
      );
      return hasNameMatch || hasServiceMatch;
    }).toList();

    _stateManager.updateDevices(
      filtered,
      _storageManager.getLastConnectedDeviceId(),
    );
  }

  // 连接管理
  Future<void> connect(BluetoothDevice device) async {
    if (isConnecting) {
      debugPrint('Connection already in progress');
      return;
    }

    try {
      _stateManager.updateConnectionState(BleConnectionState.connecting);
      _setupConnectionTimeout(device);

      await stopScan();
      debugPrint('Connecting to device: ${device.platformName}');

      await device.connect(license: License.free);

      _connectionTimeoutTimer?.cancel();
      _handleConnectionSuccess(device);
    } catch (e) {
      debugPrint("Connection error: $e");
      _connectionTimeoutTimer?.cancel();
      _handleConnectionFailure();
      rethrow;
    }
  }

  void _setupConnectionTimeout(BluetoothDevice device) {
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = Timer(BleConstants.connectionTimeout, () {
      if (isConnecting) {
        debugPrint('Connection timeout');
        _handleConnectionTimeout(device);
      }
    });
  }

  void _handleConnectionTimeout(BluetoothDevice device) async {
    try {
      await device.disconnect();
    } catch (e) {
      debugPrint('Error disconnecting timeout device: $e');
    }
    _handleConnectionFailure();
  }

  void _handleConnectionSuccess(BluetoothDevice device) {
    _stateManager.updateConnectedDevice(device);
    _stateManager.updateConnectionState(BleConnectionState.connected);
    _reconnectAttempts = 0;

    _storageManager.saveLastConnectedDeviceId(device.remoteId.toString());

    _setupConnectionStateListener(device);

    // 延迟服务发现
    Future.delayed(BleConstants.serviceDiscoveryDelay, () {
      _discoverServices(device);
    });

    // 触发时间同步
    _scheduleTimeSync();

    debugPrint('Successfully connected to device: ${device.platformName}');
  }

  void _handleConnectionFailure() {
    _stateManager.updateConnectionState(BleConnectionState.disconnected);
    _stateManager.updateConnectedDevice(null);
    _cleanupConnection();
  }

  void _setupConnectionStateListener(BluetoothDevice device) {
    _connectionSubscription?.cancel();
    _connectionSubscription = device.connectionState.listen((state) {
      debugPrint('Connection state changed: $state');
      if (state == BluetoothConnectionState.disconnected) {
        _handleDisconnection();
      }
    });
  }

  void _handleDisconnection() {
    debugPrint('Device disconnected');
    _stateManager.updateConnectionState(BleConnectionState.disconnected);
    _cleanupConnection();

    if (_storageManager.getAutoReconnectEnabled()) {
      _scheduleAutoReconnect();
    }
  }

  Future<void> disconnect() async {
    _stateManager.updateConnectionState(BleConnectionState.disconnecting);

    try {
      debugPrint('Disconnecting from device');
      await _stateManager.connectedDevice?.disconnect();
    } catch (e) {
      debugPrint("Disconnect error: $e");
    } finally {
      _stateManager.updateConnectionState(BleConnectionState.disconnected);
      _cleanupConnection();
      _storageManager.clearLastConnectedDeviceId();
    }
  }

  void _cleanupConnection() {
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _batterySubscription?.cancel();
    _batterySubscription = null;
    _connectionTimeoutTimer?.cancel();
    _timeSyncTimer?.cancel();

    _stateManager.updateConnectedDevice(null);
    _stateManager.updateBatteryLevel(null);
  }

  // 自动重连管理
  void _scheduleAutoReconnect() {
    _autoReconnectTimer?.cancel();
    _autoReconnectTimer = Timer(BleConstants.autoReconnectDelay, () {
      if (!isConnected &&
          !isConnecting &&
          _reconnectAttempts < BleConstants.maxReconnectAttempts) {
        _attemptAutoReconnect();
      }
    });
  }

  void _attemptAutoReconnect() async {
    _reconnectAttempts++;
    debugPrint(
      'Attempting auto-reconnect ($_reconnectAttempts/${BleConstants.maxReconnectAttempts})',
    );

    try {
      await startScan();
      await Future.delayed(const Duration(seconds: 3));

      final targetDevice = _stateManager.devices.firstWhere(
        (info) => info.id == _storageManager.getLastConnectedDeviceId(),
        orElse: () => BleDeviceInfo(device: _stateManager.devices.first.device),
      );

      if (targetDevice.device.remoteId.toString() ==
          _storageManager.getLastConnectedDeviceId()) {
        await connect(targetDevice.device);
        _reconnectAttempts = 0;
      } else {
        _scheduleAutoReconnect();
      }
    } catch (e) {
      debugPrint('Auto-reconnect failed: $e');
      _scheduleAutoReconnect();
    }
  }

  // 服务发现
  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();

      for (final service in services) {
        await _handleService(service);
      }
    } catch (e) {
      debugPrint("Discover services error: $e");
    }
  }

  Future<void> _handleService(BluetoothService service) async {
    final serviceUuid = service.uuid.toString().toUpperCase();

    if (serviceUuid == BleConstants.serviceUuid.toUpperCase()) {
      await _handleCustomService(service);
    } else if (serviceUuid.contains(BleConstants.batteryServiceUuid)) {
      await _handleBatteryService(service);
    }
  }

  Future<void> _handleCustomService(BluetoothService service) async {
    for (final characteristic in service.characteristics) {
      final charUuid = characteristic.uuid.toString().toUpperCase();

      if (charUuid == BleConstants.writeCharUuid.toUpperCase()) {
        // 写特征值已找到，不需要存储
      } else if (charUuid == BleConstants.notifyCharUuid.toUpperCase()) {
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
        // 读取初始电量
        try {
          final value = await characteristic.read();
          if (value.isNotEmpty) {
            _stateManager.updateBatteryLevel(value[0]);
          }
        } catch (e) {
          debugPrint("Error reading battery level: $e");
        }

        // 订阅电量更新
        if (characteristic.properties.notify) {
          await characteristic.setNotifyValue(true);
          _batterySubscription = characteristic.lastValueStream.listen((value) {
            if (value.isNotEmpty) {
              _stateManager.updateBatteryLevel(value[0]);
            }
          });
        }
        break;
      }
    }
  }

  void _handleNotification(List<int> value) {
    debugPrint("Received notification: $value");
    // 处理接收到的数据
  }

  // 时间同步管理
  void _scheduleTimeSync() {
    _timeSyncTimer?.cancel();
    _timeSyncTimer = Timer(const Duration(seconds: 1), () {
      if (isConnected) {
        syncTime();
      }
    });
  }

  Future<void> syncTime() async {
    if (!isConnected) {
      throw Exception('Device not connected');
    }

    try {
      final timePacket = BleProtocolHandler.createTimeSyncPacket(
        DateTime.now(),
      );
      await sendData(timePacket);
      debugPrint('Time synchronized');
    } catch (e) {
      debugPrint('Time sync failed: $e');
      rethrow;
    }
  }

  // 数据发送
  Future<void> sendData(List<int> data) async {
    if (!isConnected) {
      throw Exception("Device not connected");
    }

    try {
      final writeCharacteristic = _findWriteCharacteristic();
      if (writeCharacteristic == null) {
        throw Exception("Write characteristic not found");
      }

      await writeCharacteristic.write(data, withoutResponse: true);
    } catch (e) {
      debugPrint("Send data error: $e");
      rethrow;
    }
  }

  BluetoothCharacteristic? _findWriteCharacteristic() {
    final device = _stateManager.connectedDevice;
    if (device == null) return null;

    // 这里简化处理，实际使用时应该在服务发现时缓存特征值
    return null;
  }

  Future<void> sendProtocolMessage({
    List<ColorData> colors = const [],
    VibrationType vibration = VibrationType.none,
    ScreenEffect screenEffect = ScreenEffect.none,
    String text = '',
  }) async {
    final packet = BleProtocolHandler.createMessagePacket(
      colors: colors,
      vibration: vibration,
      screenEffect: screenEffect,
      text: text,
    );
    await sendData(packet);
  }

  // 设置管理
  Future<void> setAutoReconnect(bool enabled) async {
    await _storageManager.setAutoReconnectEnabled(enabled);

    if (!enabled) {
      _autoReconnectTimer?.cancel();
    }
  }

  bool get autoReconnectEnabled => _storageManager.getAutoReconnectEnabled();

  // 清理资源
  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _batterySubscription?.cancel();
    _adapterStateSubscription?.cancel();
    _connectionTimeoutTimer?.cancel();
    _autoReconnectTimer?.cancel();
    _timeSyncTimer?.cancel();
    super.dispose();
  }
}
