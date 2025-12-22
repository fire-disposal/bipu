/// 设备控制状态管理
/// 管理手环设备控制相关的状态
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bipupu_flutter/core/ble/ble_protocol.dart';
import 'package:bipupu_flutter/core/ble/device_control_service.dart';
import 'package:bipupu_flutter/core/core.dart';

/// 设备控制状态
abstract class DeviceControlState extends BaseState {
  const DeviceControlState();
}

/// 初始状态
class DeviceControlInitial extends DeviceControlState {
  const DeviceControlInitial();
}

/// 设备连接中
class DeviceConnecting extends DeviceControlState {
  const DeviceConnecting();
}

/// 设备已连接
class DeviceConnected extends DeviceControlState {
  final String deviceId;
  final String deviceName;
  final Map<String, dynamic>? deviceInfo;

  const DeviceConnected({
    required this.deviceId,
    required this.deviceName,
    this.deviceInfo,
  });

  @override
  List<Object?> get props => [deviceId, deviceName, deviceInfo];
}

/// 设备断开连接
class DeviceDisconnected extends DeviceControlState {
  const DeviceDisconnected();
}

/// 消息发送中
class MessageSending extends DeviceControlState {
  const MessageSending();
}

/// 消息发送成功
class MessageSent extends DeviceControlState {
  final DeviceMessagePacket message;

  const MessageSent(this.message);

  @override
  List<Object?> get props => [message];
}

/// 设备控制Cubit
class DeviceControlCubit extends Cubit<DeviceControlState> {
  final DeviceControlService _deviceControlService;

  DeviceControlCubit({DeviceControlService? deviceControlService})
    : _deviceControlService =
          deviceControlService ?? getIt<DeviceControlService>(),
      super(const DeviceControlInitial());

  /// 连接到设备
  Future<void> connectToDevice(String deviceId, String deviceName) async {
    emit(const DeviceConnecting());

    try {
      await _deviceControlService.initialize();
      final success = await _deviceControlService.connectToDevice(deviceId);

      if (success) {
        final deviceInfo = await _deviceControlService.getDeviceStatus();
        emit(
          DeviceConnected(
            deviceId: deviceId,
            deviceName: deviceName,
            deviceInfo: deviceInfo,
          ),
        );
      } else {
        emit(const DeviceDisconnected());
      }
    } catch (e) {
      emit(const DeviceDisconnected());
    }
  }

  /// 断开设备连接
  Future<void> disconnectDevice() async {
    await _deviceControlService.disconnect();
    emit(const DeviceDisconnected());
  }

  /// 发送简单通知
  Future<void> sendSimpleNotification({
    required String text,
    RgbColor color = RgbColor.colorWhite,
    VibrationPattern vibration = VibrationPattern.short,
    VibrationIntensity intensity = VibrationIntensity.medium,
  }) async {
    if (state is! DeviceConnected) return;

    emit(const MessageSending());

    try {
      final success = await _deviceControlService.sendSimpleNotification(
        text: text,
        color: color,
        vibration: vibration,
        intensity: intensity,
      );

      if (success) {
        final message = DeviceMessagePacket.notification(
          rgbColors: [color],
          vibrationPattern: vibration,
          vibrationIntensity: intensity,
          text: text,
        );
        emit(MessageSent(message));
        // 回到连接状态
        await Future.delayed(const Duration(seconds: 2));
        emit(state);
      }
    } catch (e) {
      // 保持当前状态
      emit(state);
    }
  }

  /// 发送RGB序列
  Future<void> sendRgbSequence({
    required List<RgbColor> colors,
    required String text,
    VibrationPattern vibration = VibrationPattern.short,
    VibrationIntensity intensity = VibrationIntensity.medium,
    int duration = 3000,
  }) async {
    if (state is! DeviceConnected) return;

    emit(const MessageSending());

    try {
      final success = await _deviceControlService.sendRgbSequence(
        colors: colors,
        text: text,
        vibration: vibration,
        intensity: intensity,
        duration: duration,
      );

      if (success) {
        final message = DeviceMessagePacket.notification(
          rgbColors: colors,
          vibrationPattern: vibration,
          vibrationIntensity: intensity,
          text: text,
          duration: duration,
        );
        emit(MessageSent(message));
        // 回到连接状态
        await Future.delayed(const Duration(seconds: 2));
        emit(state);
      }
    } catch (e) {
      // 保持当前状态
      emit(state);
    }
  }

  /// 发送紧急通知
  Future<void> sendUrgentNotification(String text) async {
    if (state is! DeviceConnected) return;

    emit(const MessageSending());

    try {
      final success = await _deviceControlService.sendUrgentNotification(text);

      if (success) {
        final message = BleProtocolUtils.createUrgentNotification(text: text);
        emit(MessageSent(message));
        // 回到连接状态
        await Future.delayed(const Duration(seconds: 2));
        emit(state);
      }
    } catch (e) {
      // 保持当前状态
      emit(state);
    }
  }

  /// 获取设备电池电量
  Future<int?> getBatteryLevel() async {
    if (state is! DeviceConnected) return null;
    return await _deviceControlService.getBatteryLevel();
  }

  /// 重置设备
  Future<void> resetDevice() async {
    if (state is! DeviceConnected) return;
    await _deviceControlService.resetDevice();
  }

  /// 检查是否已连接
  bool get isConnected => state is DeviceConnected;

  /// 获取当前连接的设备ID
  String? get connectedDeviceId {
    if (state is DeviceConnected) {
      return (state as DeviceConnected).deviceId;
    }
    return null;
  }

  /// 获取当前连接的设备名称
  String? get connectedDeviceName {
    if (state is DeviceConnected) {
      return (state as DeviceConnected).deviceName;
    }
    return null;
  }
}
