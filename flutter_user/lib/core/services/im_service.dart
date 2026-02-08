import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../api/api_service.dart';
import '../../models/message/message_response.dart';
import '../../models/friendship/friendship_response.dart';
import '../../models/message/message_request.dart';
import '../../models/common/enums.dart';

/// 统一的IM服务 - 符合后端架构
class ImService extends ChangeNotifier with WidgetsBindingObserver {
  static final ImService _instance = ImService._internal();
  factory ImService() => _instance;
  ImService._internal();

  ApiService? _apiService;
  Timer? _messageTimer;
  Timer? _friendsTimer;
  DateTime? _lastMessageAt;
  // lifecycle & network
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<dynamic>? _connectivitySub;
  bool _isOnline = true;
  bool _isAppInForeground = true;

  // adaptive polling config
  static const Duration _foregroundMessageInterval = Duration(seconds: 15);
  static const Duration _backgroundMessageInterval = Duration(minutes: 5);
  Duration _currentMessageInterval = _foregroundMessageInterval;
  int _backoffMultiplier = 1;
  static const int _maxBackoffMultiplier = 8;

  // 数据状态 - 简化管理
  List<MessageResponse> _messages = [];
  List<FriendshipResponse> _friendships = [];
  List<FriendshipResponse> _friendRequests = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  // 配置参数 - 优化频率
  static const Duration _friendsPullInterval = Duration(minutes: 10);

  // Getters
  List<MessageResponse> get messages => List.unmodifiable(_messages);
  List<FriendshipResponse> get friendships => List.unmodifiable(_friendships);
  List<FriendshipResponse> get friendRequests =>
      List.unmodifiable(_friendRequests);
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  /// 初始化服务
  void initialize(ApiService apiService) {
    _apiService = apiService;
    log('IM Service: 初始化完成');
  }

  /// 启动定时任务
  void startPolling() {
    if (_apiService == null) {
      // If we have a lastMessage timestamp, fetch incremental newer messages
      return;
    }

    log('IM Service: 启动定时任务 (adaptive polling)');

    // register lifecycle observer
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}

    // initial network state
    _connectivitySub = _connectivity.onConnectivityChanged.listen((
      dynamic payload,
    ) {
      bool online;
      if (payload is ConnectivityResult) {
        online = payload != ConnectivityResult.none;
      } else if (payload is Iterable) {
        try {
          online = payload.cast<ConnectivityResult>().any(
            (r) => r != ConnectivityResult.none,
          );
        } catch (_) {
          online = true;
        }
      } else {
        // Unknown payload type — assume online to avoid accidental stop.
        online = true;
      }

      if (_isOnline != online) {
        _isOnline = online;
        if (!_isOnline) {
          log('IM Service: 网络离线，停止轮询');
          _messageTimer?.cancel();
        } else {
          log('IM Service: 网络恢复，重启轮询');
          _applyPollingInterval();
        }
      }
    });

    // immediate initial fetch
    _fetchInitialData();

    // start timers according to current state
    _applyPollingInterval();

    _friendsTimer = Timer.periodic(_friendsPullInterval, (timer) {
      _fetchFriends();
      _fetchFriendRequests();
    });
  }

  void _applyPollingInterval() {
    _messageTimer?.cancel();
    // set base interval by foreground/background
    _currentMessageInterval = _isAppInForeground
        ? _foregroundMessageInterval
        : _backgroundMessageInterval;
    // apply backoff multiplier
    final seconds = (_currentMessageInterval.inSeconds * _backoffMultiplier)
        .clamp(1, _backgroundMessageInterval.inSeconds);
    final interval = Duration(seconds: seconds);
    _messageTimer = Timer.periodic(interval, (timer) {
      if (_isOnline) {
        _fetchMessages().catchError((e) {
          // on error increase backoff
          _backoffMultiplier = (_backoffMultiplier * 2).clamp(
            1,
            _maxBackoffMultiplier,
          );
          log(
            'IM Service: fetchMessages error, increasing backoff to x$_backoffMultiplier',
          );
          // restart timer with new interval
          _applyPollingInterval();
        });
        _fetchUnreadCount();
      }
    });
  }

  /// 停止定时任务
  void stopPolling() {
    log('IM Service: 停止定时任务');
    _messageTimer?.cancel();
    _friendsTimer?.cancel();
    _messageTimer = null;
    _friendsTimer = null;
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  /// 初始数据拉取
  Future<void> _fetchInitialData() async {
    _setLoading(true);
    try {
      await Future.wait([
        _fetchFriends(),
        _fetchFriendRequests(),
        _fetchMessages(),
        _fetchUnreadCount(),
      ]);
    } catch (e) {
      log('IM Service: 初始数据拉取失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 拉取好友列表
  Future<void> _fetchFriends() async {
    if (_apiService == null) return;
    try {
      final response = await _apiService!.getFriends(page: 1, size: 100);
      _friendships = response.items;
      notifyListeners();
      log('IM Service: 拉取到${_friendships.length}个好友');
    } catch (e) {
      log('IM Service: 拉取好友列表失败: $e');
    }
  }

  /// 拉取好友请求
  Future<void> _fetchFriendRequests() async {
    if (_apiService == null) return;
    try {
      final response = await _apiService!.getFriendRequests(page: 1, size: 100);
      _friendRequests = response.items;
      notifyListeners();
      log('IM Service: 拉取到${_friendRequests.length}个好友请求');
    } catch (e) {
      log('IM Service: 拉取好友请求失败: $e');
    }
  }

  /// 拉取消息列表
  Future<void> _fetchMessages() async {
    if (_apiService == null) return;
    try {
      // If we have a lastMessage timestamp, fetch incremental newer messages
      final resp = await _apiService!.getMessages(
        page: 1,
        size: 50,
        startDate: _lastMessageAt?.toIso8601String(),
      );

      final newItems = resp.items;

      if (_messages.isEmpty) {
        _messages = newItems;
      } else if (newItems.isNotEmpty) {
        // merge new items at beginning (newest first) and dedupe by id
        final combined = [...newItems, ..._messages];
        final Map<int, MessageResponse> dedup = {};
        for (var m in combined) {
          dedup[m.id] = m;
        }
        _messages = dedup.values.toList();
        // sort by createdAt asc for chat page expectations
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      }

      // update lastMessageAt
      if (_messages.isNotEmpty) {
        _lastMessageAt = _messages.last.createdAt.toUtc();
      }
      notifyListeners();
      log('IM Service: 拉取到${_messages.length}条消息');
    } catch (e) {
      log('IM Service: 拉取消息失败: $e');
    }
  }

  /// 拉取未读消息数
  Future<void> _fetchUnreadCount() async {
    if (_apiService == null) return;
    try {
      _unreadCount = await _apiService!.getUnreadCount();
      notifyListeners();
    } catch (e) {
      log('IM Service: 拉取未读消息数失败: $e');
    }
  }

  /// 发送消息
  Future<MessageResponse?> sendMessage({
    required int receiverId,
    required String content,
    String title = '',
  }) async {
    if (_apiService == null) return null;
    try {
      final request = MessageCreateRequest(
        title: title,
        content: content,
        receiverId: receiverId,
        messageType: MessageType.user, // 使用用户消息类型
      );
      final message = await _apiService!.sendMessage(request);

      // 立即更新本地消息列表
      _messages.insert(0, message);
      notifyListeners();

      log('IM Service: 消息发送成功');
      return message;
    } catch (e) {
      log('IM Service: 发送消息失败: $e');
      return null;
    }
  }

  /// 接受好友请求
  Future<bool> acceptFriendRequest(int friendshipId) async {
    if (_apiService == null) return false;
    try {
      await _apiService!.acceptFriendRequest(friendshipId);

      // 重新拉取数据
      await Future.wait([_fetchFriends(), _fetchFriendRequests()]);

      log('IM Service: 接受好友请求成功');
      return true;
    } catch (e) {
      log('IM Service: 接受好友请求失败: $e');
      return false;
    }
  }

  /// 拒绝好友请求
  Future<bool> rejectFriendRequest(int friendshipId) async {
    if (_apiService == null) return false;
    try {
      await _apiService!.rejectFriendRequest(friendshipId);
      await _fetchFriendRequests();
      log('IM Service: 拒绝好友请求成功');
      return true;
    } catch (e) {
      log('IM Service: 拒绝好友请求失败: $e');
      return false;
    }
  }

  /// 手动刷新数据
  Future<void> refresh() async {
    await _fetchInitialData();
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasForeground = _isAppInForeground;
    _isAppInForeground = state == AppLifecycleState.resumed;
    if (wasForeground != _isAppInForeground) {
      log('IM Service: app lifecycle changed. foreground=$_isAppInForeground');
      // reset backoff when returning to foreground
      if (_isAppInForeground) {
        _backoffMultiplier = 1;
      }
      _applyPollingInterval();
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
