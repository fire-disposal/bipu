/// BLE服务
library;

import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as blue_plus;
import '../../utils/logger.dart';
import 'ble_exceptions.dart';

/// BLE服务
class BleService {
  // Singleton pattern
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  bool _initialized = false;

  /// 初始化蓝牙服务
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 检查当前平台是否支持蓝牙
      if (!await isBluetoothSupported()) {
        Logger.warning('当前平台不支持蓝牙功能');
        _initialized = true;
        return;
      }

      // 检查蓝牙是否可用
      final isSupported = await blue_plus.FlutterBluePlus.isSupported;
      if (!isSupported) {
        Logger.warning('设备不支持蓝牙');
        _initialized = true;
        return;
      }

      // 检查蓝牙是否开启
      final adapterState = await blue_plus.FlutterBluePlus.adapterState.first;
      if (adapterState != blue_plus.BluetoothAdapterState.on) {
        // 尝试开启蓝牙
        await blue_plus.FlutterBluePlus.turnOn();
      }

      _initialized = true;
      Logger.info('蓝牙服务初始化完成');
    } catch (e) {
      Logger.error('蓝牙服务初始化失败: $e');
      // 在非移动平台上，蓝牙初始化失败是预期的，不抛出异常
      if (await _isMobilePlatform()) {
        rethrow;
      } else {
        Logger.info('在非移动平台上跳过蓝牙初始化');
        _initialized = true;
      }
    }
  }

  /// 检查是否支持蓝牙
  Future<bool> isBluetoothSupported() async {
    try {
      // 尝试访问FlutterBluePlus，如果抛出UnsupportedError则说明不支持
      await blue_plus.FlutterBluePlus.isSupported;
      return true;
    } catch (e) {
      if (e is UnsupportedError) {
        return false;
      }
      // 其他错误也视为不支持
      return false;
    }
  }

  Future<bool> _isMobilePlatform() async {
    // 这里可以根据需要添加更详细的平台检测逻辑
    // 目前简化为：如果isSupported不抛出UnsupportedError，则认为是移动平台
    try {
      await blue_plus.FlutterBluePlus.isSupported;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 开始扫描设备
  Future<void> startScan() async {
    if (!_initialized) {
      throw const BluetoothNotEnabledException();
    }

    try {
      await blue_plus.FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
      );
      Logger.info('开始扫描蓝牙设备');
    } catch (e) {
      Logger.error('扫描设备失败: $e');
      rethrow;
    }
  }

  /// 停止扫描
  Future<void> stopScan() async {
    try {
      await blue_plus.FlutterBluePlus.stopScan();
      Logger.info('停止扫描蓝牙设备');
    } catch (e) {
      Logger.error('停止扫描失败: $e');
      rethrow;
    }
  }

  /// 连接设备
  Future<void> connectToDevice(String deviceId) async {
    try {
      Logger.info('开始连接设备: $deviceId');

      // 创建设备对象
      final device = blue_plus.BluetoothDevice.fromId(deviceId);

      // 检查当前连接状态
      if (device.isConnected) {
        Logger.info('设备已在连接状态: $deviceId');
        return;
      }

      // 连接设备
      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
        license: blue_plus.License.free,
      );

      Logger.info('设备连接成功: $deviceId');
    } catch (e) {
      Logger.error('设备连接失败: $e');
      throw DeviceConnectionException(deviceId, '设备连接失败: $e');
    }
  }

  /// 断开设备连接
  Future<void> disconnectDevice(String deviceId) async {
    try {
      final device = blue_plus.FlutterBluePlus.connectedDevices.firstWhere(
        (device) => device.remoteId.str == deviceId,
        orElse: () => throw DeviceNotFoundException(deviceId),
      );

      await device.disconnect();
      Logger.info('设备断开连接: $deviceId');
    } catch (e) {
      if (e is DeviceNotFoundException) {
        rethrow;
      }
      Logger.error('设备断开连接失败: $e');
      throw DeviceConnectionException(deviceId, '设备断开连接失败: $e');
    }
  }

  /// 获取已连接的设备
  List<blue_plus.BluetoothDevice> getConnectedDevices() {
    return blue_plus.FlutterBluePlus.connectedDevices;
  }

  /// 获取扫描结果
  Stream<List<blue_plus.ScanResult>> get scanResults {
    return blue_plus.FlutterBluePlus.scanResults;
  }

  /// 检查是否已初始化
  bool get isInitialized => _initialized;
}
