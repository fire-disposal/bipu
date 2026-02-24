/// Bipupu 简单高效的蓝牙协议
///
/// 设计原则：
/// 1. 尽可能简单
/// 2. 不需要电量回报
/// 3. 发送人需要和消息内容分开
///
/// 协议格式（二进制）：
/// [协议版本:1字节][消息类型:1字节][发送人ID长度:1字节][发送人ID...][消息内容...]
///
/// 消息类型定义：
/// 0x01: 时间同步（手机 -> 设备）
/// 0x02: 文本消息（手机 -> 设备）
/// 0x03: 确认响应（设备 -> 手机）
///
/// 时间同步格式：
/// [协议版本:1字节][消息类型:1字节=0x01][Unix时间戳:4字节]
///
/// 文本消息格式：
/// [协议版本:1字节][消息类型:1字节=0x02][发送人ID长度:1字节][发送人ID...][消息内容...]
///
/// 确认响应格式：
/// [协议版本:1字节][消息类型:1字节=0x03][原始消息类型:1字节][状态码:1字节]
///
/// 状态码：
/// 0x00: 成功
/// 0x01: 格式错误
/// 0x02: 不支持的消息类型
/// 0x03: 设备忙
///
/// 服务UUID和特征UUID（使用Nordic UART Service）：
/// 服务UUID: 6E400001-B5A3-F393-E0A9-E50E24DCCA9E
/// 写特征UUID: 6E400002-B5A3-F393-E0A9-E50E24DCCA9E
/// 通知特征UUID: 6E400003-B5A3-F393-E0A9-E50E24DCCA9E

import 'dart:convert';
import 'dart:typed_data';

/// 消息类型常量
class BleMessageType {
  /// 时间同步（手机 -> 设备）
  static const int timeSync = 0x01;

  /// 文本消息（手机 -> 设备）
  static const int textMessage = 0x02;

  /// 确认响应（设备 -> 手机）
  static const int ack = 0x03;
}

/// 状态码常量
class BleStatusCode {
  static const int success = 0x00;
  static const int formatError = 0x01;
  static const int unsupportedType = 0x02;
  static const int deviceBusy = 0x03;
}

/// UUID配置常量（Nordic UART Service）
class BleUuid {
  /// 主服务UUID
  static const String service = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';

  /// 写特征UUID（手机 -> 设备）
  static const String writeCharacteristic =
      '6E400002-B5A3-F393-E0A9-E50E24DCCA9E';

  /// 通知特征UUID（设备 -> 手机）
  static const String notifyCharacteristic =
      '6E400003-B5A3-F393-E0A9-E50E24DCCA9E';
}

/// Bipupu 蓝牙协议工具类
class BleProtocol {
  /// 协议版本
  static const int version = 0x01;

  /// 最大消息长度（考虑BLE MTU限制）
  static const int maxMessageLength = 240; // 预留16字节给协议头

  /// 编码时间同步消息
  ///
  /// 格式：[版本:1][类型:1=0x01][Unix时间戳:4]
  static Uint8List encodeTimeSync(int timestamp) {
    final buffer = ByteData(6); // 1+1+4
    buffer.setUint8(0, version);
    buffer.setUint8(1, BleMessageType.timeSync);
    buffer.setUint32(2, timestamp, Endian.little);
    return buffer.buffer.asUint8List();
  }

  /// 编码文本消息
  ///
  /// 格式：[版本:1][类型:1=0x02][发送人ID长度:1][发送人ID...][消息内容...]
  static Uint8List encodeTextMessage(String senderId, String message) {
    // 编码发送人ID为UTF-8
    final senderBytes = utf8.encode(senderId);
    if (senderBytes.length > 255) {
      throw ArgumentError('发送人ID过长，最大255字节');
    }

    // 编码消息内容为UTF-8
    final messageBytes = utf8.encode(message);

    // 计算总长度
    final totalLength = 1 + 1 + 1 + senderBytes.length + messageBytes.length;
    if (totalLength > maxMessageLength) {
      throw ArgumentError('消息过长，最大$maxMessageLength字节');
    }

    // 创建缓冲区
    final buffer = Uint8List(totalLength);
    int offset = 0;

    // 写入协议版本
    buffer[offset++] = version;

    // 写入消息类型
    buffer[offset++] = BleMessageType.textMessage;

    // 写入发送人ID长度
    buffer[offset++] = senderBytes.length;

    // 写入发送人ID
    buffer.setRange(offset, offset + senderBytes.length, senderBytes);
    offset += senderBytes.length;

    // 写入消息内容
    buffer.setRange(offset, offset + messageBytes.length, messageBytes);

    return buffer;
  }

  /// 编码确认响应
  ///
  /// 格式：[版本:1][类型:1=0x03][原始消息类型:1][状态码:1]
  static Uint8List encodeAck(int originalMessageType, int statusCode) {
    final buffer = ByteData(4); // 1+1+1+1
    buffer.setUint8(0, version);
    buffer.setUint8(1, BleMessageType.ack);
    buffer.setUint8(2, originalMessageType);
    buffer.setUint8(3, statusCode);
    return buffer.buffer.asUint8List();
  }

  /// 解码消息
  ///
  /// 返回解码后的消息类型和数据
  static Map<String, dynamic> decodeMessage(Uint8List data) {
    if (data.length < 2) {
      throw FormatException('消息太短');
    }

    final version = data[0];
    if (version != BleProtocol.version) {
      throw FormatException('不支持的协议版本: $version');
    }

    final messageType = data[1];

    switch (messageType) {
      case BleMessageType.timeSync:
        return _decodeTimeSync(data);
      case BleMessageType.textMessage:
        return _decodeTextMessage(data);
      case BleMessageType.ack:
        return _decodeAck(data);
      default:
        throw FormatException('不支持的消息类型: $messageType');
    }
  }

  /// 解码时间同步消息
  static Map<String, dynamic> _decodeTimeSync(Uint8List data) {
    if (data.length != 6) {
      throw FormatException('时间同步消息长度错误');
    }

    final buffer = ByteData.view(data.buffer);
    final timestamp = buffer.getUint32(2, Endian.little);

    return {'type': BleMessageType.timeSync, 'timestamp': timestamp};
  }

  /// 解码文本消息
  static Map<String, dynamic> _decodeTextMessage(Uint8List data) {
    if (data.length < 3) {
      throw FormatException('文本消息长度错误');
    }

    final senderIdLength = data[2];
    if (data.length < 3 + senderIdLength) {
      throw FormatException('发送人ID长度错误');
    }

    // 解码发送人ID
    final senderIdBytes = data.sublist(3, 3 + senderIdLength);
    final senderId = utf8.decode(senderIdBytes);

    // 解码消息内容
    final messageBytes = data.sublist(3 + senderIdLength);
    final message = utf8.decode(messageBytes);

    return {
      'type': BleMessageType.textMessage,
      'senderId': senderId,
      'message': message,
    };
  }

  /// 解码确认响应
  static Map<String, dynamic> _decodeAck(Uint8List data) {
    if (data.length != 4) {
      throw FormatException('确认响应长度错误');
    }

    return {
      'type': BleMessageType.ack,
      'originalType': data[2],
      'statusCode': data[3],
    };
  }

  /// 检查消息是否是确认响应
  static bool isAck(Uint8List data) {
    try {
      if (data.length >= 2) {
        return data[0] == version && data[1] == BleMessageType.ack;
      }
    } catch (_) {}
    return false;
  }

  /// 检查消息是否是时间同步
  static bool isTimeSync(Uint8List data) {
    try {
      if (data.length >= 2) {
        return data[0] == version && data[1] == BleMessageType.timeSync;
      }
    } catch (_) {}
    return false;
  }

  /// 检查消息是否是文本消息
  static bool isTextMessage(Uint8List data) {
    try {
      if (data.length >= 2) {
        return data[0] == version && data[1] == BleMessageType.textMessage;
      }
    } catch (_) {}
    return false;
  }

  /// 获取当前Unix时间戳（秒）
  static int getCurrentTimestamp() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  /// 从时间戳创建DateTime
  static DateTime timestampToDateTime(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }
}
