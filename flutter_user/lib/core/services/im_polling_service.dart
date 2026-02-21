import 'dart:async';
import 'dart:developer';
import '../../api/contact_api.dart';
import '../../api/message_api.dart';
import '../../models/message/message_response.dart';
import '../../models/contact/contact.dart';

typedef PollingDataHandler =
    void Function({
      List<MessageResponse>? messages,
      List<Contact>? contacts,
      int? unreadCount,
    });

class ImPollingService {
  ImPollingService({
    required this.contactApi,
    required this.messageApi,
    required this.onData,
  });

  final ContactApi contactApi;
  final MessageApi messageApi;
  final PollingDataHandler onData;

  Timer? _messageTimer;
  Timer? _contactsTimer;

  bool get isPollingActive => _messageTimer != null && _messageTimer!.isActive;

  // adaptive polling config
  static const Duration _foregroundMessageInterval = Duration(seconds: 15);
  static const Duration _backgroundMessageInterval = Duration(minutes: 5);
  Duration _currentMessageInterval = _foregroundMessageInterval;
  int _backoffMultiplier = 1;

  static const Duration _contactsPullInterval = Duration(minutes: 10);

  void startPolling() {
    _startMessagePolling();
    _startContactsPolling();
    _fetchInitialData();
  }

  void stopPolling() {
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

  void _startContactsPolling() {
    _contactsTimer?.cancel();
    _contactsTimer = Timer.periodic(_contactsPullInterval, (timer) {
      _fetchContacts();
    });
  }

  void applyPollingInterval({required bool isForeground}) {
    _currentMessageInterval = isForeground
        ? _foregroundMessageInterval
        : _backgroundMessageInterval;
    _startMessagePolling();
  }

  Future<void> _fetchContacts() async {
    try {
      final response = await contactApi.getContacts(page: 1, size: 100);
      onData(contacts: response.items);
    } catch (e) {
      log('ImPollingService: fetch contacts failed: $e');
    }
  }

  Future<void> _fetchMessages() async {
    try {
      final receivedData = await messageApi.getMessages(
        direction: 'received',
        page: 1,
        size: 50,
      );
      final sentData = await messageApi.getMessages(
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
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final unread = receivedData.items.where((m) => !m.isRead).length;

      // notify owner
      onData(messages: list, unreadCount: unread);

      // simple backoff reset
      _backoffMultiplier = 1;
    } catch (e) {
      log('ImPollingService: fetch messages failed: $e');
      if (_backoffMultiplier < 8) {
        _backoffMultiplier *= 2;
        _startMessagePolling();
      }
    }
  }

  Future<void> refresh() async {
    await Future.wait([_fetchContacts(), _fetchMessages()]);
  }

  void dispose() {
    stopPolling();
  }
}
