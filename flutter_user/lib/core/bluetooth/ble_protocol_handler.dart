import 'dart:typed_data';
import '../constants/ble_constants.dart';
import '../protocol/ble_protocol.dart';

/// BLE协议处理器
class BleProtocolHandler {
  /// 创建时间同步数据包
  static List<int> createTimeSyncPacket(DateTime time) {
    final packet = BytesBuilder();
    packet.addByte(BleConstants.cmdTimeSync); // 时间同步命令
    packet.addByte(time.hour);
    packet.addByte(time.minute);
    packet.addByte(time.second);
    packet.addByte(time.weekday - 1); // 0-6 (周一到周日)

    // 计算校验和
    final bytes = packet.toBytes();
    int checksum = 0;
    for (final byte in bytes) {
      checksum += byte.toInt();
    }
    packet.addByte(checksum & 0xFF);

    return packet.toBytes();
  }

  /// 创建消息数据包
  static List<int> createMessagePacket({
    List<ColorData> colors = const [],
    VibrationType vibration = VibrationType.none,
    ScreenEffect screenEffect = ScreenEffect.none,
    String text = '',
  }) {
    return BleProtocol.createPacket(
      colors: colors,
      vibration: vibration,
      screenEffect: screenEffect,
      text: text,
    );
  }

  /// 验证数据包完整性
  static bool validatePacket(List<int> data) {
    if (data.isEmpty) return false;

    // 计算校验和
    int calculatedChecksum = 0;
    for (int i = 0; i < data.length - 1; i++) {
      calculatedChecksum += data[i];
    }

    return (calculatedChecksum & 0xFF) == data.last;
  }

  /// 解析错误响应
  static String parseErrorResponse(List<int> data) {
    if (data.length < 2 || data[0] != BleConstants.cmdErrorResponse) {
      return 'Unknown error';
    }

    final errorCode = data[1];
    switch (errorCode) {
      case 0x01:
        return 'Invalid packet length';
      case 0x02:
        return 'Invalid checksum';
      case 0x03:
        return 'Unknown command';
      case 0x04:
        return 'Invalid data';
      case 0x05:
        return 'Invalid time';
      default:
        return 'Error code: $errorCode';
    }
  }
}
