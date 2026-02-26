import 'dart:async';
import 'dart:developer';
import 'package:flutter/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../network/network.dart';
import 'bluetooth_device_service.dart';
import 'auth_service.dart';

/// 统一的 IM 服务 - 处理消息和联系人的获取、轮询和转发
class ImService extends ChangeNotifier {
  static final ImService _instance = ImService._internal();
  factory ImService() => _instance;
  ImService._internal();

  final BluetoothDeviceService _bluetoothService = BluetoothDeviceService();
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<dynamic>? _connectivitySub;

  // 轮询配置
  static const Duration _foregroundMessageInterval = Duration(seconds: 15);
  static const Duration _backgroundMessageInterval = Duration(minutes: 5);
  Duration _currentMessageInterval = _foregroundMessageInterval;
  int _backoffMultiplier = 1;

  // 定时器
  Timer? _messageTimer;
  Timer? _contactsTimer;
  bool _isLongPollingActive = false;

  // 状态
  List<dynamic> _messages = [];
  List<dynamic> _contacts = [];
  int _unreadCount = 0;
  int _previousMessageCount = 0;
  int _lastMessageId = 0; // 用于增量同步
  bool _isAppInForeground = true;
  bool _isOnline = true;

  // Getters
  List<dynamic> get messages => List.unmodifiable(_messages);
  List<dynamic> get contacts => List.unmodifiable(_contacts);
  int get unreadCount => _unreadCount;

  /// 初始化服务
  Future<void> initialize() async {
    log('IM Service: Initializing');

    // 监听网络连接状态
    _connectivity.checkConnectivity().then((c) {
      _isOnline = c != ConnectivityResult.none;
    });
    _connectivitySub = _connectivity.onConnectivityChanged.listen((c) {
      _isOnline = c != ConnectivityResult.none;
      if (_isOnline) {
        // 网络恢复，重置退避倍数
        _backoffMultiplier = 1;
        _applyPollingInterval();
      }
    });

    // 监听 Token 过期事件
    TokenManager.tokenExpired.addListener(_onTokenExpired);

    // 启动轮询
    _startPolling();

    log('IM Service: Initialized');
  }

  /// Token 过期处理
  void _onTokenExpired() {
    if (TokenManager.tokenExpired.value) {
      log('IM Service: Token expired, stopping polling');
      _stopPolling();
      _messages = [];
      _contacts = [];
      _unreadCount = 0;
      notifyListeners();
    }
  }

  /// 启动轮询
  void _startPolling() {
    if (_messageTimer != null && _messageTimer!.isActive) {
      return;
    }

    // 检查认证状态，未登录不启动轮询
    final authService = AuthService();
    if (authService.authState.value != AuthStatus.authenticated) {
      log('IM Service: Not authenticated, skipping polling');
      return;
    }

    log('IM Service: Starting polling');
    _startMessagePolling();
    _startContactsPolling();
    _fetchInitialData();
    _startLongPolling(); // 启动长轮询
  }

  /// 停止轮询
  void _stopPolling() {
    log('IM Service: Stopping polling');
    _messageTimer?.cancel();
    _contactsTimer?.cancel();
    _messageTimer = null;
    _contactsTimer = null;
    _isLongPollingActive = false;
  }

  /// 获取初始数据
  Future<void> _fetchInitialData() async {
    try {
      await Future.wait([_fetchContacts(), _fetchMessages()]);
    } catch (e) {
      log('IM Service: Failed to fetch initial data: $e');
    }
  }

  /// 启动消息轮询
  void _startMessagePolling() {
    _messageTimer?.cancel();
    _messageTimer = Timer.periodic(
      _currentMessageInterval * _backoffMultiplier,
      (timer) {
        _fetchMessages();
      },
    );
  }

  /// 启动联系人轮询
  void _startContactsPolling() {
    _contactsTimer?.cancel();
    _contactsTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _fetchContacts();
    });
  }

  /// 应用轮询间隔
  void _applyPollingInterval() {
    _currentMessageInterval = _isAppInForeground
        ? _foregroundMessageInterval
        : _backgroundMessageInterval;
    _startMessagePolling();
  }

  /// 获取消息列表（支持增量同步）
  Future<void> _fetchMessages() async {
    if (!_isOnline) {
      log('IM Service: Offline, skipping message fetch');
      return;
    }

    try {
      final apiClient = ApiClient.instance;
      final response = await apiClient.execute(
        () => apiClient.api.messages.getApiMessages(
          direction: 'received',
          page: 1,
          pageSize: 50,
          sinceId: _lastMessageId, // 增量同步
        ),
        operationName: 'FetchMessages',
      );

      if (response.messages.isNotEmpty) {
        // 更新最后消息ID
        _lastMessageId = response.messages
            .map((m) => m.id)
            .reduce((a, b) => a > b ? a : b);

        // 合并新消息到列表
        _messages.insertAll(0, response.messages);

        // 检查新消息并转发到蓝牙设备
        _forwardNewMessagesToBluetooth(response.messages);

        log(
          'IM Service: Fetched ${response.messages.length} new messages, lastId=$_lastMessageId',
        );
      }

      _unreadCount = _messages.where((m) => m.isRead == false).length;
      _previousMessageCount = _messages.length;

      // 重置退避倍数
      _backoffMultiplier = 1;
      notifyListeners();
    } on AuthException catch (e) {
      log('IM Service: Auth error fetching messages: ${e.message}');
      _stopPolling();
    } on NetworkException catch (e) {
      log('IM Service: Network error fetching messages: ${e.message}');
      // 应用指数退避
      if (_backoffMultiplier < 8) {
        _backoffMultiplier *= 2;
        _startMessagePolling();
      }
    } catch (e) {
      log('IM Service: Error fetching messages: $e');
    }
  }

  /// 获取联系人列表
  Future<void> _fetchContacts() async {
    if (!_isOnline) {
      log('IM Service: Offline, skipping contacts fetch');
      return;
    }

    try {
      final apiClient = ApiClient.instance;
      final response = await apiClient.execute(
        () => apiClient.api.contacts.getApiContacts(page: 1, pageSize: 100),
        operationName: 'FetchContacts',
      );

      _contacts = response.contacts;
      notifyListeners();
    } on AuthException catch (e) {
      log('IM Service: Auth error fetching contacts: ${e.message}');
      _stopPolling();
    } on NetworkException catch (e) {
      log('IM Service: Network error fetching contacts: ${e.message}');
    } catch (e) {
      log('IM Service: Error fetching contacts: $e');
    }
  }

  /// 转发新消息到蓝牙设备
  void _forwardNewMessagesToBluetooth(List<dynamic> newMessages) {
    if (_bluetoothService.connectionState.value !=
        BluetoothConnectionState.connected) {
      return;
    }

    for (final message in newMessages) {
      try {
        final formattedMessage = _formatMessageForBluetooth(message);
        _bluetoothService.sendTextMessage(formattedMessage);
        log('IM Service: Forwarded message to Bluetooth device');
      } catch (e) {
        log('IM Service: Failed to forward message to Bluetooth: $e');
      }
    }
  }

  /// 格式化消息用于蓝牙转发
  String _formatMessageForBluetooth(dynamic message) {
    try {
      // 查找发送者联系人
      dynamic senderContact;
      try {
        senderContact = _contacts.firstWhere(
          (contact) => contact.bipupuId == message.senderBipupuId,
        );
      } catch (_) {
        senderContact = null;
      }

      final senderName =
          senderContact?.name ?? message.senderBipupuId ?? 'Unknown';
      final content = message.content ?? '';
      return 'From $senderName: $content';
    } catch (e) {
      log('IM Service: Error formatting message: $e');
      return 'New message';
    }
  }

  /// 启动长轮询（真正的 Long Polling）
  void _startLongPolling() {
    if (_isLongPollingActive) {
      return;
    }

    _isLongPollingActive = true;
    _performLongPolling();
  }

  /// 执行长轮询
  Future<void> _performLongPolling() async {
    while (_isLongPollingActive && _isOnline) {
      try {
        final apiClient = ApiClient.instance;
        final response = await apiClient.execute(
          () => apiClient.api.messages.getApiMessagesPoll(
            lastMsgId: _lastMessageId,
            timeout: 30,
          ),
          operationName: 'LongPollMessages',
        );

        if (!_isLongPollingActive) break;

        if (response.messages.isNotEmpty) {
          // 更新最后消息ID
          _lastMessageId = response.messages
              .map((m) => m.id)
              .reduce((a, b) => a > b ? a : b);

          // 合并新消息到列表
          _messages.insertAll(0, response.messages);

          // 检查新消息并转发到蓝牙设备
          _forwardNewMessagesToBluetooth(response.messages);

          _unreadCount = _messages.where((m) => m.isRead == false).length;

          log(
            'IM Service: Long polling received ${response.messages.length} new messages',
          );
          notifyListeners();
        }
      } on AuthException catch (e) {
        log('IM Service: Auth error in long polling: ${e.message}');
        _isLongPollingActive = false;
        _stopPolling();
      } on NetworkException catch (e) {
        log('IM Service: Network error in long polling: ${e.message}');
        // 网络错误时等待后重试
        await Future.delayed(const Duration(seconds: 5));
      } catch (e) {
        log('IM Service: Error in long polling: $e');
        await Future.delayed(const Duration(seconds: 5));
      }
    }
  }

  /// 手动刷新数据
  Future<void> refresh() async {
    await Future.wait([_fetchContacts(), _fetchMessages()]);
  }

  /// 清除本地缓存
  void clearLocalCache() {
    _messages = [];
    _contacts = [];
    _unreadCount = 0;
    _previousMessageCount = 0;
    _lastMessageId = 0;
    notifyListeners();
  }

  /// 应用生命周期变化
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasForeground = _isAppInForeground;
    _isAppInForeground = state == AppLifecycleState.resumed;

    if (wasForeground != _isAppInForeground) {
      log('IM Service: App lifecycle changed, foreground=$_isAppInForeground');
      if (_isAppInForeground) {
        _backoffMultiplier = 1;
      }
      _applyPollingInterval();
    }
  }

  @override
  void dispose() {
    TokenManager.tokenExpired.removeListener(_onTokenExpired);
    _stopPolling();
    _connectivitySub?.cancel();
    super.dispose();
  }
}
