import 'dart:async';
import 'dart:developer';
import 'package:flutter/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dio/dio.dart';
import '../network/network.dart';

import '../config/app_config.dart';
import 'auth_service.dart';

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

  Timer? _longPollTimer;
  bool _isLongPollingActive = false;

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

  /// 获取所有已读消息ID集合
  Set<int> getReadMessageIds() {
    try {
      final readIds =
          _imSettingsBox?.get(_readMessageIdsKey, defaultValue: <int>[]) ?? [];
      if (readIds is List<int>) {
        return readIds.toSet();
      }
      return (readIds as List).cast<int>().toSet();
    } catch (e) {
      log('获取已读消息ID失败: $e');
      return {};
    }
  }

  /// 检查消息是否已读
  bool isMessageRead(int messageId) {
    return getReadMessageIds().contains(messageId);
  }

  /// 标记单条消息为已读
  Future<void> markAsRead(int messageId) async {
    try {
      final readIds = getReadMessageIds();
      if (!readIds.contains(messageId)) {
        readIds.add(messageId);
        await _imSettingsBox?.put(_readMessageIdsKey, readIds.toList());
        _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      log('标记消息为已读失败: $e');
    }
  }

  /// 批量标记消息为已读
  Future<void> markAsReadBatch(List<int> messageIds) async {
    try {
      final readIds = getReadMessageIds();
      bool hasChanges = false;

      for (final id in messageIds) {
        if (!readIds.contains(id)) {
          readIds.add(id);
          hasChanges = true;
        }
      }

      if (hasChanges) {
        await _imSettingsBox?.put(_readMessageIdsKey, readIds.toList());
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
      _setupConnectivityListener();
      _setupAuthListener();
      log('IM Service 初始化完成');
    } catch (e) {
      log('IM Service 初始化失败: $e');
    }
  }

  /// 初始化专用的长轮询 Dio 实例
  void _initializeLongPollDio() {
    // 创建基础配置
    final baseOptions = BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: Duration(seconds: 35), // 比服务器超时多5秒
      receiveTimeout: Duration(seconds: 35), // 比服务器超时多5秒
      sendTimeout: Duration(seconds: 35),
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
    _authService.authState.addListener(() {
      final status = _authService.authState.value;
      if (status == AuthStatus.authenticated) {
        if (_isOnline) {
          startPolling();
        }
      } else {
        stopPolling();
      }
    });
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
    _authService.authState.removeListener(() {}); // 无法移除匿名函数，但这不重要，因为服务通常是单例
    super.dispose();
  }

  /// 启动轮询
  Future<void> startPolling() async {
    if (!_isOnline ||
        _isLongPollingActive ||
        _authService.authState.value != AuthStatus.authenticated) {
      return;
    }

    try {
      // 确保长轮询资源已初始化
      if (!_isLongPollDioInitialized) {
        _initializeLongPollDio();
      }

      await _fetchInitialMessages();
      _isLongPollingActive = true;
      _performLongPolling();
      log('消息轮询已启动');
    } catch (e) {
      log('启动轮询失败: $e');
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

  /// 长轮询
  void _performLongPolling() {
    _longPollTimer?.cancel();
    _longPollTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) async {
      if (!_isLongPollingActive || !_isOnline) {
        timer.cancel();
        _longPollTimer = null;
        return;
      }

      try {
        // 使用专用的长轮询客户端
        // 拦截器会自动添加认证 Token，无需手动调用 _updateLongPollAuthToken()

        final pollResponse = await _longPollRestClient.messages
            .getApiMessagesPoll(lastMsgId: _lastReceivedMessageId, timeout: 30);

        if (pollResponse.messages.isNotEmpty) {
          _receivedMessages.insertAll(0, pollResponse.messages);

          final maxId = pollResponse.messages
              .map((m) => m.id)
              .reduce((a, b) => a > b ? a : b);
          _updateLastReceivedMessageId(maxId);
          _updateUnreadCount();
          notifyListeners();
        }
      } catch (e) {
        log('长轮询出错: $e');
        if (e is DioException) {
          // 处理 Dio 异常
          if (e.response?.statusCode == 401 ||
              e.type == DioExceptionType.badResponse &&
                  e.response?.statusCode == 401) {
            log('长轮询检测到未授权，停止轮询');
            stopPolling();
          } else if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout) {
            // 长轮询超时是正常的，不要记录为错误
            log('长轮询超时（正常）');
          } else if (e.type == DioExceptionType.connectionError) {
            log('长轮询连接错误，等待重试');
            await Future.delayed(const Duration(seconds: 2));
          } else {
            log('长轮询其他错误，等待重试');
            await Future.delayed(const Duration(seconds: 2));
          }
        } else if (e is AuthException ||
            e.toString().contains('401') ||
            e.toString().contains('Unauthorized')) {
          log('长轮询检测到未授权，停止轮询');
          stopPolling();
        } else {
          // 遇到错误稍微等待一下再重试，避免死循环刷屏
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    });
  }

  /// 清理长轮询资源
  void _cleanupLongPollResources() {
    _longPollTimer?.cancel();
    _longPollTimer = null;
    _isLongPollingActive = false;
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

  /// 获取特定用户的对话历史
  Future<List<dynamic>> getConversation(String peerId, {int page = 1}) async {
    try {
      final apiClient = ApiClient.instance;

      final inboxResponse = await apiClient.execute(
        () => apiClient.api.messages.getApiMessagesInbox(
          page: page,
          pageSize: 50,
        ),
        operationName: 'GetConversation',
      );

      final conversation = inboxResponse.messages
          .where(
            (m) => m.senderBipupuId == peerId || m.receiverBipupuId == peerId,
          )
          .toList();

      return conversation;
    } catch (e) {
      log('获取对话历史失败: $e');
      rethrow;
    }
  }

  /// 发送消息
  Future<dynamic> sendMessage({
    required String receiverId,
    required String content,
    String messageType = 'NORMAL',
    Map<String, dynamic>? pattern,
    List<int>? waveform,
  }) async {
    try {
      final apiClient = ApiClient.instance;

      // 构建消息创建对象
      final Map<String, dynamic> messageData = {
        'receiver_bipupu_id': receiverId,
        'content': content,
        'message_type': messageType,
      };
      if (pattern != null) messageData['pattern'] = pattern;
      if (waveform != null) messageData['waveform'] = waveform;

      final response = await apiClient.execute(
        () => apiClient.api.messages.postApiMessages(
          body: messageData as dynamic,
        ),
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

      final favoriteData = {'note': note ?? ''};

      final response = await apiClient.execute(
        () => apiClient.api.messages.postApiMessagesMessageIdFavorite(
          messageId: messageId,
          body: favoriteData as dynamic,
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
    final readIds = getReadMessageIds();
    final unreadMessages = _receivedMessages
        .where((m) => !readIds.contains(m.id as int))
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
    }
  }

  void _updateLastSentMessageId(int newId) {
    if (newId > _lastSentMessageId) {
      _lastSentMessageId = newId;
    }
  }
}
