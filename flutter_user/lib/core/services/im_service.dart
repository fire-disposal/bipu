import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:web_socket_channel/io.dart';
import '../../api/contact_api.dart';
import '../../api/message_api.dart';
import '../../models/message/message_response.dart';
import '../../models/contact/contact.dart';
import 'auth_service.dart';
import 'bluetooth_device_service.dart';
import '../storage/mobile_token_storage.dart';
import '../../api/api.dart';

/// Unified IM Service
class ImService extends ChangeNotifier with WidgetsBindingObserver {
  static final ImService _instance = ImService._internal();
  factory ImService() => _instance;
  ImService._internal();

  ContactApi? _contactApi;
  MessageApi? _messageApi;
  final BluetoothDeviceService _bluetoothService = BluetoothDeviceService();

  /// Socket connection placeholder state (true = connected)
  final ValueNotifier<bool> socketConnected = ValueNotifier<bool>(false);

  Timer? _messageTimer;
  Timer? _contactsTimer;

  // lifecycle & network
  // ignore: unused_field
  final Connectivity _connectivity = Connectivity();
  // ignore: unused_field
  StreamSubscription<dynamic>? _connectivitySub;
  // ignore: unused_field
  final bool _isOnline = true; // Default true
  bool _isAppInForeground = true;

  // adaptive polling config
  static const Duration _foregroundMessageInterval = Duration(seconds: 15);
  static const Duration _backgroundMessageInterval = Duration(minutes: 5);
  Duration _currentMessageInterval = _foregroundMessageInterval;
  int _backoffMultiplier = 1;

  // State
  List<MessageResponse> _messages = [];
  List<Contact> _contacts = [];
  int _unreadCount = 0;
  // ignore: unused_field
  final bool _isLoading = false;
  int _previousMessageCount =
      0; // Track previous message count for new message detection

  // Configuration
  static const Duration _contactsPullInterval = Duration(minutes: 10);

  // Getters
  List<MessageResponse> get messages => List.unmodifiable(_messages);
  List<Contact> get contacts => List.unmodifiable(_contacts);
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  ContactApi get contactApi => _contactApi!;
  MessageApi get messageApi => _messageApi!;

  /// Initialize service
  void initialize([ApiClient? client]) {
    final clientInst = client ?? api;
    _contactApi ??= ContactApi(clientInst);
    _messageApi ??= MessageApi(clientInst);
    WidgetsBinding.instance.addObserver(this);
    log('IM Service: Initialized');

    // initialize socketConnected based on network connectivity as a placeholder
    _connectivity.checkConnectivity().then((c) {
      socketConnected.value = c != ConnectivityResult.none;
    });
    _connectivitySub = _connectivity.onConnectivityChanged.listen((c) {
      socketConnected.value = c != ConnectivityResult.none;
    });

    // attempt to connect socket if authenticated
    final status = AuthService().authState.value;
    if (status == AuthStatus.authenticated) {
      // fire-and-forget connect; path '/ws' is a common default — backend may use different path
      unawaited(connectSocket());
    }

    // Listen to Auth State
    AuthService().authState.addListener(_onAuthStateChanged);
    // Initial check
    _onAuthStateChanged();
  }

  void _onAuthStateChanged() {
    final status = AuthService().authState.value;
    log('IM Service: Auth state changed to $status');
    if (status == AuthStatus.authenticated) {
      // Only start if not already polling or if we need to restart
      if (_messageTimer == null || !_messageTimer!.isActive) {
        startPolling();
        unawaited(connectSocket());
      }
    } else {
      _stopTimers();
      _messages = [];
      _contacts = [];
      _unreadCount = 0;
      disconnectSocket();
      notifyListeners();
    }
  }

  /// Start Polling
  void startPolling() {
    _startMessagePolling();
    _startContactsPolling();
    _fetchInitialData();
  }

  /// Stop Polling
  void stopPolling() {
    _stopTimers();
    WidgetsBinding.instance.removeObserver(this);
  }

  void _stopTimers() {
    _messageTimer?.cancel();
    _contactsTimer?.cancel();
  }

  Future<void> _fetchInitialData() async {
    await Future.wait([_fetchContacts(), _fetchMessages()]);
  }

  void _startMessagePolling() {
    _messageTimer?.cancel();
    _messageTimer = Timer.periodic(
      _currentMessageInterval * _backoffMultiplier,
      (timer) {
        _fetchMessages();
      },
    );
  }

  // WebSocket
  IOWebSocketChannel? _wsChannel;
  StreamSubscription? _wsSub;
  Duration _reconnectDelay = const Duration(seconds: 5);
  Timer? _pingTimer;

  /// Connect to backend WebSocket at `/api/ws`.
  /// Backend expects token as query parameter: ws(s)://host[:port]/api/ws?token=xxx
  Future<void> connectSocket({String path = '/api/ws'}) async {
    try {
      final uri = Uri.parse(AppConfig.baseUrl);
      final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
      final port = uri.hasPort ? uri.port : (scheme == 'wss' ? 443 : 80);

      final token = await MobileTokenStorage().getAccessToken();

      final wsUri = Uri(
        scheme: scheme,
        host: uri.host,
        port: port,
        path: path,
        queryParameters: token != null && token.isNotEmpty
            ? {'token': token}
            : null,
      );

      // clean previous
      try {
        _wsSub?.cancel();
        _wsChannel?.sink.close();
      } catch (_) {}

      _wsChannel = IOWebSocketChannel.connect(wsUri.toString());
      socketConnected.value = true;

      // When WebSocket connected, stop long-polling to avoid duplicates
      try {
        _messageTimer?.cancel();
      } catch (_) {}

      _wsSub = _wsChannel!.stream.listen(
        (event) {
          _handleSocketEvent(event);
        },
        onDone: () async {
          socketConnected.value = false;
          _stopPing();
          // try reconnect
          await Future.delayed(_reconnectDelay);
          if (AuthService().authState.value == AuthStatus.authenticated) {
            unawaited(connectSocket(path: path));
          }
        },
        onError: (err) async {
          socketConnected.value = false;
          _stopPing();
          await Future.delayed(_reconnectDelay);
          if (AuthService().authState.value == AuthStatus.authenticated) {
            unawaited(connectSocket(path: path));
          }
        },
      );

      // start heartbeat
      _startPing();
    } catch (e) {
      socketConnected.value = false;
    }
  }

  void disconnectSocket() {
    try {
      _stopPing();
      _wsSub?.cancel();
      _wsChannel?.sink.close();
    } catch (_) {}
    _wsSub = null;
    _wsChannel = null;
    socketConnected.value = false;

    // WebSocket disconnected — resume long-polling as fallback
    try {
      _applyPollingInterval();
    } catch (_) {}
  }

  void _handleSocketEvent(dynamic event) {
    try {
      final String payload = event is String
          ? event
          : utf8.decode(event as List<int>);
      final Map<String, dynamic> data = json.decode(payload);

      final type = data['type'];
      if (type == 'new_message') {
        final payloadObj = data['payload'] ?? {};
        final content = payloadObj['content']?.toString() ?? '';

        if (_bluetoothService.connectionState.value ==
                BluetoothConnectionState.connected &&
            content.isNotEmpty) {
          _bluetoothService.sendTextMessage(content);
        }
      }
    } catch (e) {
      // ignore parse errors
    }
  }

  void _startPing() {
    _stopPing();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      try {
        if (_wsChannel != null) {
          _wsChannel!.sink.add(json.encode({'type': 'ping'}));
        }
      } catch (_) {}
    });
  }

  void _stopPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void _startContactsPolling() {
    _contactsTimer?.cancel();
    _contactsTimer = Timer.periodic(_contactsPullInterval, (timer) {
      _fetchContacts();
    });
  }

  void _applyPollingInterval() {
    // restart timers with new intervals
    if (_isAppInForeground) {
      _currentMessageInterval = _foregroundMessageInterval;
    } else {
      _currentMessageInterval = _backgroundMessageInterval;
    }
    _startMessagePolling();
  }

  /// Fetch Contacts
  Future<void> _fetchContacts() async {
    if (_contactApi == null) return;
    try {
      final response = await _contactApi!.getContacts(page: 1, size: 100);
      _contacts = response.items;
      notifyListeners();
    } catch (e) {
      log('IM Service: Fetch contacts failed: ');
    }
  }

  /// Fetch Messages (combine sent and received)
  Future<void> _fetchMessages() async {
    if (_messageApi == null) return;
    try {
      final receivedData = await _messageApi!.getMessages(
        direction: 'received',
        page: 1,
        size: 50,
      );
      final sentData = await _messageApi!.getMessages(
        direction: 'sent',
        page: 1,
        size: 50,
      );

      final Map<int, MessageResponse> merged = {};

      for (var m in receivedData.items) {
        merged[m.id] = m;
      }
      for (var m in sentData.items) {
        merged[m.id] = m;
      }

      final list = merged.values.toList();
      // sort by created_at ascending (oldest first)
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      _messages = list;

      // Calculate unread (from received messages)
      _unreadCount = receivedData.items.where((m) => !m.isRead).length;

      // Check for new messages and forward to Bluetooth device
      if (_messages.length > _previousMessageCount) {
        final newMessages = _messages.sublist(_previousMessageCount);
        _forwardNewMessagesToBluetooth(newMessages);
      }
      _previousMessageCount = _messages.length;

      notifyListeners();
    } catch (e) {
      log('IM Service: Fetch messages failed: $e');
      // Simple exponential backoff on error
      if (_backoffMultiplier < 8) {
        _backoffMultiplier *= 2;
        _startMessagePolling();
      }
    }
  }

  /// Forward new messages to connected Bluetooth device
  void _forwardNewMessagesToBluetooth(List<MessageResponse> newMessages) {
    // Only forward if Bluetooth is connected
    if (_bluetoothService.connectionState.value !=
        BluetoothConnectionState.connected) {
      return;
    }

    for (final message in newMessages) {
      // Only forward received messages (not sent messages)
      // Check if this is a received message by comparing sender with current user
      final currentUserId = AuthService().currentUser?.bipupuId;
      if (currentUserId != null && message.senderBipupuId != currentUserId) {
        try {
          // Format message for forwarding
          final formattedMessage = _formatMessageForBluetooth(message);
          _bluetoothService.sendTextMessage(formattedMessage);
          log(
            'IM Service: Forwarded message ${message.id} to Bluetooth device',
          );
        } catch (e) {
          log(
            'IM Service: Failed to forward message ${message.id} to Bluetooth: $e',
          );
        }
      }
    }
  }

  /// Refresh data manually
  Future<void> refresh() async {
    await Future.wait([_fetchContacts(), _fetchMessages()]);
  }

  /// Clear local cached messages
  void clearLocalCache() {
    _messages = [];
    _unreadCount = 0;
    notifyListeners();
  }

  /// Format message for Bluetooth forwarding
  String _formatMessageForBluetooth(MessageResponse message) {
    // Find sender name
    final senderContact = _contacts.firstWhere(
      (contact) => contact.contactBipupuId == message.senderBipupuId,
      orElse: () => Contact(
        id: 0,
        contactBipupuId: message.senderBipupuId,
        remark: 'Unknown',
        createdAt: DateTime.now(),
      ),
    );

    final senderName = senderContact.remark ?? senderContact.contactBipupuId;

    // Format: "From [Sender]: [Message]"
    return 'From $senderName: ${message.content}';
  }

  // Helper to get contact by ID
  Contact? getContact(String bipupuId) {
    try {
      return _contacts.firstWhere(
        (c) => c.contactBipupuId == bipupuId,
        orElse: () => throw Exception('Not found'),
      );
    } catch (_) {
      return null;
    }
  }

  /// Format outgoing (sent) message for Bluetooth forwarding
  // no outgoing forwarding helper (outgoing messages should not be forwarded)

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasForeground = _isAppInForeground;
    _isAppInForeground = state == AppLifecycleState.resumed;
    if (wasForeground != _isAppInForeground) {
      log('IM Service: app lifecycle changed. foreground=');
      // reset backoff when returning to foreground
      if (_isAppInForeground) {
        _backoffMultiplier = 1;
      }
      _applyPollingInterval();
    }
  }

  @override
  void dispose() {
    AuthService().authState.removeListener(_onAuthStateChanged);
    stopPolling();
    _connectivitySub?.cancel();
    try {
      socketConnected.dispose();
    } catch (_) {}
    super.dispose();
  }
}
