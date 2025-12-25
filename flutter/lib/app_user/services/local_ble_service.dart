/// 本地蓝牙发送服务
/// 用于处理消息的本地推送和接收时的设备通知
library;

import 'dart:async';
import '../../core/core.dart';
import '../state/user_data_cubit.dart' as user_data;

/// 本地蓝牙发送服务
class LocalBleService {
  final DeviceControlService _deviceControlService;
  final user_data.UserDataCubit _userDataCubit;

  Timer? _messageCheckTimer;
  final StreamController<MessageEvent> _messageEventController =
      StreamController<MessageEvent>.broadcast();

  /// 消息事件流
  Stream<MessageEvent> get messageEvents => _messageEventController.stream;

  LocalBleService({
    required DeviceControlService deviceControlService,
    required user_data.UserDataCubit userDataCubit,
  }) : _deviceControlService = deviceControlService,
       _userDataCubit = userDataCubit;

  /// 初始化本地蓝牙服务
  Future<void> initialize() async {
    try {
      await _deviceControlService.initialize();
      _startMessageCheckTimer();
      Logger.info('本地蓝牙服务初始化完成');
    } catch (e) {
      Logger.error('本地蓝牙服务初始化失败: $e');
      rethrow;
    }
  }

  /// 开始消息检查定时器
  void _startMessageCheckTimer() {
    _messageCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkForNewMessages();
    });
  }

  /// 检查新消息
  Future<void> _checkForNewMessages() async {
    try {
      // 这里可以实现从本地存储或缓存检查新消息的逻辑
      // 暂时模拟新消息检测
      if (_deviceControlService.isConnected) {
        // 模拟发现新消息，向设备发送通知
        await sendLocalNotification(
          title: '新消息',
          content: '您有新消息，请查看',
          isIncoming: true,
        );
      }
    } catch (e) {
      Logger.error('检查新消息失败: $e');
    }
  }

  /// 发送本地通知到设备
  Future<bool> sendLocalNotification({
    required String title,
    required String content,
    bool isIncoming = false,
    RgbColor color = RgbColor.colorBlue,
    VibrationPattern vibration = VibrationPattern.short,
    VibrationIntensity intensity = VibrationIntensity.medium,
    int duration = 3000,
  }) async {
    if (!_deviceControlService.isConnected) {
      Logger.warning('设备未连接，无法发送本地通知');
      return false;
    }

    try {
      Logger.info('发送本地通知: $title - $content');

      // 根据消息类型选择不同的效果
      if (isIncoming) {
        // 接收消息时使用特殊效果
        await _deviceControlService.sendRgbSequence(
          colors: [RgbColor.colorGreen, RgbColor.colorBlue],
          text: '$title: $content',
          vibration: vibration,
          intensity: intensity,
          duration: duration,
        );
      } else {
        // 主动发送消息
        await _deviceControlService.sendSimpleNotification(
          text: '$title: $content',
          color: color,
          vibration: vibration,
          intensity: intensity,
        );
      }

      // 触发消息事件
      _messageEventController.add(
        MessageEvent(
          type: isIncoming
              ? MessageEventType.incoming
              : MessageEventType.outgoing,
          title: title,
          content: content,
          timestamp: DateTime.now(),
        ),
      );

      // 更新用户数据
      _updateUserDataWithMessage(title, content, isIncoming);

      return true;
    } catch (e) {
      Logger.error('发送本地通知失败: $e');
      return false;
    }
  }

  /// 发送紧急本地通知
  Future<bool> sendUrgentLocalNotification({
    required String title,
    required String content,
    bool isIncoming = false,
  }) async {
    if (!_deviceControlService.isConnected) {
      Logger.warning('设备未连接，无法发送紧急本地通知');
      return false;
    }

    try {
      Logger.info('发送紧急本地通知: $title - $content');

      await _deviceControlService.sendUrgentNotification('$title: $content');

      // 触发消息事件
      _messageEventController.add(
        MessageEvent(
          type: isIncoming
              ? MessageEventType.urgentIncoming
              : MessageEventType.urgentOutgoing,
          title: title,
          content: content,
          timestamp: DateTime.now(),
        ),
      );

      // 更新用户数据
      _updateUserDataWithMessage(title, content, isIncoming);

      return true;
    } catch (e) {
      Logger.error('发送紧急本地通知失败: $e');
      return false;
    }
  }

  /// 发送测试消息到设备
  Future<bool> sendTestMessage({
    String title = '测试消息',
    String content = '这是一条测试消息',
    RgbColor color = RgbColor.colorWhite,
    VibrationPattern vibration = VibrationPattern.short,
  }) async {
    return sendLocalNotification(
      title: title,
      content: content,
      isIncoming: false,
      color: color,
      vibration: vibration,
    );
  }

  /// 发送设备状态通知
  Future<bool> sendDeviceStatusNotification({
    required String status,
    int? batteryLevel,
    bool isCharging = false,
  }) async {
    if (!_deviceControlService.isConnected) {
      return false;
    }

    try {
      String message = '设备状态: $status';
      if (batteryLevel != null) {
        message += ', 电量: $batteryLevel%';
        if (isCharging) {
          message += ' (充电中)';
        }
      }

      await _deviceControlService.sendSimpleNotification(
        text: message,
        color: batteryLevel != null && batteryLevel < 20
            ? RgbColor.colorRed
            : RgbColor.colorGreen,
        vibration: VibrationPattern.short,
      );

      return true;
    } catch (e) {
      Logger.error('发送设备状态通知失败: $e');
      return false;
    }
  }

  /// 更新用户数据中的消息记录
  void _updateUserDataWithMessage(
    String title,
    String content,
    bool isIncoming,
  ) {
    try {
      // 创建消息信息
      final messageInfo = user_data.MessageInfo(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        content: '$title: $content',
        timestamp: DateTime.now(),
        isFavorite: false,
        sender: isIncoming ? '设备' : '本地用户',
        recipient: isIncoming ? '本地用户' : '设备',
        type: user_data.MessageType.notification,
      );

      // 添加到用户数据
      _userDataCubit.addMessage(messageInfo);
    } catch (e) {
      Logger.error('更新用户数据失败: $e');
    }
  }

  /// 检查设备连接状态
  Future<bool> checkDeviceConnection() async {
    return _deviceControlService.isConnected;
  }

  /// 获取连接的设备信息
  String? getConnectedDeviceId() {
    return _deviceControlService.connectedDeviceId;
  }

  /// 断开连接
  Future<void> disconnect() async {
    await _deviceControlService.disconnect();
    _stopMessageCheckTimer();
  }

  /// 停止消息检查定时器
  void _stopMessageCheckTimer() {
    _messageCheckTimer?.cancel();
    _messageCheckTimer = null;
  }

  /// 销毁服务
  void dispose() {
    _stopMessageCheckTimer();
    _messageEventController.close();
  }
}

/// 消息事件
class MessageEvent {
  final MessageEventType type;
  final String title;
  final String content;
  final DateTime timestamp;

  const MessageEvent({
    required this.type,
    required this.title,
    required this.content,
    required this.timestamp,
  });
}

/// 消息事件类型
enum MessageEventType {
  incoming, // 接收消息
  outgoing, // 发送消息
  urgentIncoming, // 紧急接收
  urgentOutgoing, // 紧急发送
  system, // 系统消息
}
