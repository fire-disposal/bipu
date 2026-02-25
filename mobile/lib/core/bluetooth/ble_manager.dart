import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// BLE 连接状态
enum BleConnectionState {
  /// 未连接
  disconnected,

  /// 连接中
  connecting,

  /// 已连接
  connected,

  /// 断开连接中
  disconnecting,

  /// 错误状态
  error,
}

/// BLE 设备信息
class BleDevice {
  final String id;
  final String name;
  final int rssi;
  final bool isConnected;

  const BleDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.isConnected,
  });

  @override
  String toString() => 'BleDevice(id: $id, name: $name, rssi: $rssi)';
}

/// BLE 扫描结果
class BleScanResult {
  final BleDevice device;
  final DateTime timestamp;
  final List<Guid> advertisedServices;

  BleScanResult({
    required this.device,
    required this.timestamp,
    required this.advertisedServices,
  });
}

/// BLE 管理器
///
/// 封装 flutter_blue_plus 的 API，提供统一的 BLE 操作接口
class BleManager {
  /// FlutterBluePlus 实例引用
  // FlutterBluePlus get _fbp => FlutterBluePlus();

  /// 蓝牙适配器状态流
  final _adapterStateController =
      StreamController<BluetoothAdapterState>.broadcast();
  Stream<BluetoothAdapterState> get adapterStateStream =>
      _adapterStateController.stream;

  /// 扫描结果流
  final _scanResultsController = StreamController<BleScanResult>.broadcast();
  Stream<BleScanResult> get scanResultsStream => _scanResultsController.stream;

  /// 已连接设备流
  final _connectedDevicesController =
      StreamController<List<BleDevice>>.broadcast();
  Stream<List<BleDevice>> get connectedDevicesStream =>
      _connectedDevicesController.stream;

  /// 当前连接状态
  BleConnectionState _connectionState = BleConnectionState.disconnected;
  BleConnectionState get connectionState => _connectionState;

  /// 连接状态流
  final _connectionStateController =
      StreamController<BleConnectionState>.broadcast();
  Stream<BleConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// 当前已连接的设备
  final List<BluetoothDevice> _connectedDevices = [];
  List<BleDevice> get connectedDevices {
    return _connectedDevices.map((device) {
      return BleDevice(
        id: device.remoteId.str,
        name: device.platformName,
        rssi: 0, // 已连接设备的 RSSI 通常为 0
        isConnected: device.isConnected,
      );
    }).toList();
  }

  /// 是否正在扫描
  bool _isScanning = false;
  bool get isScanning => _isScanning;

  /// 扫描订阅
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  /// 适配器状态订阅
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  /// 连接状态订阅
  final Map<String, StreamSubscription<BluetoothConnectionState>>
  _connectionSubscriptions = {};

  /// 初始化 BLE 管理器
  Future<void> initialize() async {
    debugPrint('[BleManager] 开始初始化');

    // 监听系统蓝牙适配器状态
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      debugPrint('[BleManager] 适配器状态变化：$state');
      _adapterStateController.add(state);

      // 如果蓝牙关闭，清空连接设备
      if (state == BluetoothAdapterState.off) {
        _connectedDevices.clear();
        _updateConnectedDevices();
      }
    });

    // 设置全局配置
    FlutterBluePlus.setLogLevel(LogLevel.info);

    // 2. 修复：监听连接设备的变化
    // 使用 events.onConnectionStateChanged 来实时捕捉连接状态
    FlutterBluePlus.events.onConnectionStateChanged.listen((event) async {
      debugPrint(
        '[BleManager] 设备连接事件：${event.device.remoteId} -> ${event.connectionState}',
      );

      // 当有设备连接或断开时，主动刷新当前连接的系统设备列表
      final devices = await FlutterBluePlus.systemDevices([]);
      _connectedDevices.clear();
      _connectedDevices.addAll(devices);
      _updateConnectedDevices();
    });

    // 3. 初始启动时手动获取一次已连接设备
    final initialDevices = await FlutterBluePlus.systemDevices([]);
    _connectedDevices.addAll(initialDevices);
    _updateConnectedDevices();
  }

  /// 更新已连接设备列表
  void _updateConnectedDevices() {
    _connectedDevicesController.add(connectedDevices);
  }

  /// 检查蓝牙权限
  Future<bool> checkPermissions() async {
    try {
      // 在新版本中，权限检查可能需要使用 permission_handler 库
      // 这里暂时返回 true 以继续开发
      debugPrint('[BleManager] 权限检查：跳过（需要集成 permission_handler）');
      return true;
    } catch (e) {
      debugPrint('[BleManager] 权限检查失败：$e');
      return false;
    }
  }

  /// 请求蓝牙权限
  Future<bool> requestPermissions() async {
    try {
      debugPrint('[BleManager] 请求权限...');
      // 在新版本中，权限请求可能需要使用 permission_handler 库
      // 这里暂时返回 true 以继续开发
      debugPrint('[BleManager] 权限请求：跳过（需要集成 permission_handler）');
      return true;
    } catch (e) {
      debugPrint('[BleManager] 权限请求失败：$e');
      return false;
    }
  }

  /// 开始扫描设备
  ///
  /// [withServices] 可选，过滤特定服务的设备
  /// [timeout] 扫描超时时间，默认 10 秒
  Future<void> startScan({
    List<Guid>? withServices,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_isScanning) {
      debugPrint('[BleManager] 已在扫描中');
      return;
    }

    try {
      debugPrint('[BleManager] 开始扫描...');
      _isScanning = true;

      // 启动扫描
      await FlutterBluePlus.startScan(
        timeout: timeout,
        removeIfGone: const Duration(seconds: 3),
      );

      // 监听扫描结果
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          // 如果有服务过滤条件，检查设备是否包含指定服务
          if (withServices != null && withServices.isNotEmpty) {
            final deviceServices = result.advertisementData.serviceUuids;
            final hasRequiredService = withServices.any(
              (service) => deviceServices.contains(service),
            );

            if (!hasRequiredService) {
              continue;
            }
          }

          final scanResult = BleScanResult(
            device: BleDevice(
              id: result.device.remoteId.str,
              name: result.device.platformName,
              rssi: result.rssi,
              isConnected: result.device.isConnected,
            ),
            timestamp: DateTime.now(),
            advertisedServices: result.advertisementData.serviceUuids,
          );
          _scanResultsController.add(scanResult);
        }
      });

      // 监听扫描状态变化
      FlutterBluePlus.isScanning.listen((isScanning) {
        if (!isScanning) {
          debugPrint('[BleManager] 扫描完成');
          _isScanning = false;
          _scanSubscription?.cancel();
          _scanSubscription = null;
        }
      });
    } catch (e) {
      debugPrint('[BleManager] 扫描失败：$e');
      _isScanning = false;
      rethrow;
    }
  }

  /// 停止扫描
  Future<void> stopScan() async {
    if (!_isScanning) return;

    try {
      debugPrint('[BleManager] 停止扫描');
      await FlutterBluePlus.stopScan();
      _isScanning = false;
      _scanSubscription?.cancel();
      _scanSubscription = null;
    } catch (e) {
      debugPrint('[BleManager] 停止扫描失败：$e');
      rethrow;
    }
  }

  /// 连接到设备
  ///
  /// [deviceId] 设备 ID（remoteId）
  /// [timeout] 连接超时时间，默认 10 秒
  Future<void> connect(
    String deviceId, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_connectionState == BleConnectionState.connecting) {
      debugPrint('[BleManager] 已在连接中');
      return;
    }

    try {
      debugPrint('[BleManager] 开始连接设备：$deviceId');
      _connectionState = BleConnectionState.connecting;
      _connectionStateController.add(_connectionState);

      // 创建 BluetoothDevice
      final device = BluetoothDevice(remoteId: DeviceIdentifier(deviceId));

      // 监听连接状态
      _connectionSubscriptions[deviceId] = device.connectionState.listen((
        state,
      ) {
        debugPrint('[BleManager] 设备 $deviceId 连接状态：$state');

        switch (state) {
          case BluetoothConnectionState.connected:
            _connectionState = BleConnectionState.connected;
            _connectionStateController.add(_connectionState);
            // 添加到已连接设备列表
            if (!_connectedDevices.contains(device)) {
              _connectedDevices.add(device);
              _updateConnectedDevices();
            }
            break;
          case BluetoothConnectionState.disconnected:
            _connectionState = BleConnectionState.disconnected;
            _connectionStateController.add(_connectionState);
            // 从已连接设备列表中移除
            _connectedDevices.remove(device);
            _updateConnectedDevices();
            _connectionSubscriptions.remove(deviceId);
            break;
          default:
            break;
        }
      });

      // 发起连接
      await device.connect(autoConnect: false, license: License.free);

      debugPrint('[BleManager] 连接成功：$deviceId');
    } catch (e) {
      debugPrint('[BleManager] 连接失败：$e');
      _connectionState = BleConnectionState.error;
      _connectionStateController.add(_connectionState);
      rethrow;
    }
  }

  /// 断开设备连接
  ///
  /// [deviceId] 设备 ID
  Future<void> disconnect(String deviceId) async {
    try {
      debugPrint('[BleManager] 断开设备：$deviceId');
      _connectionState = BleConnectionState.disconnecting;
      _connectionStateController.add(_connectionState);

      final device = BluetoothDevice(remoteId: DeviceIdentifier(deviceId));
      await device.disconnect();

      debugPrint('[BleManager] 断开成功：$deviceId');
      _connectionState = BleConnectionState.disconnected;
      _connectionStateController.add(_connectionState);
    } catch (e) {
      debugPrint('[BleManager] 断开失败：$e');
    }
  }

  /// 断开所有设备连接
  Future<void> disconnectAll() async {
    try {
      debugPrint('[BleManager] 断开所有设备');
      // 获取所有已连接的设备并断开它们
      for (final device in _connectedDevices) {
        try {
          await device.disconnect();
        } catch (e) {
          debugPrint('[BleManager] 断开设备 ${device.remoteId} 失败：$e');
        }
      }
      _connectedDevices.clear();
    } catch (e) {
      debugPrint('[BleManager] 断开所有设备失败：$e');
    }
  }

  /// 获取设备服务
  ///
  /// [deviceId] 设备 ID
  Future<List<BluetoothService>> getServices(String deviceId) async {
    try {
      final device = BluetoothDevice(remoteId: DeviceIdentifier(deviceId));
      final services = await device.discoverServices();
      debugPrint('[BleManager] 发现 ${services.length} 个服务');
      return services;
    } catch (e) {
      debugPrint('[BleManager] 获取服务失败：$e');
      return [];
    }
  }

  /// 读取特征值
  ///
  /// [deviceId] 设备 ID
  /// [serviceUuid] 服务 UUID
  /// [characteristicUuid] 特征 UUID
  Future<List<int>> readCharacteristic(
    String deviceId,
    String serviceUuid,
    String characteristicUuid,
  ) async {
    try {
      final device = BluetoothDevice(remoteId: DeviceIdentifier(deviceId));
      final service = await _getService(device, serviceUuid);
      final characteristic = await _getCharacteristic(
        service,
        characteristicUuid,
      );

      final value = await characteristic.read();
      debugPrint('[BleManager] 读取特征：$value');
      return value;
    } catch (e) {
      debugPrint('[BleManager] 读取特征失败：$e');
      return [];
    }
  }

  /// 写入特征值
  ///
  /// [deviceId] 设备 ID
  /// [serviceUuid] 服务 UUID
  /// [characteristicUuid] 特征 UUID
  /// [value] 要写入的值
  Future<void> writeCharacteristic(
    String deviceId,
    String serviceUuid,
    String characteristicUuid,
    List<int> value,
  ) async {
    try {
      final device = BluetoothDevice(remoteId: DeviceIdentifier(deviceId));
      final service = await _getService(device, serviceUuid);
      final characteristic = await _getCharacteristic(
        service,
        characteristicUuid,
      );

      await characteristic.write(value);
      debugPrint('[BleManager] 写入特征：$value');
    } catch (e) {
      debugPrint('[BleManager] 写入特征失败：$e');
      rethrow;
    }
  }

  /// 订阅特征值变化
  ///
  /// [deviceId] 设备 ID
  /// [serviceUuid] 服务 UUID
  /// [characteristicUuid] 特征 UUID
  Stream<List<int>> subscribeCharacteristic(
    String deviceId,
    String serviceUuid,
    String characteristicUuid,
  ) {
    final controller = StreamController<List<int>>.broadcast();

    Future.microtask(() async {
      try {
        final device = BluetoothDevice(remoteId: DeviceIdentifier(deviceId));
        final service = await _getService(device, serviceUuid);
        final characteristic = await _getCharacteristic(
          service,
          characteristicUuid,
        );

        // 监听特征值变化
        characteristic.onValueReceived.listen((value) {
          controller.add(value);
        });

        // 启用通知
        await characteristic.setNotifyValue(true);

        // 设置清理函数
        controller.onCancel = () async {
          await characteristic.setNotifyValue(false);
        };
      } catch (e) {
        debugPrint('[BleManager] 订阅特征失败：$e');
        controller.addError(e);
      }
    });

    return controller.stream;
  }

  /// 获取服务（内部方法）
  Future<BluetoothService> _getService(
    BluetoothDevice device,
    String uuid,
  ) async {
    final services = await device.discoverServices();
    final service = services.firstWhere(
      (s) => s.serviceUuid.toString().toLowerCase() == uuid.toLowerCase(),
      orElse: () => throw Exception('Service not found: $uuid'),
    );
    return service;
  }

  /// 获取特征（内部方法）
  Future<BluetoothCharacteristic> _getCharacteristic(
    BluetoothService service,
    String uuid,
  ) async {
    final characteristic = service.characteristics.firstWhere(
      (c) =>
          c.characteristicUuid.toString().toLowerCase() == uuid.toLowerCase(),
      orElse: () => throw Exception('Characteristic not found: $uuid'),
    );
    return characteristic;
  }

  /// 释放资源
  void dispose() {
    _scanSubscription?.cancel();
    _adapterStateSubscription?.cancel();

    for (final subscription in _connectionSubscriptions.values) {
      subscription.cancel();
    }
    _connectionSubscriptions.clear();

    _adapterStateController.close();
    _scanResultsController.close();
    _connectedDevicesController.close();
    _connectionStateController.close();
  }
}
