import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/bluetooth/ble_manager.dart';
import 'ble_protocol.dart';

/// 蓝牙协议服务提供者
final bleProtocolServiceProvider = Provider<BleProtocolService>((ref) {
  final bleManager = ref.read(bleManagerProvider);
  return BleProtocolService(bleManager);
});

/// 蓝牙协议服务
///
/// 负责：
/// 1. 时间同步（连接成功后自动发送）
/// 2. 文本消息转发
class BleProtocolService {
  final BleManager _bleManager;

  /// 设备通知订阅
  final Map<String, StreamSubscription<List<int>>> _deviceSubscriptions = {};

  BleProtocolService(this._bleManager);

  /// 初始化设备协议处理
  Future<void> initializeDevice(String deviceId) async {
    debugPrint('[BleProtocolService] 初始化设备协议: $deviceId');

    try {
      // 订阅设备通知
      final subscription = _bleManager
          .subscribeCharacteristic(
            deviceId,
            BleUuid.service,
            BleUuid.notifyCharacteristic,
          )
          .listen((data) {
            _handleDeviceNotification(deviceId, data);
          });

      _deviceSubscriptions[deviceId] = subscription;
      debugPrint('[BleProtocolService] 已订阅设备通知: $deviceId');
    } catch (e) {
      debugPrint('[BleProtocolService] 订阅设备通知失败: $e');
      rethrow;
    }
  }

  /// 释放设备资源
  Future<void> disposeDevice(String deviceId) async {
    debugPrint('[BleProtocolService] 释放设备资源: $deviceId');

    // 取消订阅
    await _deviceSubscriptions[deviceId]?.cancel();
    _deviceSubscriptions.remove(deviceId);
  }

  /// 发送时间同步到设备
  ///
  /// 在蓝牙连接成功后调用
  Future<void> sendTimeSync(String deviceId) async {
    debugPrint('[BleProtocolService] 发送时间同步到设备: $deviceId');

    try {
      final timestamp = BleProtocol.getCurrentTimestamp();
      final timeSyncData = BleProtocol.encodeTimeSync(timestamp);

      // 发送时间同步消息
      await _sendDataToDevice(deviceId, timeSyncData);
      debugPrint('[BleProtocolService] 时间同步已发送: $deviceId');
    } catch (e) {
      debugPrint('[BleProtocolService] 发送时间同步失败: $e');
      rethrow;
    }
  }

  /// 发送文本消息到设备
  ///
  /// 发送人ID和消息内容分开传输
  Future<void> sendTextMessage(
    String deviceId,
    String senderId,
    String message,
  ) async {
    debugPrint('[BleProtocolService] 发送文本消息到设备: $deviceId, 发送人: $senderId');

    try {
      final messageData = BleProtocol.encodeTextMessage(senderId, message);

      // 发送文本消息
      await _sendDataToDevice(deviceId, messageData);
      debugPrint('[BleProtocolService] 文本消息已发送: $deviceId');
    } catch (e) {
      debugPrint('[BleProtocolService] 发送文本消息失败: $e');
      rethrow;
    }
  }

  /// 处理设备通知
  void _handleDeviceNotification(String deviceId, List<int> data) {
    try {
      final uint8Data = Uint8List.fromList(data);

      // 检查是否是确认消息
      if (BleProtocol.isAck(uint8Data)) {
        final decoded = BleProtocol.decodeMessage(uint8Data);
        final originalType = decoded['originalType'] as int;
        final statusCode = decoded['statusCode'] as int;

        debugPrint(
          '[BleProtocolService] 收到确认: 设备=$deviceId, 原始类型=$originalType, 状态=$statusCode',
        );

        // 根据状态码处理
        if (statusCode != BleStatusCode.success) {
          debugPrint('[BleProtocolService] 消息发送失败，状态码: $statusCode');
        }
      } else {
        // 其他类型的消息
        debugPrint('[BleProtocolService] 收到非确认消息，类型: ${uint8Data[1]}');
      }
    } catch (e) {
      debugPrint('[BleProtocolService] 处理设备通知失败: $e');
    }
  }

  /// 发送数据到设备
  Future<void> _sendDataToDevice(String deviceId, Uint8List data) async {
    try {
      await _bleManager.writeCharacteristic(
        deviceId,
        BleUuid.service,
        BleUuid.writeCharacteristic,
        data,
      );
      debugPrint('[BleProtocolService] 数据发送成功: ${data.length}字节');
    } catch (e) {
      debugPrint('[BleProtocolService] 数据发送失败: $e');
      rethrow;
    }
  }

  /// 释放所有资源
  void dispose() {
    debugPrint('[BleProtocolService] 释放所有资源');

    // 取消所有订阅
    for (final subscription in _deviceSubscriptions.values) {
      subscription.cancel();
    }
    _deviceSubscriptions.clear();
  }
}
