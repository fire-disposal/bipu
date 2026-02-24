import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/message_model.dart';
import '../api/dio_client.dart';

/// 消息流提供者 - UI 层订阅此流以获取实时消息
final messageStreamProvider = StreamProvider<List<MessageResponse>>((ref) {
  final pollingService = ref.watch(pollingServiceProvider);
  return pollingService.messageStream;
});

/// 长轮询服务提供者
final pollingServiceProvider = Provider<PollingService>((ref) {
  final dio = ref.read(pollingDioClientProvider);
  return PollingService(dio: dio);
});

/// 轮询状态
enum PollingStatus {
  /// 空闲（未开始或已停止）
  idle,

  /// 正在轮询
  polling,

  /// 暂停（App 在后台）
  paused,

  /// 错误状态
  error,
}

/// 长轮询消息拉取引擎
///
/// 核心逻辑：
/// 1. 基于长轮询模拟实时消息推送
/// 2. 监听 App 生命周期，后台时降级为每分钟一次
/// 3. 将新消息推送到 messageStream
///
/// API 端点：GET /api/messages/poll
/// 参数：
/// - last_msg_id: 最后收到的消息 ID
/// - timeout: 超时时间（秒），默认 30
class PollingService {
  final Dio _dio;

  PollingService({required Dio dio}) : _dio = dio;

  /// 消息流控制器
  final _messageStreamController =
      StreamController<List<MessageResponse>>.broadcast();

  /// 消息流 - UI 层订阅此流
  Stream<List<MessageResponse>> get messageStream =>
      _messageStreamController.stream;

  /// 当前轮询状态
  PollingStatus _status = PollingStatus.idle;
  PollingStatus get status => _status;

  /// 状态变化流
  final _statusController = StreamController<PollingStatus>.broadcast();
  Stream<PollingStatus> get statusStream => _statusController.stream;

  /// 最后一次消息 ID（用于增量拉取）
  int? _lastMessageId;

  /// 轮询间隔（毫秒）
  /// - 前台：立即轮询（收到响应后立刻发起下一次）
  /// - 后台：60000ms（每分钟一次）
  Duration _pollingInterval = Duration.zero;

  /// 是否正在运行
  bool _isRunning = false;

  /// 取消令牌（用于取消当前轮询请求）
  CancelToken? _currentCancelToken;

  /// 启动轮询服务
  Future<void> start() async {
    if (_isRunning) return;

    debugPrint('[PollingService] 启动轮询服务');
    _isRunning = true;
    _status = PollingStatus.polling;
    _statusController.add(_status);

    // 从本地存储获取最后消息 ID
    await _loadLastMessageId();

    // 开始轮询
    _pollLoop();
  }

  /// 停止轮询服务
  Future<void> stop() async {
    if (!_isRunning) return;

    debugPrint('[PollingService] 停止轮询服务');
    _isRunning = false;
    _status = PollingStatus.idle;
    _statusController.add(_status);

    // 取消当前请求
    _currentCancelToken?.cancel();
  }

  /// 暂停轮询（App 进入后台）
  void pause() {
    if (!_isRunning) return;

    debugPrint('[PollingService] 暂停轮询（后台模式）');
    _status = PollingStatus.paused;
    _statusController.add(_status);
    _pollingInterval = const Duration(milliseconds: 60000); // 降级为每分钟一次

    // 取消当前请求，等待下次轮询
    _currentCancelToken?.cancel();
  }

  /// 恢复轮询（App 回到前台）
  void resume() {
    if (!_isRunning) return;

    debugPrint('[PollingService] 恢复轮询（前台模式）');
    _status = PollingStatus.polling;
    _statusController.add(_status);
    _pollingInterval = Duration.zero; // 立即轮询

    // 立即发起一次轮询
    _pollLoop();
  }

  /// 轮询循环
  Future<void> _pollLoop() async {
    while (_isRunning) {
      // 如果间隔大于 0，等待
      if (_pollingInterval.inMilliseconds > 0) {
        await Future.delayed(_pollingInterval);
      }

      // 如果已停止，退出循环
      if (!_isRunning) break;

      // 发起轮询请求
      await _pollOnce();
    }
  }

  /// 执行单次轮询请求
  ///
  /// 使用新 API：GET /api/messages/poll?last_msg_id={id}&timeout=30
  Future<void> _pollOnce() async {
    if (_status != PollingStatus.polling) return;

    _currentCancelToken = CancelToken();

    try {
      final lastMsgId = _lastMessageId ?? 0;
      debugPrint('[PollingService] 发起轮询请求，last_msg_id: $lastMsgId');

      // 调用新长轮询 API
      final response = await _dio.get<List>(
        '/api/messages/poll',
        queryParameters: {
          'last_msg_id': lastMsgId,
          'timeout': 30, // 30 秒超时
        },
        cancelToken: _currentCancelToken,
      );

      if (response.statusCode == 200 && response.data != null) {
        final messages = response.data!;

        if (messages.isNotEmpty) {
          debugPrint('[PollingService] 收到 ${messages.length} 条新消息');

          // 解析消息
          final newMessages = messages
              .map(
                (msg) => MessageResponse.fromJson(msg as Map<String, dynamic>),
              )
              .toList();

          // 推送到流
          _messageStreamController.add(newMessages);

          // 更新最后消息 ID
          final lastMsg = newMessages.last;
          _lastMessageId = lastMsg.id;
          await _saveLastMessageId();
        } else {
          debugPrint('[PollingService] 无新消息（空数组）');
        }
      }
    } on DioException catch (e) {
      // 如果是取消请求，忽略
      if (e.type == DioExceptionType.cancel) {
        debugPrint('[PollingService] 请求被取消');
        return;
      }

      // 超时是正常的（长轮询机制）
      if (e.type == DioExceptionType.receiveTimeout) {
        debugPrint('[PollingService] 轮询超时（正常）');
        return;
      }

      // 其他错误
      debugPrint('[PollingService] 轮询错误：${e.message}');
      _status = PollingStatus.error;
      _statusController.add(_status);

      // 等待一段时间后重试
      await Future.delayed(const Duration(seconds: 5));
      _status = PollingStatus.polling;
      _statusController.add(_status);
    } catch (e) {
      debugPrint('[PollingService] 未知错误：$e');
    }
  }

  /// 从本地存储加载最后消息 ID
  Future<void> _loadLastMessageId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastMessageId = prefs.getInt('last_message_id');
      debugPrint('[PollingService] 加载最后消息 ID: $_lastMessageId');
    } catch (e) {
      debugPrint('[PollingService] 加载最后消息 ID 失败：$e');
    }
  }

  /// 保存最后消息 ID 到本地存储
  Future<void> _saveLastMessageId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_message_id', _lastMessageId ?? 0);
    } catch (e) {
      debugPrint('[PollingService] 保存最后消息 ID 失败：$e');
    }
  }

  /// 释放资源
  void dispose() {
    stop();
    _messageStreamController.close();
    _statusController.close();
  }
}
