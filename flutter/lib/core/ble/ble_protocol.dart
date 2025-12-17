/// 蓝牙通信协议定义
/// 用于与手环设备进行BLE通信的协议规范
library;

import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// 协议版本号
const int PROTOCOL_VERSION = 0x01;

/// 服务UUID定义
class BleServiceUuids {
  static const String deviceControlService =
      "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String deviceInfoService =
      "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";
}

/// 特征值UUID定义
class BleCharacteristicUuids {
  static const String commandCharacteristic =
      "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String statusCharacteristic =
      "6E400004-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String deviceInfoCharacteristic =
      "6E400005-B5A3-F393-E0A9-E50E24DCCA9E";
}

/// 命令类型定义
enum BleCommandType {
  notification(0x01), // 通知消息
  rgbControl(0x02), // RGB灯光控制
  vibrationControl(0x03), // 震动控制
  textDisplay(0x04), // 文本显示
  deviceStatus(0x05), // 设备状态查询
  batteryLevel(0x06) // 电池电量查询
  ;

  final int value;
  const BleCommandType(this.value);
}

/// RGB颜色定义
class RgbColor {
  final int red;
  final int green;
  final int blue;

  const RgbColor({required this.red, required this.green, required this.blue});

  /// 从十六进制颜色值创建
  factory RgbColor.fromHex(int hexColor) {
    return RgbColor(
      red: (hexColor >> 16) & 0xFF,
      green: (hexColor >> 8) & 0xFF,
      blue: hexColor & 0xFF,
    );
  }

  /// 转换为字节数组
  List<int> toBytes() => [red, green, blue];

  /// 预定义颜色
  static const RgbColor colorRed = RgbColor(red: 255, green: 0, blue: 0);
  static const RgbColor colorGreen = RgbColor(red: 0, green: 255, blue: 0);
  static const RgbColor colorBlue = RgbColor(red: 0, green: 0, blue: 255);
  static const RgbColor colorYellow = RgbColor(red: 255, green: 255, blue: 0);
  static const RgbColor colorPurple = RgbColor(red: 128, green: 0, blue: 128);
  static const RgbColor colorCyan = RgbColor(red: 0, green: 255, blue: 255);
  static const RgbColor colorWhite = RgbColor(red: 255, green: 255, blue: 255);
  static const RgbColor colorBlack = RgbColor(red: 0, green: 0, blue: 0);
}

/// 震动模式定义
enum VibrationPattern {
  none(0x00), // 无震动
  short(0x01), // 短震动
  medium(0x02), // 中等震动
  long(0x03), // 长震动
  double(0x04), // 双震动
  triple(0x05), // 三震动
  custom(0x06) // 自定义震动
  ;

  final int value;
  const VibrationPattern(this.value);
}

/// 震动强度定义
enum VibrationIntensity {
  low(0x01), // 低强度
  medium(0x02), // 中等强度
  high(0x03) // 高强度
  ;

  final int value;
  const VibrationIntensity(this.value);
}

/// 手环设备消息数据包
@immutable
class DeviceMessagePacket {
  final int protocolVersion;
  final BleCommandType commandType;
  final int sequenceNumber;
  final List<RgbColor> rgbColors;
  final VibrationPattern vibrationPattern;
  final VibrationIntensity vibrationIntensity;
  final String text;
  final int duration; // 持续时间（毫秒）

  const DeviceMessagePacket({
    this.protocolVersion = PROTOCOL_VERSION,
    required this.commandType,
    required this.sequenceNumber,
    required this.rgbColors,
    this.vibrationPattern = VibrationPattern.short,
    this.vibrationIntensity = VibrationIntensity.medium,
    this.text = '',
    this.duration = 3000, // 默认3秒
  });

  /// 创建通知消息数据包
  factory DeviceMessagePacket.notification({
    required List<RgbColor> rgbColors,
    required VibrationPattern vibrationPattern,
    required VibrationIntensity vibrationIntensity,
    required String text,
    int duration = 3000,
  }) {
    return DeviceMessagePacket(
      commandType: BleCommandType.notification,
      sequenceNumber: _generateSequenceNumber(),
      rgbColors: rgbColors,
      vibrationPattern: vibrationPattern,
      vibrationIntensity: vibrationIntensity,
      text: text,
      duration: duration,
    );
  }

  /// 序列化为字节数组
  List<int> toBytes() {
    final buffer = BytesBuilder();

    // 协议头 (4字节)
    buffer.addByte(protocolVersion); // 协议版本 (1字节)
    buffer.addByte(commandType.value); // 命令类型 (1字节)
    buffer.addByte(sequenceNumber & 0xFF); // 序列号低8位 (1字节)
    buffer.addByte((sequenceNumber >> 8) & 0xFF); // 序列号高8位 (1字节)

    // RGB颜色序列 (3 * n 字节)
    buffer.addByte(rgbColors.length); // 颜色数量 (1字节)
    for (final color in rgbColors) {
      for (final byte in color.toBytes()) {
        buffer.addByte(byte);
      }
    }

    // 震动控制 (2字节)
    buffer.addByte(vibrationPattern.value); // 震动模式 (1字节)
    buffer.addByte(vibrationIntensity.value); // 震动强度 (1字节)

    // 文本信息 (最大64字节)
    final textBytes = _encodeText(text);
    buffer.addByte(textBytes.length); // 文本长度 (1字节)
    for (final byte in textBytes) {
      buffer.addByte(byte);
    }

    // 持续时间 (2字节，毫秒)
    buffer.addByte(duration & 0xFF); // 持续时间低8位
    buffer.addByte((duration >> 8) & 0xFF); // 持续时间高8位

    // 校验和 (1字节)
    final bytes = buffer.toBytes();
    final checksum = _calculateChecksum(bytes);
    buffer.addByte(checksum);

    return buffer.toBytes();
  }

  /// 从字节数组反序列化
  factory DeviceMessagePacket.fromBytes(List<int> bytes) {
    if (bytes.length < 12) {
      throw const FormatException('数据包长度不足');
    }

    int offset = 0;

    // 协议头
    final protocolVersion = bytes[offset++];
    final commandType = BleCommandType.values.firstWhere(
      (e) => e.value == bytes[offset++],
    );
    final sequenceNumber = bytes[offset++] | (bytes[offset++] << 8);

    // RGB颜色序列
    final colorCount = bytes[offset++];
    final rgbColors = <RgbColor>[];
    for (int i = 0; i < colorCount; i++) {
      rgbColors.add(
        RgbColor(
          red: bytes[offset++],
          green: bytes[offset++],
          blue: bytes[offset++],
        ),
      );
    }

    // 震动控制
    final vibrationPattern = VibrationPattern.values.firstWhere(
      (e) => e.value == bytes[offset++],
    );
    final vibrationIntensity = VibrationIntensity.values.firstWhere(
      (e) => e.value == bytes[offset++],
    );

    // 文本信息
    final textLength = bytes[offset++];
    final textBytes = bytes.sublist(offset, offset + textLength);
    offset += textLength;
    final text = _decodeText(textBytes);

    // 持续时间
    final duration = bytes[offset++] | (bytes[offset++] << 8);

    // 校验和验证
    final expectedChecksum = bytes[offset];
    final actualChecksum = _calculateChecksum(bytes.sublist(0, offset));
    if (expectedChecksum != actualChecksum) {
      throw const FormatException('校验和不匹配');
    }

    return DeviceMessagePacket(
      protocolVersion: protocolVersion,
      commandType: commandType,
      sequenceNumber: sequenceNumber,
      rgbColors: rgbColors,
      vibrationPattern: vibrationPattern,
      vibrationIntensity: vibrationIntensity,
      text: text,
      duration: duration,
    );
  }

  /// 编码文本（UTF-8，最大64字节）
  static List<int> _encodeText(String text) {
    final encoded = text.codeUnits.take(64).toList();
    return encoded.length <= 64 ? encoded : encoded.sublist(0, 64);
  }

  /// 解码文本
  static String _decodeText(List<int> bytes) {
    return String.fromCharCodes(bytes);
  }

  /// 计算校验和
  static int _calculateChecksum(List<int> bytes) {
    int sum = 0;
    for (final byte in bytes) {
      sum += byte;
    }
    return sum & 0xFF;
  }

  /// 生成序列号
  static int _generateSequenceNumber() {
    return DateTime.now().millisecondsSinceEpoch & 0xFFFF;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceMessagePacket &&
        other.protocolVersion == protocolVersion &&
        other.commandType == commandType &&
        other.sequenceNumber == sequenceNumber &&
        listEquals(other.rgbColors, rgbColors) &&
        other.vibrationPattern == vibrationPattern &&
        other.vibrationIntensity == vibrationIntensity &&
        other.text == text &&
        other.duration == duration;
  }

  @override
  int get hashCode {
    return Object.hash(
      protocolVersion,
      commandType,
      sequenceNumber,
      rgbColors,
      vibrationPattern,
      vibrationIntensity,
      text,
      duration,
    );
  }

  @override
  String toString() {
    return 'DeviceMessagePacket('
        'protocolVersion: $protocolVersion, '
        'commandType: $commandType, '
        'sequenceNumber: $sequenceNumber, '
        'rgbColors: $rgbColors, '
        'vibrationPattern: $vibrationPattern, '
        'vibrationIntensity: $vibrationIntensity, '
        'text: "$text", '
        'duration: ${duration}ms'
        ')';
  }
}

/// 协议工具类
class BleProtocolUtils {
  /// 创建简单的通知消息
  static DeviceMessagePacket createSimpleNotification({
    required String text,
    RgbColor color = RgbColor.colorWhite,
    VibrationPattern vibration = VibrationPattern.short,
    VibrationIntensity intensity = VibrationIntensity.medium,
  }) {
    return DeviceMessagePacket.notification(
      rgbColors: [color],
      vibrationPattern: vibration,
      vibrationIntensity: intensity,
      text: text,
    );
  }

  /// 创建彩虹灯效果
  static DeviceMessagePacket createRainbowEffect({
    required String text,
    VibrationPattern vibration = VibrationPattern.medium,
    VibrationIntensity intensity = VibrationIntensity.medium,
  }) {
    return DeviceMessagePacket.notification(
      rgbColors: [
        RgbColor.colorRed,
        RgbColor.colorGreen,
        RgbColor.colorBlue,
        RgbColor.colorYellow,
        RgbColor.colorPurple,
        RgbColor.colorCyan,
      ],
      vibrationPattern: vibration,
      vibrationIntensity: intensity,
      text: text,
    );
  }

  /// 创建紧急通知
  static DeviceMessagePacket createUrgentNotification({required String text}) {
    return DeviceMessagePacket.notification(
      rgbColors: [RgbColor.colorRed, RgbColor.colorRed, RgbColor.colorRed],
      vibrationPattern: VibrationPattern.triple,
      vibrationIntensity: VibrationIntensity.high,
      text: text,
      duration: 5000,
    );
  }
}
