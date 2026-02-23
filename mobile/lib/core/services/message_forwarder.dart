import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../features/bluetooth/logic/ble_protocol_service.dart';
import '../bluetooth/ble_manager.dart';
import './polling_service.dart';
import '../../shared/models/message_model.dart';

/// 消息转发服务提供者
final messageForwarderProvider = Provider<MessageForwarder>((ref) {
  final pollingService = ref.read(pollingServiceProvider);
  final bleProtocolService = ref.read(bleProtocolServiceProvider);
  final bleManager = ref.read(bleManagerProvider);

  return MessageForwarder(
    pollingService: pollingService,
    bleProtocolService: bleProtocolService,
    bleManager: bleManager,
  );
});

/// 消息转发服务
///
/// 负责：
/// 1. 监听轮询服务的新消息
/// 2. 将消息转发到所有连接的蓝牙设备
/// 3. 在设备连接成功后自动发送时间同步
class MessageForwarder {
  final PollingService _pollingService;
  final BleProtocolService _bleProtocolService;
  final BleManager _bleManager;

  /// 消息订阅
  StreamSubscription<List<MessageResponse>>? _messageSubscription;

  /// 设备连接状态订阅
  StreamSubscription<List<BleDevice>>? _deviceSubscription;

  /// 当前连接的设备
  final List<BleDevice> _connectedDevices = [];

  /// 是否正在运行
  bool _isRunning = false;

  MessageForwarder({
    required PollingService pollingService,
    required BleProtocolService bleProtocolService,
    required BleManager bleManager,
  }) : _pollingService = pollingService,
       _bleProtocolService = bleProtocolService,
       _bleManager = bleManager;

  /// 启动消息转发服务
  Future<void> start() async {
    if (_isRunning) {
      debugPrint('[MessageForwarder] 服务已在运行');
      return;
    }

    debugPrint('[MessageForwarder] 启动消息转发服务');
    _isRunning = true;

    // 监听新消息
    _messageSubscription = _pollingService.messageStream.listen(
      _handleNewMessages,
    );

    // 监听设备连接状态
    _deviceSubscription = _bleManager.connectedDevicesStream.listen(
      _handleDeviceUpdate,
    );

    // 获取当前已连接的设备
    final currentDevices = _bleManager.connectedDevices;
    _connectedDevices.addAll(currentDevices);

    // 为每个已连接的设备发送时间同步
    for (final device in currentDevices) {
      await _sendTimeSyncToDevice(device.id);
    }

    debugPrint('[MessageForwarder] 服务启动完成，已连接设备: ${_connectedDevices.length}');
  }

  /// 停止消息转发服务
  Future<void> stop() async {
    if (!_isRunning) {
      return;
    }

    debugPrint('[MessageForwarder] 停止消息转发服务');
    _isRunning = false;

    // 取消所有订阅
    await _messageSubscription?.cancel();
    await _deviceSubscription?.cancel();

    _messageSubscription = null;
    _deviceSubscription = null;

    _connectedDevices.clear();

    debugPrint('[MessageForwarder] 服务已停止');
  }

  /// 处理新消息
  void _handleNewMessages(List<MessageResponse> messages) {
    if (!_isRunning || _connectedDevices.isEmpty) {
      return;
    }

    debugPrint('[MessageForwarder] 收到 ${messages.length} 条新消息');

    for (final message in messages) {
      _forwardMessageToDevices(message);
    }
  }

  /// 转发消息到所有连接的设备
  Future<void> _forwardMessageToDevices(MessageResponse message) async {
    if (_connectedDevices.isEmpty) {
      return;
    }

    debugPrint('[MessageForwarder] 转发消息到 ${_connectedDevices.length} 个设备');

    for (final device in _connectedDevices) {
      try {
        // 使用发送人ID和消息内容分开传输
        await _bleProtocolService.sendTextMessage(
          device.id,
          message.senderBipupuId, // 发送人ID
          message.content, // 消息内容
        );

        debugPrint('[MessageForwarder] 消息转发成功: ${device.name}');
      } catch (e) {
        debugPrint('[MessageForwarder] 转发消息失败: ${device.name}, $e');
      }
    }
  }

  /// 处理设备更新
  void _handleDeviceUpdate(List<BleDevice> devices) {
    if (!_isRunning) {
      return;
    }

    // 找出新连接的设备
    final newDevices = devices
        .where(
          (device) =>
              !_connectedDevices.any((existing) => existing.id == device.id),
        )
        .toList();

    // 找出断开的设备
    final disconnectedDevices = _connectedDevices
        .where(
          (device) => !devices.any((newDevice) => newDevice.id == device.id),
        )
        .toList();

    // 处理断开连接的设备
    for (final device in disconnectedDevices) {
      debugPrint('[MessageForwarder] 设备断开: ${device.name}');
    }

    // 处理新连接的设备
    for (final device in newDevices) {
      debugPrint('[MessageForwarder] 设备连接: ${device.name}');
      _sendTimeSyncToDevice(device.id);
    }

    // 更新设备列表
    _connectedDevices.clear();
    _connectedDevices.addAll(devices);

    debugPrint(
      '[MessageForwarder] 设备更新: 总数=${devices.length}, 新增=${newDevices.length}, 断开=${disconnectedDevices.length}',
    );
  }

  /// 向设备发送时间同步
  Future<void> _sendTimeSyncToDevice(String deviceId) async {
    try {
      await _bleProtocolService.sendTimeSync(deviceId);
      debugPrint('[MessageForwarder] 时间同步已发送到设备: $deviceId');
    } catch (e) {
      debugPrint('[MessageForwarder] 时间同步失败: $e');
    }
  }

  /// 手动发送时间同步到所有设备
  Future<void> syncTimeToAllDevices() async {
    if (!_isRunning) {
      debugPrint('[MessageForwarder] 服务未运行，无法同步时间');
      return;
    }

    debugPrint('[MessageForwarder] 手动触发时间同步到所有设备');

    for (final device in _connectedDevices) {
      await _sendTimeSyncToDevice(device.id);
    }
  }

  /// 获取服务状态
  Map<String, dynamic> getStatus() {
    return {
      'isRunning': _isRunning,
      'connectedDevices': _connectedDevices.length,
      'devices': _connectedDevices.map((device) {
        return {
          'id': device.id,
          'name': device.name,
          'isConnected': device.isConnected,
        };
      }).toList(),
    };
  }

  /// 释放所有资源
  Future<void> dispose() async {
    await stop();
    _bleProtocolService.dispose();
    debugPrint('[MessageForwarder] 所有资源已释放');
  }
}
