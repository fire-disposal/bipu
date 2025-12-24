/// BLE数据模型
library;

/// BLE服务UUID常量
class BleServiceUuids {
  static const String deviceControlService =
      '00001800-0000-1000-8000-00805f9b34fb';
}

/// BLE特征值UUID常量
class BleCharacteristicUuids {
  static const String commandCharacteristic =
      '00002a00-0000-1000-8000-00805f9b34fb';
  static const String statusCharacteristic =
      '00002a01-0000-1000-8000-00805f9b34fb';
}

/// RGB颜色
class RgbColor {
  final int red;
  final int green;
  final int blue;

  const RgbColor(this.red, this.green, this.blue);

  static const RgbColor colorRed = RgbColor(255, 0, 0);
  static const RgbColor colorGreen = RgbColor(0, 255, 0);
  static const RgbColor colorBlue = RgbColor(0, 0, 255);
  static const RgbColor colorWhite = RgbColor(255, 255, 255);
  static const RgbColor colorBlack = RgbColor(0, 0, 0);
  static const RgbColor colorYellow = RgbColor(255, 255, 0);
  static const RgbColor colorPurple = RgbColor(255, 0, 255);
  static const RgbColor colorCyan = RgbColor(0, 255, 255);

  /// 转换为字节数组
  List<int> toBytes() {
    return [red, green, blue];
  }

  @override
  String toString() => 'RgbColor($red, $green, $blue)';
}

/// 振动模式
enum VibrationPattern { none, short, medium, long, double, triple }

/// 振动强度
enum VibrationIntensity { low, medium, high, maximum }

/// BLE命令类型
enum BleCommandType {
  deviceStatus,
  notification,
  rainbowEffect,
  rgbSequence,
  reset,
}

/// 设备消息包
class DeviceMessagePacket {
  final BleCommandType commandType;
  final int sequenceNumber;
  final List<RgbColor> rgbColors;
  final String text;
  final int duration;
  final VibrationPattern vibrationPattern;
  final VibrationIntensity vibrationIntensity;

  const DeviceMessagePacket({
    required this.commandType,
    required this.sequenceNumber,
    this.rgbColors = const [],
    this.text = '',
    this.duration = 1000,
    this.vibrationPattern = VibrationPattern.none,
    this.vibrationIntensity = VibrationIntensity.medium,
  });

  /// 创建通知消息
  factory DeviceMessagePacket.notification({
    required List<RgbColor> rgbColors,
    required String text,
    VibrationPattern vibrationPattern = VibrationPattern.short,
    VibrationIntensity vibrationIntensity = VibrationIntensity.medium,
    int duration = 3000,
    int? sequenceNumber,
  }) {
    return DeviceMessagePacket(
      commandType: BleCommandType.notification,
      sequenceNumber:
          sequenceNumber ?? DateTime.now().millisecondsSinceEpoch & 0xFFFF,
      rgbColors: rgbColors,
      text: text,
      duration: duration,
      vibrationPattern: vibrationPattern,
      vibrationIntensity: vibrationIntensity,
    );
  }

  /// 转换为字节数组
  List<int> toBytes() {
    final bytes = <int>[];

    // 命令类型 (1字节)
    bytes.add(commandType.index);

    // 序列号 (2字节)
    bytes.add(sequenceNumber >> 8);
    bytes.add(sequenceNumber & 0xFF);

    // RGB颜色数量 (1字节)
    bytes.add(rgbColors.length);

    // RGB颜色数据 (每个颜色3字节)
    for (final color in rgbColors) {
      bytes.addAll(color.toBytes());
    }

    // 文本长度 (1字节)
    final textBytes = text.codeUnits;
    bytes.add(textBytes.length);

    // 文本数据
    bytes.addAll(textBytes);

    // 持续时间 (2字节，毫秒)
    bytes.add(duration >> 8);
    bytes.add(duration & 0xFF);

    // 振动模式 (1字节)
    bytes.add(vibrationPattern.index);

    // 振动强度 (1字节)
    bytes.add(vibrationIntensity.index);

    return bytes;
  }

  @override
  String toString() {
    return 'DeviceMessagePacket{commandType: $commandType, '
        'sequenceNumber: $sequenceNumber, rgbColors: $rgbColors, '
        'text: $text, duration: $duration, '
        'vibrationPattern: $vibrationPattern, '
        'vibrationIntensity: $vibrationIntensity}';
  }
}

/// 设备状态
class DeviceStatus {
  final int batteryLevel;
  final bool isCharging;
  final double temperature;
  final DateTime lastSyncTime;
  final bool isConnected;

  const DeviceStatus({
    required this.batteryLevel,
    required this.isCharging,
    required this.temperature,
    required this.lastSyncTime,
    this.isConnected = true,
  });

  /// 从字节数组解析设备状态
  factory DeviceStatus.fromBytes(List<int> bytes) {
    if (bytes.length < 8) {
      throw const FormatException('Invalid device status data');
    }

    return DeviceStatus(
      batteryLevel: bytes[0],
      isCharging: bytes[1] == 1,
      temperature: (bytes[2] << 8 | bytes[3]) / 10.0,
      lastSyncTime: DateTime.now(),
      isConnected: true,
    );
  }

  @override
  String toString() {
    return 'DeviceStatus{batteryLevel: $batteryLevel%, '
        'isCharging: $isCharging, temperature: ${temperature}°C, '
        'lastSyncTime: $lastSyncTime, isConnected: $isConnected}';
  }
}
