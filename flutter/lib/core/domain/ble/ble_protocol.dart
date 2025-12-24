/// BLE协议工具类
library;

import 'ble_models.dart';

/// BLE协议工具类
class BleProtocolUtils {
  /// 创建简单通知
  static DeviceMessagePacket createSimpleNotification({
    required String text,
    RgbColor color = RgbColor.colorWhite,
    VibrationPattern vibration = VibrationPattern.short,
    VibrationIntensity intensity = VibrationIntensity.medium,
  }) {
    return DeviceMessagePacket.notification(
      rgbColors: [color],
      text: text,
      vibrationPattern: vibration,
      vibrationIntensity: intensity,
      duration: 2000,
    );
  }

  /// 创建彩虹灯效果
  static DeviceMessagePacket createRainbowEffect({
    required String text,
    VibrationPattern vibration = VibrationPattern.medium,
    VibrationIntensity intensity = VibrationIntensity.medium,
  }) {
    final rainbowColors = [
      RgbColor.colorRed,
      RgbColor.colorYellow,
      RgbColor.colorGreen,
      RgbColor.colorCyan,
      RgbColor.colorBlue,
      RgbColor.colorPurple,
    ];

    return DeviceMessagePacket.notification(
      rgbColors: rainbowColors,
      text: text,
      vibrationPattern: vibration,
      vibrationIntensity: intensity,
      duration: 5000,
    );
  }

  /// 创建紧急通知
  static DeviceMessagePacket createUrgentNotification(String text) {
    return DeviceMessagePacket.notification(
      rgbColors: [RgbColor.colorRed],
      text: text,
      vibrationPattern: VibrationPattern.triple,
      vibrationIntensity: VibrationIntensity.maximum,
      duration: 3000,
    );
  }

  /// 创建RGB序列
  static DeviceMessagePacket createRgbSequence({
    required List<RgbColor> colors,
    required String text,
    VibrationPattern vibration = VibrationPattern.short,
    VibrationIntensity intensity = VibrationIntensity.medium,
    int duration = 3000,
  }) {
    return DeviceMessagePacket.notification(
      rgbColors: colors,
      text: text,
      vibrationPattern: vibration,
      vibrationIntensity: intensity,
      duration: duration,
    );
  }

  /// 创建设备状态查询命令
  static DeviceMessagePacket createStatusQuery() {
    return DeviceMessagePacket(
      commandType: BleCommandType.deviceStatus,
      sequenceNumber: DateTime.now().millisecondsSinceEpoch & 0xFFFF,
      text: 'STATUS',
      duration: 1000,
    );
  }

  /// 创建设备重置命令
  static DeviceMessagePacket createResetCommand() {
    return DeviceMessagePacket(
      commandType: BleCommandType.reset,
      sequenceNumber: DateTime.now().millisecondsSinceEpoch & 0xFFFF,
      text: 'RESET',
      duration: 1000,
    );
  }

  /// 解析设备状态响应
  static DeviceStatus? parseStatusResponse(List<int> data) {
    try {
      if (data.length < 8) {
        return null;
      }

      return DeviceStatus.fromBytes(data);
    } catch (e) {
      return null;
    }
  }

  /// 验证消息大小
  static bool isValidMessageSize(List<int> messageBytes) {
    return messageBytes.length <= 512;
  }

  /// 分块消息
  static List<List<int>> chunkMessage(List<int> messageBytes, int chunkSize) {
    if (!isValidMessageSize(messageBytes)) {
      throw ArgumentError('Message too large');
    }

    final chunks = <List<int>>[];
    for (int i = 0; i < messageBytes.length; i += chunkSize) {
      final end = (i + chunkSize < messageBytes.length)
          ? i + chunkSize
          : messageBytes.length;
      chunks.add(messageBytes.sublist(i, end));
    }
    return chunks;
  }

  /// 计算校验和
  static int calculateChecksum(List<int> data) {
    int sum = 0;
    for (final byte in data) {
      sum += byte;
    }
    return sum & 0xFF;
  }

  /// 验证校验和
  static bool verifyChecksum(List<int> data, int expectedChecksum) {
    return calculateChecksum(data) == expectedChecksum;
  }
}
