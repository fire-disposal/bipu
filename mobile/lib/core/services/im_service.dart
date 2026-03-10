import 'dart:async';
import 'dart:developer';
import 'package:flutter/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dio/dio.dart';
import '../network/network.dart';

import '../config/app_config.dart';
import 'auth_service.dart';
import 'background_service.dart';
import '../api/models/favorite_create.dart';
import '../api/models/message_create.dart';
import '../api/models/message_type.dart';

/// 统一的 IM 服务 - 优化重写版本（单长轮询）
class ImService extends ChangeNotifier {
  static final ImService _instance = ImService._internal();
  factory ImService() => _instance;
  ImService._internal() {
    _initializeLongPollDio();
  }

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<dynamic>? _connectivitySub;
  final AuthService _authService = AuthService();

  bool _isLongPollingActive = false;
  bool _isStartingPolling = false; // 防止 startPolling() 并发调用竞态
  late final VoidCallback _authListener;
  Set<int> _cachedReadIds = {};

  // 专用的长轮询 Dio 实例和 RestClient
  late Dio _longPollDio;
  late RestClient _longPollRestClient;
  bool _isLongPollDioInitialized = false;

  List<dynamic> _receivedMessages = [];
  List<dynamic> _sentMessages = [];
  int _unreadCount = 0;
  int _unreadSystemCount = 0;
  int _unreadNormalCount = 0;

  int _lastReceivedMessageId = 0;
  int _lastSentMessageId = 0;
  bool _isOnline = true;

  static const String _imSettingsBoxName = 'im_settings_box';
  static const String _lastReceivedMsgIdKey = 'last_received_msg_id';
  static const String _readMessageIdsKey = 'read_message_ids';

  Box? _imSettingsBox;

  List<dynamic> get receivedMessages => List.unmodifiable(_receivedMessages);
  List<dynamic> get sentMessages => List.unmodifiable(_sentMessages);
  int get unreadCount => _unreadCount;
  int get unreadSystemCount => _unreadSystemCount;
  int get unreadNormalCount => _unreadNormalCount;

  /// 获取所有已读消息ID集合（使用内存缓存，避免重复磁盘 IO）
  Set<int> getReadMessageIds() => Set.unmodifiable(_cachedReadIds);

  /// 检查消息是否已读
  bool isMessageRead(int messageId) => _cachedReadIds.contains(messageId);

  /// 标记单条消息为已读
  Future<void> markAsRead(int messageId) async {
    try {
      if (_cachedReadIds.add(messageId)) {
        await _imSettingsBox?.put(_readMessageIdsKey, _cachedReadIds.toList());
        _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      log('标记消息为已读失败: $e');
    }
  }

  /// 标记单条消息为未读
  Future<void> markAsUnread(int messageId) async {
    try {
      if (_cachedReadIds.remove(messageId)) {
        await _imSettingsBox?.put(_readMessageIdsKey, _cachedReadIds.toList());
        _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      log('标记消息为未读失败: $e');
    }
  }

  /// 批量标记消息为已读
  Future<void> markAsReadBatch(List<int> messageIds) async {
    try {
      final sizeBefore = _cachedReadIds.length;
      _cachedReadIds.addAll(messageIds);
      if (_cachedReadIds.length != sizeBefore) {
        await _imSettingsBox?.put(_readMessageIdsKey, _cachedReadIds.toList());
        _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      log('批量标记消息为已读失败: $e');
    }
  }

  Future<void> init() async {
    try {
      _imSettingsBox = await Hive.openBox(_imSettingsBoxName);
      _lastReceivedMessageId =
          _imSettingsBox?.get(_lastReceivedMsgIdKey, defaultValue: 0) ?? 0;
      // 预加载已读 ID 至内存缓存，避免后续每次触发磁盘 IO
      final storedIds =
          _imSettingsBox?.get(_readMessageIdsKey, defaultValue: <int>[]) ?? [];
      _cachedReadIds = (storedIds is List<int>)
          ? storedIds.toSet()
          : (storedIds as List).cast<int>().toSet();
      _setupConnectivityListener();
      _setupAuthListener();
      // 冷启动时 auth 可能已是 authenticated，ValueNotifier 不会重触发，需手动检查
      if (_authService.authState.value == AuthStatus.authenticated &&
          _isOnline) {
        startPolling();
      }
      log('IM Service 初始化完成');
    } catch (e) {
      log('IM Service 初始化失败: $e');
    }
  }

  /// 初始化专用的长轮询 Dio 实例
  void _initializeLongPollDio() {
    // 创建基础配置
    // 🆕 关键优化：超时配置与后端对齐
    // - 后端长轮询超时：30 秒
    // - 前端 receiveTimeout：45 秒（30 + 15秒网络延迟缓冲）
    // - 这样可以确保后端返回时前端能正确接收，避免误判为超时
    final baseOptions = BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: Duration(seconds: 10), // 连接超时 10 秒
      receiveTimeout: Duration(seconds: 45), // 接收超时 45 秒（后端 30s + 缓冲 15s）
      sendTimeout: Duration(seconds: 10), // 发送超时 10 秒
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) {
        // 长轮询需要接受超时状态和正常状态
        return status == null ||
            (status >= 200 && status < 300) ||
            status == 408; // Request Timeout
      },
    );

    _longPollDio = Dio(baseOptions);

    // 添加必要的拦截器
    _longPollDio.interceptors.addAll([
      _createLongPollInterceptor(),
      if (AppConfig.enableApiLogging) _createLongPollLogInterceptor(),
    ]);

    // 创建专用的 RestClient
    _longPollRestClient = RestClient(_longPollDio);
    _isLongPollDioInitialized = true;
  }

  /// 创建长轮询专用的日志拦截器
  LogInterceptor _createLongPollLogInterceptor() {
    return LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
      logPrint: (message) {
        log('🌐 LONGPOLL: $message');
      },
    );
  }

  /// 创建长轮询请求拦截器
  Interceptor _createLongPollInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 手动添加认证 Token
        try {
          final token = await TokenManager.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (e) {
          log('长轮询请求拦截器添加 Token 失败: $e');
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // 处理 401 错误
        if (error.response?.statusCode == 401) {
          log('长轮询遇到 401 错误，停止轮询');
          stopPolling();
        }
        handler.next(error);
      },
    );
  }

  void _setupAuthListener() {
    _authListener = () {
      final status = _authService.authState.value;
      if (status == AuthStatus.authenticated) {
        if (_isOnline) {
          startPolling();
        }
      } else {
        stopPolling();
      }
    };
    _authService.authState.addListener(_authListener);
  }

  void _setupConnectivityListener() {
    _connectivitySub?.cancel();
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final isOnlineNow = !results.contains(ConnectivityResult.none);

      _isOnline = isOnlineNow;
      log('网络状态: ${_isOnline ? "在线" : "离线"}');

      if (_isOnline) {
        startPolling();
      } else {
        stopPolling();
      }
    });
  }

  @override
  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    _cleanupLongPollResources();
    await _imSettingsBox?.close();
    _authService.authState.removeListener(_authListener);
    super.dispose();
  }

  /// 启动轮询
  Future<void> startPolling() async {
    if (!_isOnline ||
        _isLongPollingActive ||
        _isStartingPolling ||
        _authService.authState.value != AuthStatus.authenticated) {
      return;
    }

    _isStartingPolling = true;
    try {
      if (!_isLongPollDioInitialized) {
        _initializeLongPollDio();
      }

      await _fetchInitialMessages();
      _isLongPollingActive = true;
      _performLongPolling();
      log('消息轮询已启动');
    } catch (e) {
      log('启动轮询失败: $e');
    } finally {
      _isStartingPolling = false;
    }
  }

  /// 停止轮询
  void stopPolling() {
    _cleanupLongPollResources();
    log('消息轮询已停止');
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
        _updateUnreadCount();
      }

      notifyListeners();
    } catch (e) {
      log('获取初始消息失败: $e');
    }
  }

  /// 长轮询 - 优化版本
  /// 🆕 关键改进：改为顺序执行而非并发，一次只有一个请求在途
  void _performLongPolling() {
    if (_isLongPollingActive && _isOnline) {
      _startSequentialPolling();
    }
  }

  /// 顺序执行长轮询（一次只有一个请求在途）
  Future<void> _startSequentialPolling() async {
    int retryCount = 0;
    const maxRetries = 3;
    const baseRetryDelay = Duration(seconds: 1);

    while (_isLongPollingActive && _isOnline) {
      try {
        final pollResponse = await _longPollRestClient.messages
            .getApiMessagesPoll(lastMsgId: _lastReceivedMessageId, timeout: 30);

        retryCount = 0; // 请求成功则重置重试计数

        if (pollResponse.messages.isNotEmpty) {
          _receivedMessages.insertAll(0, pollResponse.messages);
          final maxId = pollResponse.messages
              .map((m) => m.id)
              .reduce((a, b) => a > b ? a : b);
          _updateLastReceivedMessageId(maxId);
          _updateUnreadCount();
          notifyListeners();
          log('✓ 长轮询收到 ${pollResponse.messages.length} 条新消息');
        } else {
          log('✓ 长轮询超时（无新消息），继续轮询');
        }
      } catch (e) {
        log('✗ 长轮询出错: $e');

        // 401 未授权：立即停止
        if (e is DioException &&
            (e.response?.statusCode == 401 ||
                (e.type == DioExceptionType.badResponse &&
                    e.response?.statusCode == 401))) {
          log('✗ 长轮询检测到未授权（401），停止轮询');
          stopPolling();
          return;
        }

        // Dio 超时（正常现象）：立即继续，不计重试
        if (e is DioException &&
            (e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.receiveTimeout ||
                e.type == DioExceptionType.sendTimeout)) {
          log('⏱ 长轮询超时（正常现象），继续轮询');
          continue;
        }

        // AuthException / 字符串 401：立即停止
        if (e is AuthException ||
            e.toString().contains('401') ||
            e.toString().contains('Unauthorized')) {
          log('✗ 长轮询检测到未授权，停止轮询');
          stopPolling();
          return;
        }

        // 其余错误（连接错误、其他 Dio、未知异常）：指数退避重试
        retryCount++;
        final context = e is DioException ? 'Dio 错误 (${e.type})' : '轮询异常';
        if (!await _retryWithBackoff(
          retryCount,
          maxRetries,
          baseRetryDelay,
          context,
        )) {
          return;
        }
      }
    }

    log('✓ 长轮询循环已退出');
  }

  /// 指数退避重试辅助方法。[retryCount] 为已递增后的次数。
  /// 返回 true 表示已等待可继续重试；返回 false 表示达到上限已调用 [stopPolling]。
  Future<bool> _retryWithBackoff(
    int retryCount,
    int maxRetries,
    Duration baseDelay,
    String context,
  ) async {
    if (retryCount <= maxRetries) {
      final delay = baseDelay * (1 << (retryCount - 1)); // 1s, 2s, 4s
      log('⚠ $context，${delay.inSeconds}秒后重试 ($retryCount/$maxRetries)');
      await Future.delayed(delay);
      return true;
    } else {
      log('✗ $context 达到最大重试次数，停止轮询');
      stopPolling();
      return false;
    }
  }

  /// 清理长轮询资源
  void _cleanupLongPollResources() {
    _isLongPollingActive = false;
    _isStartingPolling = false;
    try {
      _longPollDio.close();
      _isLongPollDioInitialized = false;
    } catch (e) {
      log('关闭长轮询 Dio 实例失败: $e');
    }
  }

  /// 统一的消息获取接口
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
            _updateLastSentMessageId(maxId);
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
          _updateUnreadCount();
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
      log('获取消息失败: $e');
      rethrow;
    }
  }

  /// 获取特定用户的对话历史（优先从内存缓存过滤，避免全量 API 拉取）
  Future<List<dynamic>> getConversation(String peerId, {int page = 1}) async {
    if (_receivedMessages.isNotEmpty) {
      return _receivedMessages
          .where(
            (m) => m.senderBipupuId == peerId || m.receiverBipupuId == peerId,
          )
          .toList();
    }

    try {
      final apiClient = ApiClient.instance;

      final inboxResponse = await apiClient.execute(
        () => apiClient.api.messages.getApiMessagesInbox(
          page: page,
          pageSize: 50,
        ),
        operationName: 'GetConversation',
      );

      return inboxResponse.messages
          .where(
            (m) => m.senderBipupuId == peerId || m.receiverBipupuId == peerId,
          )
          .toList();
    } catch (e) {
      log('获取对话历史失败: $e');
      rethrow;
    }
  }

  /// 发送消息
  Future<dynamic> sendMessage({
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
      log('发送消息失败: $e');
      rethrow;
    }
  }

  /// 标记消息为已读（通过 API）
  Future<void> markMessageAsRead(int messageId) async {
    try {
      final apiClient = ApiClient.instance;

      await apiClient.execute(
        () => apiClient.api.messages.postApiMessagesMessageIdRead(
          messageId: messageId,
        ),
        operationName: 'MarkMessageRead',
      );

      await markAsRead(messageId);
    } catch (e) {
      log('标记消息为已读失败: $e');
      rethrow;
    }
  }

  /// 批量标记消息为已读（通过 API）
  Future<void> markMessagesReadBatch(List<int> messageIds) async {
    try {
      final apiClient = ApiClient.instance;

      await apiClient.execute(
        () => apiClient.api.messages.postApiMessagesReadBatch(body: messageIds),
        operationName: 'MarkMessagesReadBatch',
      );

      await markAsReadBatch(messageIds);
    } catch (e) {
      log('批量标记消息为已读失败: $e');
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
      log('收藏消息失败: $e');
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
      log('取消收藏失败: $e');
      rethrow;
    }
  }

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
      log('获取收藏列表失败: $e');
      rethrow;
    }
  }

  /// 删除消息
  Future<void> deleteMessage(int messageId) async {
    try {
      final apiClient = ApiClient.instance;

      await apiClient.execute(
        () => apiClient.api.messages.deleteApiMessagesMessageId(
          messageId: messageId,
        ),
        operationName: 'DeleteMessage',
      );

      _receivedMessages.removeWhere((m) => m.id == messageId);
      _sentMessages.removeWhere((m) => m.id == messageId);
      notifyListeners();
    } catch (e) {
      log('删除消息失败: $e');
      rethrow;
    }
  }

  void _updateUnreadCount() {
    final unreadMessages = _receivedMessages
        .where((m) => !_cachedReadIds.contains(m.id as int))
        .toList();

    _unreadCount = unreadMessages.length;

    _unreadSystemCount = unreadMessages
        .where((m) => m.messageType == MessageType.system)
        .length;

    _unreadNormalCount = _unreadCount - _unreadSystemCount;
  }

  void _updateLastReceivedMessageId(int newId) {
    if (newId > _lastReceivedMessageId) {
      _lastReceivedMessageId = newId;
      _imSettingsBox?.put(_lastReceivedMsgIdKey, _lastReceivedMessageId);
      // 同步到 Hive，使后台服务能读取最新游标，避免重复推送通知
      unawaited(BackgroundMessageService.syncLastMessageId(newId));
    }
  }

  void _updateLastSentMessageId(int newId) {
    if (newId > _lastSentMessageId) {
      _lastSentMessageId = newId;
    }
  }
}
