import 'dart:async';
import 'dart:developer';
import 'package:flutter/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../api/contact_api.dart';
import '../../api/message_api.dart';
import '../../models/message/message_response.dart';
import '../../models/contact/contact.dart';
import 'auth_service.dart';
import 'bluetooth_device_service.dart';
import '../storage/mobile_token_storage.dart';
import '../../api/api.dart';
import 'im_socket_service.dart';
import 'im_polling_service.dart';
import 'im_forwarder.dart';

/// Unified IM Service
class ImService extends ChangeNotifier with WidgetsBindingObserver {
  static final ImService _instance = ImService._internal();
  factory ImService() => _instance;
  ImService._internal();

  ContactApi? _contactApi;
  MessageApi? _messageApi;
  final BluetoothDeviceService _bluetoothService = BluetoothDeviceService();

  /// Socket and polling helpers (extracted)
  late final ImSocketService _socketService;
  late final ImPollingService _pollingService;
  late final MessageForwarder _forwarder;

  /// Socket connection placeholder state (true = connected)
  final ValueNotifier<bool> socketConnected = ValueNotifier<bool>(false);

  // lifecycle & network
  // ignore: unused_field
  final Connectivity _connectivity = Connectivity();
  // ignore: unused_field
  StreamSubscription<dynamic>? _connectivitySub;
  // ignore: unused_field
  final bool _isOnline = true; // Default true
  bool _isAppInForeground = true;

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

    // instantiate helper services
    _socketService = ImSocketService(onEvent: _onSocketEvent);
    _pollingService = ImPollingService(
      contactApi: contactApi,
      messageApi: messageApi,
      onData: _onPollingData,
    );
    _forwarder = MessageForwarder(_bluetoothService, () => _contacts);

    // attempt to connect socket if authenticated
    final status = AuthService().authState.value;
    if (status == AuthStatus.authenticated) {
      unawaited(_socketService.connectSocket());
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
      startPolling();
      unawaited(_socketService.connectSocket());
    } else {
      _pollingService.stopPolling();
      _messages = [];
      _contacts = [];
      _unreadCount = 0;
      _socketService.disconnectSocket();
      notifyListeners();
    }
  }

  /// Start Polling
  void startPolling() {
    _pollingService.startPolling();
  }

  /// Stop Polling
  void stopPolling() {
    _pollingService.stopPolling();
    WidgetsBinding.instance.removeObserver(this);
  }

  void _onSocketEvent(Map<String, dynamic> event) {
    final type = event['type'];
    if (type == 'new_message') {
      final payloadObj = event['payload'] ?? {};
      final content = payloadObj['content']?.toString() ?? '';

      if (_bluetoothService.connectionState.value ==
              BluetoothConnectionState.connected &&
          content.isNotEmpty) {
        _bluetoothService.sendTextMessage(content);
      }
    }
  }

  void _onPollingData({
    List<MessageResponse>? messages,
    List<Contact>? contacts,
    int? unreadCount,
  }) {
    var changed = false;
    if (contacts != null) {
      _contacts = contacts;
      changed = true;
    }
    if (messages != null) {
      // detect new messages to forward
      if (messages.length > _messages.length) {
        final newMessages = messages.sublist(_messages.length);
        final currentUserId = AuthService().currentUser?.bipupuId;
        final receivedOnly = currentUserId == null
            ? newMessages
            : newMessages
                  .where((m) => m.senderBipupuId != currentUserId)
                  .toList();
        if (receivedOnly.isNotEmpty) {
          _forwarder.forwardNewMessages(receivedOnly);
        }
      }
      _messages = messages;
      changed = true;
    }
    if (unreadCount != null) {
      _unreadCount = unreadCount;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  /// Refresh data manually
  Future<void> refresh() async {
    await _pollingService.refresh();
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
        // nothing to reset in facade; polling service handles intervals
      }
      _pollingService.applyPollingInterval(isForeground: _isAppInForeground);
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
    try {
      _socketService.dispose();
    } catch (_) {}
    try {
      _pollingService.dispose();
    } catch (_) {}
    super.dispose();
  }
}
