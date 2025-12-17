/// 手环设备控制服务
/// 提供向手环设备发送控制命令的高级接口
library;

import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as blue_plus;
import 'ble_protocol.dart';
import 'bluetooth_service.dart' as ble_service;
import '../utils/logger.dart';

/// 设备控制服务 - 单例模式
class DeviceControlService {
  static final DeviceControlService _instance =
      DeviceControlService._internal();

  factory DeviceControlService() => _instance;
  DeviceControlService._internal();

  static DeviceControlService get instance => _instance;

  blue_plus.BluetoothDevice? _connectedDevice;
  blue_plus.BluetoothCharacteristic? _commandCharacteristic;
  blue_plus.BluetoothCharacteristic? _statusCharacteristic;

  bool _isInitialized = false;

  /// 初始化设备控制服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 确保蓝牙服务已初始化
      if (!ble_service.BluetoothService.instance.isInitialized) {
        await ble_service.BluetoothService.instance.initialize();
      }

      _isInitialized = true;
      Logger.info('设备控制服务初始化完成');
    } catch (e) {
      Logger.error('设备控制服务初始化失败: $e');
      rethrow;
    }
  }

  /// 连接到指定设备
  Future<bool> connectToDevice(String deviceId) async {
    try {
      Logger.info('开始连接设备: $deviceId');

      // 断开当前连接
      await disconnect();

      // 创建设备对象
      final device = blue_plus.BluetoothDevice.fromId(deviceId);

      // 连接设备
      await device.connect(
        timeout: const Duration(seconds: 10),
        autoConnect: false,
        license: blue_plus.License.free, // 添加必要的license参数
      );

      // 等待连接建立
      await Future.delayed(const Duration(milliseconds: 500));

      // 发现服务
      final services = await device.discoverServices();

      // 查找设备控制服务
      final controlService = services.firstWhere(
        (service) => service.uuid.str == BleServiceUuids.deviceControlService,
        orElse: () => throw Exception('未找到设备控制服务'),
      );

      // 查找特征值
      _commandCharacteristic = controlService.characteristics.firstWhere(
        (char) => char.uuid.str == BleCharacteristicUuids.commandCharacteristic,
        orElse: () => throw Exception('未找到命令特征值'),
      );

      _statusCharacteristic = controlService.characteristics.firstWhere(
        (char) => char.uuid.str == BleCharacteristicUuids.statusCharacteristic,
        orElse: () => throw Exception('未找到状态特征值'),
      );

      // 启用状态通知
      if (_statusCharacteristic != null &&
          !_statusCharacteristic!.isNotifying) {
        await _statusCharacteristic!.setNotifyValue(true);
      }

      _connectedDevice = device;

      // 监听连接状态
      device.connectionState.listen((state) {
        if (state == blue_plus.BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });

      Logger.info('设备连接成功: $deviceId');
      return true;
    } catch (e) {
      Logger.error('设备连接失败: $e');
      return false;
    }
  }

  /// 断开当前连接
  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        _handleDisconnection();
        Logger.info('设备已断开连接');
      }
    } catch (e) {
      Logger.error('断开连接失败: $e');
    }
  }

  /// 处理设备断开连接
  void _handleDisconnection() {
    _connectedDevice = null;
    _commandCharacteristic = null;
    _statusCharacteristic = null;
  }

  /// 获取当前连接的设备
  blue_plus.BluetoothDevice? get connectedDevice => _connectedDevice;

  /// 检查是否已连接设备
  bool get isConnected =>
      _connectedDevice != null && _commandCharacteristic != null;

  /// 发送消息到设备
  Future<bool> sendMessage(DeviceMessagePacket message) async {
    if (!isConnected) {
      Logger.warning('未连接设备，无法发送消息');
      return false;
    }

    try {
      Logger.info('发送消息到设备: $message');

      // 将消息转换为字节数组
      final messageBytes = message.toBytes();

      // 检查消息大小
      if (messageBytes.length > 512) {
        Logger.warning('消息过大，无法发送');
        return false;
      }

      // 分块发送（如果消息较大）
      const chunkSize = 20; // BLE典型MTU大小
      for (int i = 0; i < messageBytes.length; i += chunkSize) {
        final end = (i + chunkSize < messageBytes.length)
            ? i + chunkSize
            : messageBytes.length;
        final chunk = messageBytes.sublist(i, end);

        await _commandCharacteristic!.write(chunk);

        // 小块之间添加延迟，避免设备处理不过来
        if (end < messageBytes.length) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }

      Logger.info('消息发送成功');
      return true;
    } catch (e) {
      Logger.error('消息发送失败: $e');
      return false;
    }
  }

  /// 发送简单通知
  Future<bool> sendSimpleNotification({
    required String text,
    RgbColor color = RgbColor.colorWhite,
    VibrationPattern vibration = VibrationPattern.short,
    VibrationIntensity intensity = VibrationIntensity.medium,
  }) async {
    final message = BleProtocolUtils.createSimpleNotification(
      text: text,
      color: color,
      vibration: vibration,
      intensity: intensity,
    );
    return sendMessage(message);
  }

  /// 发送彩虹灯效果
  Future<bool> sendRainbowEffect({
    required String text,
    VibrationPattern vibration = VibrationPattern.medium,
    VibrationIntensity intensity = VibrationIntensity.medium,
  }) async {
    final message = BleProtocolUtils.createRainbowEffect(
      text: text,
      vibration: vibration,
      intensity: intensity,
    );
    return sendMessage(message);
  }

  /// 发送紧急通知
  Future<bool> sendUrgentNotification(String text) async {
    final message = BleProtocolUtils.createUrgentNotification(text: text);
    return sendMessage(message);
  }

  /// 发送RGB灯光序列
  Future<bool> sendRgbSequence({
    required List<RgbColor> colors,
    required String text,
    VibrationPattern vibration = VibrationPattern.short,
    VibrationIntensity intensity = VibrationIntensity.medium,
    int duration = 3000,
  }) async {
    final message = DeviceMessagePacket.notification(
      rgbColors: colors,
      vibrationPattern: vibration,
      vibrationIntensity: intensity,
      text: text,
      duration: duration,
    );
    return sendMessage(message);
  }

  /// 获取设备状态
  Future<Map<String, dynamic>?> getDeviceStatus() async {
    if (!isConnected) return null;

    try {
      // 这里可以实现获取设备状态的逻辑
      // 例如读取状态特征值
      if (_statusCharacteristic != null) {
        final statusData = await _statusCharacteristic!.read();
        // 解析状态数据
        return _parseDeviceStatus(statusData);
      }
      return null;
    } catch (e) {
      Logger.error('获取设备状态失败: $e');
      return null;
    }
  }

  /// 解析设备状态数据
  Map<String, dynamic> _parseDeviceStatus(List<int> statusData) {
    // 这里根据实际协议解析状态数据
    return {
      'batteryLevel': 85, // 模拟电池电量
      'isCharging': false,
      'temperature': 25,
      'lastSyncTime': DateTime.now().toIso8601String(),
    };
  }

  /// 获取设备电池电量
  Future<int?> getBatteryLevel() async {
    final status = await getDeviceStatus();
    return status?['batteryLevel'] as int?;
  }

  /// 重置设备状态
  Future<bool> resetDevice() async {
    if (!isConnected) return false;

    try {
      // 发送重置命令
      final resetMessage = DeviceMessagePacket(
        commandType: BleCommandType.deviceStatus,
        sequenceNumber: DateTime.now().millisecondsSinceEpoch & 0xFFFF,
        rgbColors: [],
        text: 'RESET',
        duration: 1000,
      );

      return await sendMessage(resetMessage);
    } catch (e) {
      Logger.error('重置设备失败: $e');
      return false;
    }
  }
}

/// 设备控制异常
class DeviceControlException implements Exception {
  final String message;
  final String? deviceId;

  const DeviceControlException(this.message, [this.deviceId]);

  @override
  String toString() {
    return 'DeviceControlException: $message${deviceId != null ? ' (设备: $deviceId)' : ''}';
  }
}
