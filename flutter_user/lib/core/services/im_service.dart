import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

import '../../api/api.dart';
import '../../api/contact_api.dart';
import '../../api/message_api.dart';
import '../../models/contact/contact.dart';
import '../../models/message/message_response.dart';
import 'auth_service.dart';
import 'bluetooth_device_service.dart';
import 'im_forwarder.dart';
import 'im_polling_service.dart';
import 'im_socket_service.dart';

/// Unified IM Service
class ImService extends ChangeNotifier with WidgetsBindingObserver {
  static final ImService _instance = ImService._internal();
  ContactApi? _contactApi;
  MessageApi? _messageApi;

  final BluetoothDeviceService _bluetoothService = BluetoothDeviceService();

  /// Socket and polling helpers (extracted)
  late final ImSocketService _socketService;
  late final ImPollingService _pollingService;
  late final MessageForwarder _messageForwarder;

  bool get isLoading => _pollingService.isPollingActive;

  /// Socket connection placeholder state (true = connected)
  final ValueNotifier<bool> socketConnected = ValueNotifier<bool>(false);
  // lifecycle & network
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<dynamic>? _connectivitySub;

  bool _isAppInForeground = true;
  // State
  List<MessageResponse> _messages = [];
  List<Contact> _contacts = [];

  int _unreadCount = 0;
  factory ImService() => _instance;
  ImService._internal();

  ContactApi get contactApi => _contactApi!;
  List<Contact> get contacts => List.unmodifiable(_contacts);
  MessageApi get messageApi => _messageApi!;

  // Getters
  List<MessageResponse> get messages => List.unmodifiable(_messages);
  int get unreadCount => _unreadCount;

  /// Clear local cached messages
  void clearLocalCache() {
    _messages = [];
    _unreadCount = 0;
    notifyListeners();
  }

  /// Refresh data from server
  Future<void> refresh() async {
    await _pollingService.refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasForeground = _isAppInForeground;
    _isAppInForeground = state == AppLifecycleState.resumed;

    if (wasForeground && !_isAppInForeground) {
      // App went to background
      _pollingService.stopPolling();
      _socketService.disconnectSocket();
    } else if (!wasForeground && _isAppInForeground) {
      // App came to foreground
      final status = AuthService().authState.value;
      if (status == AuthStatus.authenticated) {
        _socketService.connectSocket();
        _pollingService.startPolling();
      }
    }
  }

  /// Dispose service
  void disposeService() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    _socketService.disconnectSocket();
    _pollingService.stopPolling();
    AuthService().authState.removeListener(_onAuthStateChanged);
    log('IM Service: Disposed');
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

  /// Get service status
  Map<String, dynamic> getStatus() {
    return {
      'messagesCount': _messages.length,
      'contactsCount': _contacts.length,
      'unreadCount': _unreadCount,
      'isAppInForeground': _isAppInForeground,
      'socketConnected': socketConnected.value,
    };
  }

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

    // instantiate helper services
    _socketService = ImSocketService(onEvent: _onSocketEvent);
    _pollingService = ImPollingService(
      contactApi: contactApi,
      messageApi: messageApi,
      onData: _onPollingData,
    );
    _messageForwarder = MessageForwarder(_bluetoothService, () => _contacts);

    // attempt to connect socket if authenticated
    final status = AuthService().authState.value;
    if (status == AuthStatus.authenticated) {
      _socketService.connectSocket();
    }

    // Listen to Auth State
    AuthService().authState.addListener(_onAuthStateChanged);
    // Initial check
    _onAuthStateChanged();
  }

  /// Mark message as read
  Future<void> markMessageAsRead(int messageId) async {
    try {
      // await messageApi.markMessageAsRead(messageId);

      // Update local state
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        // _messages[index] = _messages[index].copyWith(isRead: true);
        if (_unreadCount > 0) {
          _unreadCount--;
        }
        notifyListeners();
      }
    } catch (e) {
      log('IM Service: Failed to mark message as read: $e');
    }
  }

  /// Send a message
  Future<MessageResponse> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    try {
      final message = await messageApi.sendMessage(
        receiverId: receiverId,
        content: content,
      );

      // Add to local messages
      _messages.add(message);
      notifyListeners();

      // Forward to Bluetooth devices if connected (fire and forget)
      unawaited(_messageForwarder.forwardNewMessages([message]));

      return message;
    } catch (e) {
      log('IM Service: Failed to send message: $e');
      rethrow;
    }
  }

  void _onAuthStateChanged() {
    final status = AuthService().authState.value;
    if (status == AuthStatus.authenticated) {
      _socketService.connectSocket();
      _pollingService.startPolling();
    } else {
      _socketService.disconnectSocket();
      _pollingService.stopPolling();
      clearLocalCache();
    }
  }

  /// Handle polling data
  void _onPollingData({
    List<MessageResponse>? messages,
    List<Contact>? contacts,
    int? unreadCount,
  }) {
    if (messages != null) {
      _updateMessages(messages);
    }
    if (contacts != null) {
      _updateContacts(contacts);
    }
  }

  /// Handle socket events
  void _onSocketEvent(Map<String, dynamic> event) {
    log('IM Service: Socket event: $event');
    // TODO: Handle socket events
  }

  /// Update contacts list
  void _updateContacts(List<Contact> newContacts) {
    _contacts = newContacts;
    notifyListeners();
  }

  /// Update messages list
  void _updateMessages(List<MessageResponse> newMessages) {
    // Detect new messages by comparing message IDs
    final Set<int> existingIds = Set.from(_messages.map((m) => m.id));
    final List<MessageResponse> newMessagesToForward = [];

    for (final message in newMessages) {
      if (!existingIds.contains(message.id)) {
        newMessagesToForward.add(message);
        _unreadCount++;
      }
    }

    // Forward new messages to Bluetooth devices (fire and forget)
    if (newMessagesToForward.isNotEmpty) {
      unawaited(_messageForwarder.forwardNewMessages(newMessagesToForward));
    }

    _messages = newMessages;
    notifyListeners();
  }
}
