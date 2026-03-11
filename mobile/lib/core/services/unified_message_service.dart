import 'dart:async';
import 'dart:developer';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/io.dart';

import '../config/app_config.dart';
import '../network/network.dart';
import '../api/models/message_response.dart';
import '../api/models/message_type.dart';
import '../api/models/message_create.dart';
import 'auth_service.dart';
import 'background_service.dart';
import 'toast_service.dart';

/// 统一消息服务 - 集成WebSocket和长轮询的智能消息传递系统
class UnifiedMessageService extends ChangeNotifier {
  static final UnifiedMessageService _instance =
      UnifiedMessageService._internal();
  factory UnifiedMessageService() => _instance;
  UnifiedMessageService._internal();

  // 依赖服务
  final AuthService _authService = AuthService();
  final Connectivity _connectivity = Connectivity();

  // 状态管理
  StreamSubscription<dynamic>? _connectivitySub;
  VoidCallback? _authListener;
  bool _isOnline = true;
  bool _isRunning = false;

  // WebSocket相关
  IOWebSocketChannel? _webSocketChannel;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  // 长轮询相关
  late Dio _pollingDio;
  bool _isPollingActive = false;
  bool _isStarting = false;

  // 消息存储
  List<MessageResponse> _receivedMessages = [];
  List<MessageResponse> _sentMessages = [];
  Set<int> _cachedReadIds = {};
  int _lastReceivedMessageId = 0;
  int _lastSentMessageId = 0;

  // 存储配置
  static const String _imSettingsBoxName = 'unified_im_settings_box';
  static const String _lastReceivedMsgIdKey = 'last_received_msg_id';
  static const String _readMessageIdsKey = 'read_message_ids';
  Box? _imSettingsBox;

  // 应用状态
  bool _isInForeground = true;
  Timer? _backgroundTimer;

  // Getters
  List<MessageResponse> get receivedMessages =>
      List.unmodifiable(_receivedMessages);
  List<MessageResponse> get sentMessages => List.unmodifiable(_sentMessages);
  int get unreadCount =>
      _receivedMessages.where((m) => !_cachedReadIds.contains(m.id)).length;
  int get unreadSystemCount => _receivedMessages
      .where(
        (m) =>
            !_cachedReadIds.contains(m.id) &&
            m.messageType == MessageType.system,
      )
      .length;
  int get unreadNormalCount => unreadCount - unreadSystemCount;

  /// 初始化服务
  Future<void> init() async {
    if (_isRunning) return;

    try {
      // 初始化存储
      _imSettingsBox = await Hive.openBox(_imSettingsBoxName);
      _lastReceivedMessageId =
          _imSettingsBox?.get(_lastReceivedMsgIdKey, defaultValue: 0) ?? 0;
      final storedIds =
          _imSettingsBox?.get(_readMessageIdsKey, defaultValue: <int>[]) ?? [];
      _cachedReadIds = (storedIds is List<int>)
          ? storedIds.toSet()
          : (storedIds as List).cast<int>().toSet();

      // 设置监听器
      _setupConnectivityListener();
      _setupAuthListener();

      // 检查初始状态
      if (_authService.authState.value == AuthStatus.authenticated) {
        await start();
      }

      _isRunning = true;
      log('Unified Message Service initialized');
    } catch (e) {
      log('Failed to initialize Unified Message Service: $e');
    }
  }

  /// 启动消息服务
  Future<void> start() async {
    if (!_isOnline ||
        _isStarting ||
        _authService.authState.value != AuthStatus.authenticated) {
      return;
    }

    _isStarting = true;
    try {
      await _fetchInitialMessages();

      // 优先尝试WebSocket连接
      if (await _connectWebSocket()) {
        log('WebSocket connected successfully');
      } else {
        // WebSocket失败，使用长轮询
        _startLongPolling();
        log('Falling back to long polling');
      }

      // 如果在后台，设置后台优化
      if (!_isInForeground) {
        _optimizeForBackground();
      }
    } catch (e) {
      log('Failed to start message service: $e');
      // 尝试长轮询作为备选
      _startLongPolling();
    } finally {
      _isStarting = false;
    }
  }

  /// 停止消息服务
  void stop() {
    _cleanupWebSocket();
    _cleanupLongPolling();
    _isRunning = false;
    log('Unified Message Service stopped');
  }

  /// 连接WebSocket
  Future<bool> _connectWebSocket() async {
    try {
      final token = await TokenManager.getAccessToken();
      if (token == null) return false;

      // WebSocket URL 已包含完整路径
      final wsUrl = '${AppConfig.wsBaseUrl}?token=$token';

      final channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));

      // 用 Completer 等待首条消息或首个错误，确认握手是否真正成功
      final completer = Completer<bool>();

      channel.stream.listen(
        (message) {
          // 收到第一条消息说明握手成功
          if (!completer.isCompleted) completer.complete(true);
          _handleWebSocketMessage(message);
        },
        onError: (error) {
          log('WebSocket error: $error');
          if (!completer.isCompleted) completer.complete(false);
          _cleanupWebSocket();
          // 握手失败时触发 fallback
          _reconnectAttempts++;
          if (_reconnectAttempts > _maxReconnectAttempts) {
            _startLongPolling();
          }
        },
        onDone: () {
          log('WebSocket connection closed');
          if (!completer.isCompleted) completer.complete(false);
          _cleanupWebSocket();
          _reconnectAttempts++;
          if (_reconnectAttempts <= _maxReconnectAttempts) {
            _scheduleReconnect();
          } else {
            // 切换到长轮询
            _startLongPolling();
          }
        },
        cancelOnError: true,
      );

      // 等待握手结果（最多 10 秒）
      final connected = await completer.future.timeout(
        AppConfig.websocketConnectTimeout,
        onTimeout: () {
          log('WebSocket handshake timed out');
          channel.sink.close();
          return false;
        },
      );

      if (!connected) return false;

      _webSocketChannel = channel;
      // 启动心跳
      _startHeartbeat();
      _reconnectAttempts = 0;
      return true;
    } catch (e) {
      log('WebSocket connection failed: $e');
      return false;
    }
  }

  /// 处理WebSocket消息
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message.toString());
      if (data['type'] == 'new_message') {
        final messageData = data['message'];
        final msg = MessageResponse.fromJson(messageData);
        _addReceivedMessage(msg);
      }
    } catch (e) {
      log('Failed to parse WebSocket message: $e');
    }
  }

  /// 处理WebSocket错误
  void _handleWebSocketError(Object error) {
    log('WebSocket error: $error');
    _cleanupWebSocket();
  }

  /// 启动心跳机制
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_webSocketChannel != null) {
        try {
          _webSocketChannel!.sink.add(jsonEncode({'type': 'ping'}));
        } catch (e) {
          log('Failed to send heartbeat: $e');
          _cleanupWebSocket();
        }
      }
    });
  }

  /// 安排重连
  void _scheduleReconnect() {
    final delay = Duration(seconds: 2 * _reconnectAttempts);
    Timer(delay, () {
      if (_isOnline &&
          _authService.authState.value == AuthStatus.authenticated) {
        _connectWebSocket();
      }
    });
  }

  /// 清理WebSocket资源
  void _cleanupWebSocket() {
    _heartbeatTimer?.cancel();
    _webSocketChannel?.sink.close();
    _webSocketChannel = null;
  }

  /// 启动长轮询
  void _startLongPolling() {
    if (_isPollingActive) return;

    _initializePollingDio();
    _isPollingActive = true;
    _performLongPolling();
  }

  /// 初始化长轮询Dio实例
  void _initializePollingDio() {
    final baseOptions = BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 45),
      sendTimeout: Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) {
        return status == null ||
            (status >= 200 && status < 300) ||
            status == 408;
      },
    );

    _pollingDio = Dio(baseOptions);
    _pollingDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await TokenManager.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (e) {
            log('Failed to add token to polling request: $e');
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            log('Polling encountered 401 error, stopping service');
            stop();
          }
          handler.next(error);
        },
      ),
    );
  }

  /// 执行长轮询
  void _performLongPolling() {
    _startSequentialPolling();
  }

  /// 顺序执行长轮询
  Future<void> _startSequentialPolling() async {
    int retryCount = 0;
    const maxRetries = 3;
    const baseRetryDelay = Duration(seconds: 1);

    while (_isPollingActive &&
        _isOnline &&
        _authService.authState.value == AuthStatus.authenticated) {
      try {
        final response = await _pollingDio.get<Map<String, dynamic>>(
          '/api/messages/poll',
          queryParameters: {
            'last_msg_id': _lastReceivedMessageId,
            'timeout': 30,
          },
        );

        retryCount = 0;
        final data = response.data ?? {};
        final messages = (data['messages'] as List<dynamic>?) ?? [];

        if (messages.isNotEmpty) {
          final newMessages = messages
              .map(
                (msg) => MessageResponse.fromJson(msg as Map<String, dynamic>),
              )
              .toList();
          _addReceivedMessages(newMessages);
          log('✓ Long polling received ${newMessages.length} new messages');
        }
      } catch (e) {
        if (e is DioException) {
          if (e.response?.statusCode == 401) {
            log('✗ Polling detected unauthorized (401), stopping service');
            stop();
            return;
          }

          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout) {
            log('⏱ Polling timeout (normal), continuing');
            continue;
          }
        }

        retryCount++;
        if (retryCount > maxRetries) {
          log('✗ Max retries exceeded, stopping polling');
          _isPollingActive = false;
          return;
        }

        final delay = baseRetryDelay * (1 << (retryCount - 1));
        await Future.delayed(delay);
      }
    }
  }

  /// 清理长轮询资源
  void _cleanupLongPolling() {
    _isPollingActive = false;
    try {
      _pollingDio.close();
    } catch (e) {
      log('Failed to close polling Dio: $e');
    }
  }

  /// 获取初始消息
  Future<void> _fetchInitialMessages() async {
    try {
      final apiClient = ApiClient.instance;
      final inboxResponse = await apiClient.execute(
        () => apiClient.api.messages.getApiMessagesInbox(
          page: 1,
          pageSize: 50,
          sinceId: 0,
        ),
        operationName: 'FetchInitialMessages',
      );

      if (inboxResponse.messages.isNotEmpty) {
        _receivedMessages = List.from(inboxResponse.messages);
        final maxId = inboxResponse.messages
            .map((m) => m.id)
            .reduce((a, b) => a > b ? a : b);
        _updateLastReceivedMessageId(maxId);
      }
      notifyListeners();
    } catch (e) {
      log('Failed to fetch initial messages: $e');
    }
  }

  /// 添加接收到的消息
  void _addReceivedMessage(MessageResponse message) {
    _receivedMessages.insert(0, message);
    if (message.id > _lastReceivedMessageId) {
      _updateLastReceivedMessageId(message.id);
    }
    notifyListeners();

    // 前台时弹出 in-app 提示
    if (_isInForeground) {
      ToastService().showMessage('📨 来自 ${message.senderBipupuId} 的新消息');
    }

    // 同步到后台服务，避免重复通知
    unawaited(BackgroundMessageService.syncLastMessageId(message.id));
  }

  /// 批量添加接收到的消息
  void _addReceivedMessages(List<MessageResponse> messages) {
    _receivedMessages.insertAll(0, messages);
    final maxId = messages.map((m) => m.id).reduce((a, b) => a > b ? a : b);
    _updateLastReceivedMessageId(maxId);
    notifyListeners();

    // 前台时弹出 in-app 提示
    if (_isInForeground) {
      if (messages.length == 1) {
        ToastService().showMessage(
          '📨 来自 ${messages.first.senderBipupuId} 的新消息',
        );
      } else {
        ToastService().showMessage('📨 收到 ${messages.length} 条新消息');
      }
    }

    // 同步到后台服务
    unawaited(BackgroundMessageService.syncLastMessageId(maxId));
  }

  /// 更新最后接收的消息ID
  void _updateLastReceivedMessageId(int newId) {
    if (newId > _lastReceivedMessageId) {
      _lastReceivedMessageId = newId;
      _imSettingsBox?.put(_lastReceivedMsgIdKey, _lastReceivedMessageId);
    }
  }

  /// 标记消息为未读
  Future<void> markAsUnread(int messageId) async {
    try {
      if (_cachedReadIds.remove(messageId)) {
        await _imSettingsBox?.put(_readMessageIdsKey, _cachedReadIds.toList());
        notifyListeners();
      }
    } catch (e) {
      log('Failed to mark message as unread: $e');
    }
  }

  /// 标记消息为已读
  Future<void> markAsRead(int messageId) async {
    try {
      if (_cachedReadIds.add(messageId)) {
        await _imSettingsBox?.put(_readMessageIdsKey, _cachedReadIds.toList());
        notifyListeners();
      }
    } catch (e) {
      log('Failed to mark message as read: $e');
    }
  }

  /// 批量标记消息为已读
  Future<void> markAsReadBatch(List<int> messageIds) async {
    try {
      final sizeBefore = _cachedReadIds.length;
      _cachedReadIds.addAll(messageIds);
      if (_cachedReadIds.length != sizeBefore) {
        await _imSettingsBox?.put(_readMessageIdsKey, _cachedReadIds.toList());
        notifyListeners();
      }
    } catch (e) {
      log('Failed to batch mark messages as read: $e');
    }
  }

  /// 检查消息是否已读
  bool isMessageRead(int messageId) => _cachedReadIds.contains(messageId);

  /// 获取收藏列表
  Future<Map<String, dynamic>> getFavorites({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final apiClient = ApiClient.instance;
      final response = await apiClient.execute(
        () => apiClient.api.messages.getApiMessagesFavorites(
          page: page,
          pageSize: pageSize,
        ),
        operationName: 'GetFavorites',
      );

      return {
        'favorites': response.favorites,
        'total': response.total,
        'page': response.page,
        'page_size': response.pageSize,
      };
    } catch (e) {
      log('Failed to get favorites: $e');
      rethrow;
    }
  }

  /// 收藏消息
  Future<dynamic> addFavorite(int messageId, {String? note}) async {
    try {
      final apiClient = ApiClient.instance;
      final favoriteData = FavoriteCreate(note: note ?? '');
      final response = await apiClient.execute(
        () => apiClient.api.messages.postApiMessagesMessageIdFavorite(
          messageId: messageId,
          body: favoriteData,
        ),
        operationName: 'AddFavorite',
      );
      return response;
    } catch (e) {
      log('Failed to add favorite: $e');
      rethrow;
    }
  }

  /// 取消收藏消息
  Future<void> removeFavorite(int messageId) async {
    try {
      final apiClient = ApiClient.instance;
      await apiClient.execute(
        () => apiClient.api.messages.deleteApiMessagesMessageIdFavorite(
          messageId: messageId,
        ),
        operationName: 'RemoveFavorite',
      );
    } catch (e) {
      log('Failed to remove favorite: $e');
      rethrow;
    }
  }

  /// 发送消息
  Future<MessageResponse> sendMessage({
    required String receiverId,
    required String content,
    MessageType messageType = MessageType.normal,
    dynamic pattern,
    List<int>? waveform,
  }) async {
    try {
      final apiClient = ApiClient.instance;
      final messageCreate = MessageCreate(
        receiverId: receiverId,
        content: content,
        messageType: messageType,
        pattern: pattern,
        waveform: waveform,
      );

      final response = await apiClient.execute(
        () => apiClient.api.messages.postApiMessages(body: messageCreate),
        operationName: 'SendMessage',
      );

      _sentMessages.insert(0, response);
      notifyListeners();
      return response;
    } catch (e) {
      log('Failed to send message: $e');
      rethrow;
    }
  }

  /// 获取消息（兼容现有接口）
  Future<Map<String, dynamic>> getMessages({
    required String direction,
    int page = 1,
    int pageSize = 20,
    bool forceRefresh = false,
  }) async {
    try {
      final apiClient = ApiClient.instance;

      if (direction == 'sent') {
        final response = await apiClient.execute(
          () => apiClient.api.messages.getApiMessagesSent(
            page: page,
            pageSize: pageSize,
            sinceId: forceRefresh ? 0 : _lastSentMessageId,
          ),
          operationName: 'GetSentMessages',
        );

        if (page == 1) {
          _sentMessages = List.from(response.messages);
          if (response.messages.isNotEmpty) {
            final maxId = response.messages
                .map((m) => m.id)
                .reduce((a, b) => a > b ? a : b);
            _lastSentMessageId = maxId;
          }
          notifyListeners();
        }

        return {
          'messages': response.messages,
          'total': response.total,
          'page': response.page,
          'page_size': response.pageSize,
        };
      } else {
        final response = await apiClient.execute(
          () => apiClient.api.messages.getApiMessagesInbox(
            page: page,
            pageSize: pageSize,
            sinceId: forceRefresh ? 0 : _lastReceivedMessageId,
          ),
          operationName: 'GetReceivedMessages',
        );

        if (page == 1) {
          _receivedMessages = List.from(response.messages);
          if (response.messages.isNotEmpty) {
            final maxId = response.messages
                .map((m) => m.id)
                .reduce((a, b) => a > b ? a : b);
            _updateLastReceivedMessageId(maxId);
          }
          notifyListeners();
        }

        return {
          'messages': response.messages,
          'total': response.total,
          'page': response.page,
          'page_size': response.pageSize,
        };
      }
    } catch (e) {
      log('Failed to get messages: $e');
      rethrow;
    }
  }

  /// 优化后台运行
  void _optimizeForBackground() {
    // 在后台时，如果使用长轮询，可以调整超时时间
    if (_isPollingActive) {
      // 长轮询已经在运行，保持现有配置
    }

    // 设置后台定时器，定期检查是否需要唤醒
    _backgroundTimer?.cancel();
    _backgroundTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (!_isInForeground &&
          _isOnline &&
          _authService.authState.value == AuthStatus.authenticated) {
        // 可以在这里添加后台优化逻辑
        log('Background optimization check');
      }
    });
  }

  /// 设置网络监听器
  void _setupConnectivityListener() {
    _connectivitySub?.cancel();
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final isOnlineNow = !results.contains(ConnectivityResult.none);
      final wasOnline = _isOnline;
      _isOnline = isOnlineNow;

      if (_isOnline && !wasOnline) {
        // 网络恢复，重新启动服务
        start();
      } else if (!_isOnline && wasOnline) {
        // 网络断开，停止服务
        stop();
      }
    });
  }

  /// 设置认证监听器
  void _setupAuthListener() {
    _authListener = () {
      final status = _authService.authState.value;
      if (status == AuthStatus.authenticated) {
        if (_isOnline) {
          start();
        }
      } else {
        stop();
      }
    };
    _authService.authState.addListener(_authListener!);
  }

  /// 设置应用前台/后台状态
  void setForegroundState(bool isInForeground) {
    if (_isInForeground == isInForeground) return;

    _isInForeground = isInForeground;

    if (_isInForeground) {
      // 回到前台，确保服务运行
      if (_authService.authState.value == AuthStatus.authenticated &&
          _isOnline) {
        start();
      }
      _backgroundTimer?.cancel();
    } else {
      // 进入后台，优化资源使用
      _optimizeForBackground();
    }
  }

  @override
  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    _authListener?.call();
    _authListener = null;
    _backgroundTimer?.cancel();
    stop();
    await _imSettingsBox?.close();
    super.dispose();
  }
}
