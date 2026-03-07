import 'dart:convert';
import 'package:flutter/foundation.dart';

/// 单一统合蓝牙协议服务（增强版）
///
/// 协议设计目标：
/// 1. 单一协议格式，简化实现
/// 2. 在消息转发的同时完成时间同步
/// 3. 支持多种消息类型
/// 4. 简单高效，减少蓝牙传输开销
/// 5. 数据完整性校验，防止比特翻转
/// 6. 安全的UTF-8文本传输，避免截断风险
///
/// 协议格式（增强版）：
/// [协议头(1字节)][时间戳(4字节)][消息类型(1字节)][数据长度(2字节)][数据(N字节)][校验和(1字节)]
///
/// 字节布局：
/// 0: 协议头 (0xB0)
/// 1-4: 时间戳 (Unix时间戳，秒，小端序)
/// 5: 消息类型
/// 6-7: 数据长度 (小端序)
/// 8+: 数据内容
/// N: 校验和 (所有字节的异或校验)
///
/// 校验和计算：对协议头到数据内容的所有字节进行异或运算
class UnifiedBluetoothProtocol {
  static final UnifiedBluetoothProtocol _instance =
      UnifiedBluetoothProtocol._internal();
  factory UnifiedBluetoothProtocol() => _instance;
  UnifiedBluetoothProtocol._internal();

  // ========== 协议常量定义 ==========

  /// 协议头 - B代表Bipupu
  static const int PROTOCOL_HEADER = 0xB0;

  /// 消息类型定义
  static const int MESSAGE_TYPE_TIME_SYNC = 0x01; // 时间同步（数据可以为空）
  static const int MESSAGE_TYPE_TEXT = 0x02; // 文本消息
  static const int MESSAGE_TYPE_ACKNOWLEDGEMENT = 0x03; // 确认响应
  static const int MESSAGE_TYPE_BINDING_INFO = 0x04; // 绑定信息交换
  static const int MESSAGE_TYPE_UNBIND_COMMAND = 0x05; // 解绑命令

  /// 最大数据长度 (受限于蓝牙MTU，通常为20-244字节)
  /// 我们设置为240字节，为协议头和校验和留出空间
  static const int MAX_DATA_LENGTH = 240;

  /// 协议头部固定长度 (协议头 + 时间戳 + 消息类型 + 数据长度)
  static const int HEADER_LENGTH = 8;

  /// 校验和字节长度
  static const int CHECKSUM_LENGTH = 1;

  /// 最小数据包长度 (头部 + 校验和)
  static const int MIN_PACKET_LENGTH = HEADER_LENGTH + CHECKSUM_LENGTH;

  // ========== 数据包创建方法 ==========

  /// 创建统一协议数据包（带校验和）
  ///
  /// 参数：
  /// - messageType: 消息类型
  /// - data: 消息数据（可以为空）
  /// - timestamp: 时间戳（可选，默认使用当前时间）
  ///
  /// 返回：Uint8List格式的数据包（包含校验和）
  Uint8List createPacket({
    required int messageType,
    Uint8List? data,
    DateTime? timestamp,
  }) {
    // 验证消息类型
    _validateMessageType(messageType);

    // 获取或生成时间戳
    final now = timestamp ?? DateTime.now().toUtc();
    final int ts = now.millisecondsSinceEpoch ~/ 1000;

    // 处理数据
    final Uint8List finalData = data ?? Uint8List(0);
    final int dataLength = finalData.length;

    // 验证数据长度
    if (dataLength > MAX_DATA_LENGTH) {
      throw ArgumentError(
        'Data too large: $dataLength bytes (max $MAX_DATA_LENGTH)',
      );
    }

    // 创建数据包（包含校验和位置）
    final packet = Uint8List(HEADER_LENGTH + dataLength + CHECKSUM_LENGTH);

    // 设置协议头
    packet[0] = PROTOCOL_HEADER;

    // 设置时间戳（小端序）
    final byteData = ByteData.view(packet.buffer);
    byteData.setUint32(1, ts, Endian.little);

    // 设置消息类型
    packet[5] = messageType;

    // 设置数据长度（小端序）
    byteData.setUint16(6, dataLength, Endian.little);

    // 设置数据内容
    if (dataLength > 0) {
      packet.setRange(HEADER_LENGTH, HEADER_LENGTH + dataLength, finalData);
    }

    // 计算并设置校验和
    final checksum = _calculateChecksum(packet, HEADER_LENGTH + dataLength);
    packet[HEADER_LENGTH + dataLength] = checksum;

    if (kDebugMode) {
      print(
        'Created unified protocol packet: '
        'header=0x${PROTOCOL_HEADER.toRadixString(16).toUpperCase()}, '
        'timestamp=$ts, '
        'type=${getMessageTypeName(messageType)} ($messageType), '
        'dataLength=$dataLength, '
        'checksum=0x${checksum.toRadixString(16).toUpperCase()}',
      );
    }

    return packet;
  }

  /// 创建时间同步数据包
  ///
  /// 这是时间同步的专用方法，消息类型为MESSAGE_TYPE_TIME_SYNC
  /// 数据部分可以为空，因为时间戳已经在协议头部
  Uint8List createTimeSyncPacket({DateTime? timestamp}) {
    return createPacket(
      messageType: MESSAGE_TYPE_TIME_SYNC,
      data: null,
      timestamp: timestamp,
    );
  }

  /// 创建文本消息数据包
  ///
  /// ## 数据字段布局
  /// ```
  /// [ 1字节: sender_len ][ sender_len 字节: 发送者名 UTF-8 ][ 剩余字节: 正文 UTF-8 ]
  /// ```
  /// - `sender_len = 0`：直接蓝牙发送（DeviceDetailPage），ESP32 显示为 "App"
  /// - `sender_len > 0`：网络转发消息，ESP32 直接读取二进制字段，无字符串解析
  ///
  /// ## 截断策略
  /// 总 data ≤ [MAX_DATA_LENGTH] = 240 字节。
  /// sender 最长 63 字节（留余量给正文）；正文超出部分字节感知截断并追加 `…`。
  ///
  /// 参数：
  /// - [body]：消息正文
  /// - [sender]：发送者显示名（默认 `'App'`，即直接蓝牙发送）
  /// - [timestamp]：时间戳（可选，默认当前时间）
  Uint8List createTextPacket(
    String body, {
    String sender = 'App',
    DateTime? timestamp,
  }) {
    // ── 编码 sender ────────────────────────────────────────────────────────
    const int maxSenderBytes = 63; // 1 字节 len + 最多 63 字节名 = 64 字节开销
    final rawSenderBytes = utf8.encode(sender);

    // 向前找 UTF-8 字符边界，防止截断出乱码
    int senderLen = rawSenderBytes.length;
    if (senderLen > maxSenderBytes) {
      senderLen = maxSenderBytes;
      while (senderLen > 0 && (rawSenderBytes[senderLen] & 0xC0) == 0x80) {
        senderLen--;
      }
    }

    // sender_len = 0 when sender is exactly "App" AND senderLen stays 0?
    // No: we always encode sender_len accurately.
    // Special case: if original sender == 'App', we still encode sender_len=3
    // so ESP32 reads it correctly. The ESP32 will show "App" as-is.
    // (No special case needed — the protocol is uniform.)

    // ── 编码 body ──────────────────────────────────────────────────────────
    final maxBodyBytes = MAX_DATA_LENGTH - 1 - senderLen; // 1 for len byte
    final rawBodyBytes = utf8.encode(body);

    Uint8List safeBodyBytes;
    if (rawBodyBytes.length <= maxBodyBytes) {
      safeBodyBytes = Uint8List.fromList(rawBodyBytes);
    } else {
      safeBodyBytes = _safeUtf8Truncate(
        Uint8List.fromList(rawBodyBytes),
        maxBodyBytes,
      );
    }

    // ── 组装 data = [senderLen(1)][sender][body] ──────────────────────────
    final data = Uint8List(1 + senderLen + safeBodyBytes.length);
    data[0] = senderLen;
    if (senderLen > 0) {
      data.setRange(1, 1 + senderLen, rawSenderBytes.sublist(0, senderLen));
    }
    data.setRange(1 + senderLen, data.length, safeBodyBytes);

    if (kDebugMode) {
      print(
        '[BLE] createTextPacket sender="$sender"($senderLen B) '
        'body=${safeBodyBytes.length} B total_data=${data.length} B',
      );
    }

    return createPacket(
      messageType: MESSAGE_TYPE_TEXT,
      data: data,
      timestamp: timestamp,
    );
  }

  /// 创建确认响应数据包
  Uint8List createAcknowledgementPacket(
    int originalMessageId, {
    DateTime? timestamp,
  }) {
    final data = Uint8List(4);
    final byteData = ByteData.view(data.buffer);
    byteData.setUint32(0, originalMessageId, Endian.little);

    return createPacket(
      messageType: MESSAGE_TYPE_ACKNOWLEDGEMENT,
      data: data,
      timestamp: timestamp,
    );
  }

  // ========== 数据包解析方法 ==========

  /// 解析统一协议数据包（带校验和验证）
  ///
  /// 参数：
  /// - data: 接收到的原始数据
  ///
  /// 返回：包含解析结果的Map，如果解析失败返回null
  Map<String, dynamic>? parsePacket(Uint8List data) {
    // 基本验证
    if (data.isEmpty) {
      if (kDebugMode) {
        print('Empty data received');
      }
      return null;
    }

    // 检查最小长度
    if (data.length < MIN_PACKET_LENGTH) {
      if (kDebugMode) {
        print(
          'Packet too short: ${data.length} bytes, '
          'minimum $MIN_PACKET_LENGTH bytes required',
        );
      }
      return null;
    }

    // 检查协议头
    if (data[0] != PROTOCOL_HEADER) {
      if (kDebugMode) {
        print(
          'Invalid protocol header: 0x${data[0].toRadixString(16).toUpperCase()}, '
          'expected 0x${PROTOCOL_HEADER.toRadixString(16).toUpperCase()}',
        );
      }
      return null;
    }

    try {
      final byteData = ByteData.view(data.buffer);

      // 解析时间戳
      final timestamp = byteData.getUint32(1, Endian.little);

      // 解析消息类型
      final messageType = data[5];

      // 验证消息类型
      if (!_isValidMessageType(messageType)) {
        if (kDebugMode) {
          print('Invalid message type: $messageType');
        }
        return null;
      }

      // 解析数据长度
      final dataLength = byteData.getUint16(6, Endian.little);

      // 验证数据长度
      if (dataLength > MAX_DATA_LENGTH) {
        if (kDebugMode) {
          print('Data length exceeds maximum: $dataLength > $MAX_DATA_LENGTH');
        }
        return null;
      }

      // 验证总长度
      final expectedLength = HEADER_LENGTH + dataLength + CHECKSUM_LENGTH;
      if (data.length != expectedLength) {
        if (kDebugMode) {
          print(
            'Packet length mismatch: expected $expectedLength bytes, '
            'got ${data.length} bytes',
          );
        }
        return null;
      }

      // 验证校验和
      final calculatedChecksum = _calculateChecksum(data, data.length - 1);
      final receivedChecksum = data[data.length - 1];

      if (calculatedChecksum != receivedChecksum) {
        if (kDebugMode) {
          print(
            'Checksum mismatch: calculated=0x${calculatedChecksum.toRadixString(16).toUpperCase()}, '
            'received=0x${receivedChecksum.toRadixString(16).toUpperCase()}',
          );
        }
        return null;
      }

      // 提取数据
      Uint8List messageData = Uint8List(0);
      String? text;
      int? originalMessageId;

      if (dataLength > 0) {
        messageData = data.sublist(HEADER_LENGTH, HEADER_LENGTH + dataLength);

        // 根据消息类型解析数据
        switch (messageType) {
          case MESSAGE_TYPE_TEXT:
            try {
              // 使用allowMalformed参数确保即使有轻微损坏也能解码
              text = utf8.decode(messageData, allowMalformed: true);
            } catch (e) {
              text = '[UTF-8解码错误]';
              if (kDebugMode) {
                print('UTF-8解码失败: $e');
              }
            }
            break;

          case MESSAGE_TYPE_ACKNOWLEDGEMENT:
            if (messageData.length >= 4) {
              final idByteData = ByteData.view(messageData.buffer);
              originalMessageId = idByteData.getUint32(0, Endian.little);
            }
            break;
        }
      }

      // 构建结果
      final result = {
        'protocol': 'unified',
        'header': PROTOCOL_HEADER,
        'timestamp': timestamp,
        'messageType': messageType,
        'messageTypeName': getMessageTypeName(messageType),
        'dataLength': dataLength,
        'data': messageData,
        'checksum': receivedChecksum,
        'checksumValid': true,
        'datetime': DateTime.fromMillisecondsSinceEpoch(
          timestamp * 1000,
          isUtc: true,
        ),
      };

      // 添加类型特定的字段
      if (text != null) {
        result['text'] = text;
      }

      if (originalMessageId != null) {
        result['originalMessageId'] = originalMessageId;
      }

      if (kDebugMode) {
        print(
          'Parsed unified protocol packet: '
          'timestamp=$timestamp, '
          'type=${getMessageTypeName(messageType)} ($messageType), '
          'dataLength=$dataLength, '
          'checksum=0x${receivedChecksum.toRadixString(16).toUpperCase()} (valid)',
        );

        if (text != null) {
          print('解析文本: "$text"');
        }
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to parse packet: $e');
      }
      return null;
    }
  }

  /// 快速检查数据包是否有效（包括校验和验证）
  bool isValidPacket(Uint8List data) {
    if (data.isEmpty || data[0] != PROTOCOL_HEADER) {
      return false;
    }

    if (data.length < MIN_PACKET_LENGTH) {
      return false;
    }

    try {
      final messageType = data[5];
      if (!_isValidMessageType(messageType)) {
        return false;
      }

      final byteData = ByteData.view(data.buffer);
      final dataLength = byteData.getUint16(6, Endian.little);

      if (dataLength > MAX_DATA_LENGTH) {
        return false;
      }

      final expectedLength = HEADER_LENGTH + dataLength + CHECKSUM_LENGTH;
      if (data.length != expectedLength) {
        return false;
      }

      // 验证校验和
      final calculatedChecksum = _calculateChecksum(data, data.length - 1);
      final receivedChecksum = data[data.length - 1];

      return calculatedChecksum == receivedChecksum;
    } catch (e) {
      return false;
    }
  }

  /// 验证数据包但不解析内容（轻量级验证）
  bool validatePacket(Uint8List data) {
    return isValidPacket(data);
  }

  // ========== 工具方法 ==========

  /// 获取消息类型名称
  String getMessageTypeName(int messageType) {
    switch (messageType) {
      case MESSAGE_TYPE_TIME_SYNC:
        return 'Time Sync';
      case MESSAGE_TYPE_TEXT:
        return 'Text Message';
      case MESSAGE_TYPE_ACKNOWLEDGEMENT:
        return 'Acknowledgement';
      case MESSAGE_TYPE_BINDING_INFO:
        return 'Binding Info';
      case MESSAGE_TYPE_UNBIND_COMMAND:
        return 'Unbind Command';
      default:
        return 'Unknown ($messageType)';
    }
  }

  /// 格式化时间戳为可读字符串
  String formatTimestamp(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      timestamp * 1000,
      isUtc: true,
    );
    final localTime = dateTime.toLocal();

    return '${localTime.year}-${localTime.month.toString().padLeft(2, '0')}-'
        '${localTime.day.toString().padLeft(2, '0')} '
        '${localTime.hour.toString().padLeft(2, '0')}:'
        '${localTime.minute.toString().padLeft(2, '0')}:'
        '${localTime.second.toString().padLeft(2, '0')}';
  }

  /// 计算数据包大小（包含校验和）
  int calculatePacketSize({String? text, Uint8List? data}) {
    final int dataLength = text != null
        ? utf8.encode(text).length
        : (data?.length ?? 0);

    return HEADER_LENGTH + dataLength + CHECKSUM_LENGTH;
  }

  /// 获取最大文本长度（考虑UTF-8编码）
  int getMaxTextLength() {
    // 保守估计，留出一些空间
    return MAX_DATA_LENGTH ~/ 3; // UTF-8中文字符最多3字节
  }

  /// 获取协议版本信息
  Map<String, dynamic> getProtocolInfo() {
    return {
      'version': '1.2',
      'header': '0xB0',
      'hasChecksum': true,
      'checksumType': 'XOR',
      'maxDataLength': MAX_DATA_LENGTH,
      'minPacketLength': MIN_PACKET_LENGTH,
      'hasSafeUtf8Truncation': true,
      'supportedMessageTypes': [
        {'id': MESSAGE_TYPE_TIME_SYNC, 'name': 'Time Sync'},
        {'id': MESSAGE_TYPE_TEXT, 'name': 'Text Message'},
        {'id': MESSAGE_TYPE_ACKNOWLEDGEMENT, 'name': 'Acknowledgement'},
        {'id': MESSAGE_TYPE_BINDING_INFO, 'name': 'Binding Info'},
        {'id': MESSAGE_TYPE_UNBIND_COMMAND, 'name': 'Unbind Command'},
      ],
    };
  }

  // ========== 私有方法 ==========

  /// 安全的UTF-8截断函数
  ///
  /// 参数：
  /// - bytes: UTF-8编码的字节数组
  /// - maxLength: 最大允许字节数
  ///
  /// 返回：截断后的字节数组，确保是有效的UTF-8序列
  /// 注意：会回退到UTF-8字符边界，避免在多字节字符中间截断
  Uint8List _safeUtf8Truncate(List<int> bytes, int maxLength) {
    if (bytes.isEmpty || maxLength <= 0) {
      return Uint8List(0);
    }

    if (bytes.length <= maxLength) {
      return Uint8List.fromList(bytes);
    }

    // 从maxLength开始向前查找完整的UTF-8字符边界
    int safeLength = maxLength;

    // UTF-8字符边界规则：
    // 1. 单字节字符: 0xxxxxxx (0x00-0x7F)
    // 2. 多字节字符首字节:
    //    - 2字节: 110xxxxx (0xC0-0xDF)
    //    - 3字节: 1110xxxx (0xE0-0xEF)
    //    - 4字节: 11110xxx (0xF0-0xF7)
    // 3. 后续字节: 10xxxxxx (0x80-0xBF)

    // 向前查找，直到找到字符边界
    while (safeLength > 0 && (bytes[safeLength - 1] & 0xC0) == 0x80) {
      // 这是后续字节，继续向前查找
      safeLength--;
    }

    return safeLength > 0
        ? Uint8List.fromList(bytes.sublist(0, safeLength))
        : Uint8List(0);
  }

  /// 计算校验和（异或校验）
  int _calculateChecksum(Uint8List data, int length) {
    int checksum = 0;
    for (int i = 0; i < length; i++) {
      checksum ^= data[i];
    }
    return checksum & 0xFF; // 确保返回单字节
  }

  /// 验证消息类型
  void _validateMessageType(int messageType) {
    if (!_isValidMessageType(messageType)) {
      throw ArgumentError('Invalid message type: $messageType');
    }
  }

  /// 检查消息类型是否有效
  bool _isValidMessageType(int messageType) {
    return messageType >= MESSAGE_TYPE_TIME_SYNC &&
        messageType <= MESSAGE_TYPE_UNBIND_COMMAND;
  }
}
