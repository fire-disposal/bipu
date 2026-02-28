import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'unified_bluetooth_protocol.dart';

/// 蓝牙设备服务 - 增强版
///
/// 特点：
/// 1. 使用单一统合协议 (0xB0) 处理所有通信
/// 2. 在消息转发的同时完成时间同步
/// 3. 支持多种消息类型
/// 4. 自动重连机制，提高连接稳定性
/// 5. 连接状态管理优化
/// 6. 完善的错误处理和恢复机制
class BluetoothDeviceService {
  static final BluetoothDeviceService _instance =
      BluetoothDeviceService._internal();
  factory BluetoothDeviceService() => _instance;
  BluetoothDeviceService._internal();

  // ========== 协议服务 ==========
  final UnifiedBluetoothProtocol _protocol = UnifiedBluetoothProtocol();

  // ========== 连接状态 ==========
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _nusTxCharacteristic;
  String? _lastConnectedDeviceId;
  DateTime? _lastConnectionTime;

  // ========== 订阅管理 ==========
  final _subscriptions = <StreamSubscription<dynamic>>[];
  bool _isDisposing = false;
  bool _isReconnecting = false;
  Timer? _reconnectTimer;

  // ========== 配置参数 ==========
  static const Duration _connectionTimeout = Duration(seconds: 15);
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const int _maxReconnectAttempts = 3;
  int _reconnectAttempts = 0;

  // ========== 状态通知 ==========
  final ValueNotifier<BluetoothConnectionState> connectionState = ValueNotifier(
    BluetoothConnectionState.disconnected,
  );

  final ValueNotifier<String> connectionStatus = ValueNotifier('未连接');
  final ValueNotifier<int> signalStrength = ValueNotifier(0);
  final ValueNotifier<bool> isReconnecting = ValueNotifier(false);

  // ========== 数据接收 ==========
  final ValueNotifier<Map<String, dynamic>?> _receivedPacket = ValueNotifier(
    null,
  );
  final StreamController<Map<String, dynamic>> _packetStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onPacketReceived =>
      _packetStreamController.stream;

  // ========== 连接状态事件 ==========
  final StreamController<BluetoothConnectionState>
  _connectionStateStreamController =
      StreamController<BluetoothConnectionState>.broadcast();

  /// 连接状态变化事件流
  Stream<BluetoothConnectionState> get onConnectionStateChanged =>
      _connectionStateStreamController.stream;

  // ========== 公共方法 ==========

  /// 连接到蓝牙设备（增强版）
  Future<void> connect(BluetoothDevice device) async {
    if (_isDisposing) {
      throw StateError('服务正在关闭，无法连接');
    }

    // 如果正在重连，先停止重连
    _stopReconnectTimer();

    // 如果已连接相同设备，直接返回
    if (_connectedDevice?.remoteId == device.remoteId &&
        connectionState.value == BluetoothConnectionState.connected) {
      if (kDebugMode) {
        print('已连接到设备: ${device.remoteId}');
      }
      return;
    }

    // 清理现有连接
    await _cleanupExistingConnection();

    try {
      // 更新连接状态
      connectionStatus.value = '正在连接...';
      isReconnecting.value = false;

      // 设置连接监听
      _setupConnectionListener(device);

      // 发起物理连接
      await device.connect(
        license: License.free,
        timeout: _connectionTimeout,
        autoConnect: false,
      );

      // 保存连接信息
      _connectedDevice = device;
      _lastConnectedDeviceId = device.remoteId.str;
      _lastConnectionTime = DateTime.now();
      _reconnectAttempts = 0;

      // 启动初始化流程
      await _runSequentialSetup(device);

      if (kDebugMode) {
        print('蓝牙连接成功: ${device.remoteId}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('蓝牙连接失败: $e');
      }

      // 连接失败，尝试重连
      if (_lastConnectedDeviceId != null && !_isDisposing) {
        _scheduleReconnect();
      }

      await _cleanupInternalState();
      rethrow;
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    _stopReconnectTimer();
    isReconnecting.value = false;

    if (_connectedDevice != null) {
      try {
        connectionStatus.value = '正在断开...';
        await _connectedDevice!.disconnect();

        if (kDebugMode) {
          print('蓝牙已断开连接');
        }
      } catch (e) {
        if (kDebugMode) {
          print('断开连接时出错: $e');
        }
      }
    }

    await _cleanupInternalState();
  }

  /// 发送文本消息
  Future<void> sendTextMessage(String text) async {
    if (!isConnected || _nusTxCharacteristic == null) {
      throw StateError('蓝牙未连接或特征值未找到');
    }

    try {
      final packet = _protocol.createTextPacket(text);

      await _nusTxCharacteristic!.write(
        packet,
        withoutResponse: _nusTxCharacteristic!.properties.writeWithoutResponse,
      );

      if (kDebugMode) {
        print('文本消息已发送: "$text"');
      }
    } catch (e) {
      if (kDebugMode) {
        print('发送文本消息失败: $e');
      }

      // 发送失败，检查连接状态
      _checkConnectionHealth();
      rethrow;
    }
  }

  /// 发送时间同步
  Future<void> sendTimeSync() async {
    if (!isConnected || _nusTxCharacteristic == null) {
      throw StateError('蓝牙未连接或特征值未找到');
    }

    try {
      final packet = _protocol.createTimeSyncPacket();

      await _nusTxCharacteristic!.write(
        packet,
        withoutResponse: _nusTxCharacteristic!.properties.writeWithoutResponse,
      );

      if (kDebugMode) {
        print('时间同步已发送');
      }
    } catch (e) {
      if (kDebugMode) {
        print('发送时间同步失败: $e');
      }
      rethrow;
    }
  }

  /// 安全发送消息（带连接检查）
  Future<bool> safeSendTextMessage(String text) async {
    if (!isConnected || _nusTxCharacteristic == null) {
      if (kDebugMode) {
        print('蓝牙未连接，跳过消息发送');
      }
      return false;
    }

    try {
      await sendTextMessage(text);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('安全发送消息失败: $e');
      }
      return false;
    }
  }

  /// 安全发送时间同步
  Future<bool> safeSendTimeSync() async {
    if (!isConnected || _nusTxCharacteristic == null) {
      if (kDebugMode) {
        print('蓝牙未连接，跳过时间同步');
      }
      return false;
    }

    try {
      await sendTimeSync();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('安全发送时间同步失败: $e');
      }
      return false;
    }
  }

  /// 获取连接信息
  Map<String, dynamic> getConnectionInfo() {
    return {
      'isConnected': isConnected,
      'deviceId': _connectedDevice?.remoteId,
      'deviceName': _connectedDevice?.platformName,
      'connectionState': connectionState.value.toString(),
      'connectionStatus': connectionStatus.value,
      'signalStrength': signalStrength.value,
      'lastConnectionTime': _lastConnectionTime?.toIso8601String(),
      'reconnectAttempts': _reconnectAttempts,
      'isReconnecting': isReconnecting.value,
    };
  }

  /// 获取协议信息
  Map<String, dynamic> getProtocolInfo() {
    return _protocol.getProtocolInfo();
  }

  // ========== 属性访问器 ==========

  bool get isConnected =>
      connectionState.value == BluetoothConnectionState.connected;

  BluetoothDevice? get connectedDevice => _connectedDevice;

  UnifiedBluetoothProtocol get protocol => _protocol;

  int get maxTextLength => _protocol.getMaxTextLength();

  int calculatePacketSize({String? text, Uint8List? data}) =>
      _protocol.calculatePacketSize(text: text, data: data);

  int get activeSubscriptionCount => _subscriptions.length;

  bool get isDisposing => _isDisposing;

  // ========== 私有方法 ==========

  /// 清理现有连接
  Future<void> _cleanupExistingConnection() async {
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (e) {
        // 忽略断开连接时的错误
      }
    }

    _cancelAllSubscriptions();
    await _cleanupInternalState();
  }

  /// 设置连接状态监听
  void _setupConnectionListener(BluetoothDevice device) {
    final subscription = device.connectionState.listen(
      (state) {
        if (_isDisposing) return;

        connectionState.value = state;

        // 发送连接状态变化事件
        _connectionStateStreamController.add(state);

        // 更新连接状态文本
        switch (state) {
          case BluetoothConnectionState.connected:
            connectionStatus.value = '已连接';
            _reconnectAttempts = 0;
            isReconnecting.value = false;
            break;

          case BluetoothConnectionState.disconnected:
            connectionStatus.value = '未连接';

            // 如果是意外断开，尝试重连
            if (_lastConnectedDeviceId != null &&
                !_isReconnecting &&
                !_isDisposing) {
              _scheduleReconnect();
            }
            break;

          // 处理其他可能的状态（已弃用但需要处理）
          default:
            // 对于已弃用的状态，使用默认处理
            connectionStatus.value = '连接中...';
            break;
        }

        if (kDebugMode) {
          print('蓝牙连接状态更新: $state');
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('连接监听错误: $error');
        }

        if (!_isDisposing) {
          _scheduleReconnect();
        }
      },
    );

    _subscriptions.add(subscription);
  }

  /// 顺序执行初始化流程
  Future<void> _runSequentialSetup(BluetoothDevice device) async {
    try {
      // 1. 发现服务
      connectionStatus.value = '发现服务...';
      final services = await device.discoverServices();

      // 2. 查找 Nordic UART Service
      connectionStatus.value = '查找特征值...';
      final nusService = services.firstWhere(
        (service) =>
            service.uuid.toString().toLowerCase() ==
            '6e400001-b5a3-f393-e0a9-e50e24dcca9e',
        orElse: () => throw StateError('未找到 NUS 服务'),
      );

      // 3. 查找 TX 特征值
      _nusTxCharacteristic = nusService.characteristics.firstWhere(
        (characteristic) =>
            characteristic.uuid.toString().toLowerCase() ==
            '6e400002-b5a3-f393-e0a9-e50e24dcca9e',
        orElse: () => throw StateError('未找到 TX 特征值'),
      );

      // 4. 设置接收监听
      connectionStatus.value = '设置接收监听...';
      await _setupReceiveListener();

      // 5. 发送初始时间同步
      connectionStatus.value = '同步时间...';
      await sendTimeSync();

      connectionStatus.value = '准备就绪';

      if (kDebugMode) {
        print('蓝牙初始化完成');
      }
    } catch (e) {
      if (kDebugMode) {
        print('蓝牙初始化失败: $e');
      }

      // 初始化失败，断开连接
      await disconnect();
      rethrow;
    }
  }

  /// 设置数据接收监听
  Future<void> _setupReceiveListener() async {
    if (_nusTxCharacteristic == null) return;

    final subscription = _nusTxCharacteristic!.onValueReceived.listen(
      (value) {
        if (_isDisposing) return;

        try {
          final packet = Uint8List.fromList(value);
          final parsed = _protocol.parsePacket(packet);
          if (parsed != null) {
            _receivedPacket.value = parsed;
            _packetStreamController.add(parsed);

            if (kDebugMode) {
              print('收到蓝牙数据包: ${parsed['messageTypeName']}');
            }

            // 根据消息类型处理
            _processReceivedPacket(parsed);
          }
        } catch (e) {
          if (kDebugMode) {
            print('解析接收数据失败: $e');
          }
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('接收监听错误: $error');
        }
      },
    );

    _subscriptions.add(subscription);
  }

  /// 处理接收到的数据包
  void _processReceivedPacket(Map<String, dynamic> packet) {
    final messageType = packet['messageType'];

    switch (messageType) {
      case UnifiedBluetoothProtocol.MESSAGE_TYPE_TIME_SYNC:
        _handleTimeSync(packet);
        break;
      case UnifiedBluetoothProtocol.MESSAGE_TYPE_TEXT:
        _handleTextMessage(packet);
        break;
      case UnifiedBluetoothProtocol.MESSAGE_TYPE_ACKNOWLEDGEMENT:
        _handleAcknowledgement(packet);
        break;
    }
  }

  /// 处理时间同步
  void _handleTimeSync(Map<String, dynamic> packet) {
    if (kDebugMode) {
      print('收到时间同步: ${packet['timestamp']}');
    }
  }

  /// 处理文本消息
  void _handleTextMessage(Map<String, dynamic> packet) {
    if (kDebugMode) {
      print('收到文本消息: ${packet['text']}');
    }
  }

  /// 处理确认响应
  void _handleAcknowledgement(Map<String, dynamic> packet) {
    if (kDebugMode) {
      print('收到确认响应: ${packet['originalMessageId']}');
    }
  }

  /// 检查连接健康状态
  void _checkConnectionHealth() {
    if (isConnected && _lastConnectionTime != null) {
      final duration = DateTime.now().difference(_lastConnectionTime!);

      // 如果连接时间超过30分钟，主动断开重连
      if (duration > Duration(minutes: 30)) {
        if (kDebugMode) {
          print('连接时间过长，主动重连以保持稳定性');
        }
        _scheduleReconnect();
      }
    }
  }

  /// 安排重连
  void _scheduleReconnect() {
    if (_isDisposing || _isReconnecting || _lastConnectedDeviceId == null) {
      return;
    }

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      if (kDebugMode) {
        print('已达到最大重连次数: $_reconnectAttempts');
      }
      return;
    }

    _reconnectAttempts++;
    _isReconnecting = true;
    isReconnecting.value = true;

    if (kDebugMode) {
      print('安排重连，尝试次数: $_reconnectAttempts');
    }

    _reconnectTimer = Timer(_reconnectDelay, () async {
      if (_isDisposing) return;

      try {
        connectionStatus.value = '正在重连...';

        // 查找设备 - systemDevices需要参数，我们传入空列表获取所有设备
        final devices = await FlutterBluePlus.systemDevices([]);
        BluetoothDevice? foundDevice;

        // 遍历设备列表查找匹配的设备
        for (final device in devices) {
          if (device.remoteId.str == _lastConnectedDeviceId) {
            foundDevice = device;
            break;
          }
        }

        if (foundDevice == null) {
          throw StateError('设备未找到');
        }

        // 重新连接
        await connect(foundDevice);
      } catch (e) {
        if (kDebugMode) {
          print('重连失败: $e');
        }

        // 继续重连
        if (_reconnectAttempts < _maxReconnectAttempts) {
          _scheduleReconnect();
        } else {
          _isReconnecting = false;
          isReconnecting.value = false;
          connectionStatus.value = '连接失败';
        }
      }
    });
  }

  /// 停止重连定时器
  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _isReconnecting = false;
    isReconnecting.value = false;
  }

  /// 取消所有订阅
  void _cancelAllSubscriptions() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  /// 清理内部状态
  Future<void> _cleanupInternalState() async {
    _cancelAllSubscriptions();
    _stopReconnectTimer();

    _connectedDevice = null;
    _nusTxCharacteristic = null;
    _isReconnecting = false;
    _reconnectAttempts = 0;

    connectionState.value = BluetoothConnectionState.disconnected;
    connectionStatus.value = '未连接';
    signalStrength.value = 0;
    isReconnecting.value = false;
    _receivedPacket.value = null;
  }

  /// 销毁服务
  Future<void> dispose() async {
    _isDisposing = true;
    await disconnect();
    _cancelAllSubscriptions();
    _stopReconnectTimer();
    _packetStreamController.close();
    _connectionStateStreamController.close();
  }
}
