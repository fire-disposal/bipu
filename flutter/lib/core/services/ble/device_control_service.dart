/// 设备控制服务
library;

import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as blue_plus;
import '../../utils/logger.dart';
import 'ble_models.dart';
import 'ble_exceptions.dart';
import 'ble_service.dart';
import 'ble_protocol.dart';

/// 设备控制服务
class DeviceControlService {
  // Singleton
  static final DeviceControlService _instance =
      DeviceControlService._internal();
  factory DeviceControlService() => _instance;
  DeviceControlService._internal();

  final BleService _bleService = BleService();
  blue_plus.BluetoothDevice? _connectedDevice;
  blue_plus.BluetoothCharacteristic? _commandCharacteristic;
  blue_plus.BluetoothCharacteristic? _statusCharacteristic;
  bool _isInitialized = false;

  /// 初始化设备控制服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 确保蓝牙服务已初始化
      if (!_bleService.isInitialized) {
        await _bleService.initialize();
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

      // 连接设备
      await _bleService.connectToDevice(deviceId);

      // 创建设备对象
      final device = blue_plus.BluetoothDevice.fromId(deviceId);

      // 发现服务
      final services = await device.discoverServices();

      // 查找设备控制服务
      final controlService = services.firstWhere(
        (service) => service.uuid.str == BleServiceUuids.deviceControlService,
        orElse: () => throw ServiceNotFoundException(deviceId),
      );

      // 查找特征值
      _commandCharacteristic = controlService.characteristics.firstWhere(
        (char) => char.uuid.str == BleCharacteristicUuids.commandCharacteristic,
        orElse: () => throw CharacteristicNotFoundException(deviceId, '命令'),
      );

      _statusCharacteristic = controlService.characteristics.firstWhere(
        (char) => char.uuid.str == BleCharacteristicUuids.statusCharacteristic,
        orElse: () => throw CharacteristicNotFoundException(deviceId, '状态'),
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

  void _handleDisconnection() {
    _connectedDevice = null;
    _commandCharacteristic = null;
    _statusCharacteristic = null;
  }

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
      if (!BleProtocolUtils.isValidMessageSize(messageBytes)) {
        Logger.warning('消息过大，无法发送');
        return false;
      }

      // 分块发送
      final chunks = BleProtocolUtils.chunkMessage(messageBytes, 20);
      for (final chunk in chunks) {
        await _commandCharacteristic!.write(chunk);
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
    final message = BleProtocolUtils.createUrgentNotification(text);
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
    final message = BleProtocolUtils.createRgbSequence(
      colors: colors,
      text: text,
      vibration: vibration,
      intensity: intensity,
      duration: duration,
    );
    return sendMessage(message);
  }

  /// 获取设备状态
  Future<DeviceStatus?> getDeviceStatus() async {
    if (!isConnected) return null;

    try {
      if (_statusCharacteristic != null) {
        final statusData = await _statusCharacteristic!.read();
        return BleProtocolUtils.parseStatusResponse(statusData);
      }
      return null;
    } catch (e) {
      Logger.error('获取设备状态失败: $e');
      return null;
    }
  }

  /// 获取设备电池电量
  Future<int?> getBatteryLevel() async {
    final status = await getDeviceStatus();
    return status?.batteryLevel;
  }

  /// 重置设备状态
  Future<bool> resetDevice() async {
    if (!isConnected) return false;

    try {
      final resetMessage = BleProtocolUtils.createResetCommand();
      return await sendMessage(resetMessage);
    } catch (e) {
      Logger.error('重置设备失败: $e');
      return false;
    }
  }

  /// 检查是否已连接设备
  bool get isConnected =>
      _connectedDevice != null && _commandCharacteristic != null;

  /// 获取当前连接的设备ID
  String? get connectedDeviceId => _connectedDevice?.remoteId.str;
}
