import 'dart:async';
import 'dart:convert'; // 必须引用，用于 utf8.encode
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothDeviceService {
  static final BluetoothDeviceService _instance =
      BluetoothDeviceService._internal();
  factory BluetoothDeviceService() => _instance;
  BluetoothDeviceService._internal();

  BluetoothDevice? _connectedDevice;
  StreamSubscription<BluetoothConnectionState>? _stateSubscription;
  BluetoothCharacteristic? _nusTxCharacteristic;

  // 使用 ValueNotifier 驱动 UI，状态更清晰
  final ValueNotifier<BluetoothConnectionState> connectionState = ValueNotifier(
    BluetoothConnectionState.disconnected,
  );

  /// 核心连接方法
  Future<void> connect(BluetoothDevice device) async {
    // 1. 预清理：防止重复连接或状态残留
    if (_connectedDevice != null) {
      await disconnect();
    }

    // 2. 建立连接监听
    // 注意：监听仅负责状态同步和非正常断开后的清理，不触发复杂的业务逻辑
    _stateSubscription = device.connectionState.listen((state) {
      connectionState.value = state;
      if (kDebugMode) {
        print('BLE State Update: $state');
      }

      if (state == BluetoothConnectionState.disconnected) {
        _cleanupInternalState();
      }
    });

    try {
      // 3. 发起物理连接
      // autoConnect: false 适合手动点击连接，稳定性更高
      await device.connect(
        license: License.free,
        timeout: const Duration(seconds: 10),
        autoConnect: false,
      );

      // 4. 连接成功后，启动“串行初始化”流程
      _connectedDevice = device;
      await _runSequentialSetup(device);
    } catch (e) {
      if (kDebugMode) {
        print('Connect failed: $e');
      }
      await disconnect();
      rethrow;
    }
  }

  /// 串行初始化逻辑：避开蓝牙栈并发冲突
  Future<void> _runSequentialSetup(BluetoothDevice device) async {
    try {
      // A. 给底层链路一点“呼吸时间”处理配对或参数握手
      await Future.delayed(const Duration(milliseconds: 600));

      // B. 发现服务
      List<BluetoothService> services = await device.discoverServices();

      // C. 查找目标特征值
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() ==
            "6e400001-b5a3-f393-e0a9-e50e24dcca9e") {
          for (var c in service.characteristics) {
            if (c.uuid.toString().toLowerCase() ==
                "6e400002-b5a3-f393-e0a9-e50e24dcca9e") {
              _nusTxCharacteristic = c;
              break;
            }
          }
        }
      }

      if (_nusTxCharacteristic == null) {
        throw Exception("NUS TX Characteristic not found");
      }

      // D. MTU 协商 (Android 必须在 Discover Services 之后请求)
      if (Platform.isAndroid) {
        try {
          await device.requestMtu(247);
          // 等待 MTU 协议交换完成
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          if (kDebugMode) {
            print("MTU request optional: $e");
          }
        }
      }

      // E. 初始化业务逻辑：同步时间
      await syncTime();
    } catch (e) {
      if (kDebugMode) {
        print('Setup process failed: $e');
      }
      // 如果关键初始化失败，建议断开重来
      await disconnect();
    }
  }

  /// 发送时间同步
  Future<void> syncTime() async {
    final characteristic = _nusTxCharacteristic;
    if (characteristic == null) {
      return;
    }

    try {
      final now = DateTime.now().toUtc();
      // 获取 Unix 时间戳 (秒)
      final int timestamp = now.millisecondsSinceEpoch ~/ 1000;

      // 构造 5 字节数据包: [Header(1), Timestamp(4)]
      final packet = Uint8List(5);
      packet[0] = 0xA1; // 协议头

      // 使用 ByteData 写入 4 字节小端序时间戳
      ByteData bd = ByteData.view(packet.buffer);
      bd.setUint32(1, timestamp, Endian.little);

      await characteristic.write(
        packet,
        withoutResponse: characteristic.properties.writeWithoutResponse,
      );

      if (kDebugMode) {
        print('Time sync sent: UTC $timestamp');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Sync time error: $e');
      }
    }
  }

  /// 发送 UTF-8 文本消息 (0xA2)
  Future<void> sendTextMessage(String text) async {
    final characteristic = _nusTxCharacteristic;
    if (characteristic == null) {
      return;
    }

    try {
      // 1. 将文本转为 UTF-8 字节数组
      final utf8Bytes = utf8.encode(text);

      // 2. 检查 MTU 限制并分包发送
      await _sendTextWithChunking(characteristic, utf8Bytes, text);
    } catch (e) {
      if (kDebugMode) {
        print('Send text error: $e');
      }
      rethrow; // 重新抛出异常让调用者处理
    }
  }

  /// 分包发送文本消息，考虑 MTU 限制
  Future<void> _sendTextWithChunking(
    BluetoothCharacteristic characteristic,
    List<int> utf8Bytes,
    String originalText,
  ) async {
    // 保守的 MTU 限制，减去协议头 1 字节
    const maxPayloadSize = 200;
    const maxChunkSize = maxPayloadSize - 1; // 减去协议头

    if (utf8Bytes.length <= maxChunkSize) {
      // 单包发送
      final packet = Uint8List(1 + utf8Bytes.length);
      packet[0] = 0xA2; // 协议头：消息转发
      packet.setRange(1, packet.length, utf8Bytes);

      await characteristic.write(
        packet,
        withoutResponse: characteristic.properties.writeWithoutResponse,
      );

      if (kDebugMode) {
        print('Sent A2 Message: $originalText (Length: ${utf8Bytes.length})');
      }
      return;
    }

    // 多包发送
    if (kDebugMode) {
      print('Sending long message in chunks: ${utf8Bytes.length} bytes');
    }

    for (var i = 0; i < utf8Bytes.length; i += maxChunkSize) {
      final end = i + maxChunkSize;
      final chunkEnd = end < utf8Bytes.length ? end : utf8Bytes.length;
      final chunkSize = chunkEnd - i;

      // 创建数据包：协议头 + 数据块
      final packet = Uint8List(1 + chunkSize);
      packet[0] = 0xA2; // 协议头：消息转发
      packet.setRange(1, packet.length, utf8Bytes, i);

      await characteristic.write(
        packet,
        withoutResponse: characteristic.properties.writeWithoutResponse,
      );

      if (kDebugMode) {
        print(
          'Sent chunk ${(i ~/ maxChunkSize) + 1}/'
          '${(utf8Bytes.length / maxChunkSize).ceil()}: '
          '$chunkSize bytes',
        );
      }

      // 块间延迟，避免蓝牙栈过载
      if (chunkEnd < utf8Bytes.length) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    if (kDebugMode) {
      print('Completed sending long message');
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
    } finally {
      _cleanupInternalState();
      connectionState.value = BluetoothConnectionState.disconnected;
    }
  }

  /// 清理内部引用
  void _cleanupInternalState() {
    _stateSubscription?.cancel();
    _stateSubscription = null;
    _connectedDevice = null;
    _nusTxCharacteristic = null;
  }
}
