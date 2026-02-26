import 'package:flutter/material.dart';
import 'package:bipupu/core/network/network.dart';
import 'package:bipupu/core/network/api_exception.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/auth_service.dart';

class ReceivedMessagesPage extends StatefulWidget {
  const ReceivedMessagesPage({super.key});

  @override
  State<ReceivedMessagesPage> createState() => _ReceivedMessagesPageState();
}

class _ReceivedMessagesPageState extends State<ReceivedMessagesPage> {
  final AuthService _authService = AuthService();
  List<MessageResponse> _messages = [];
  bool _isLoading = false;
  late SharedPreferences _prefs;
  final Set<int> _readMessageIds = {};

  @override
  void initState() {
    super.initState();
    _initPrefs();
    _loadMessages();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadReadStatus();
  }

  void _loadReadStatus() {
    final readIds = _prefs.getStringList('read_message_ids') ?? [];
    setState(() {
      _readMessageIds.clear();
      _readMessageIds.addAll(readIds.map((id) => int.parse(id)));
    });
  }

  Future<void> _markAsRead(int messageId) async {
    if (!_readMessageIds.contains(messageId)) {
      _readMessageIds.add(messageId);
      await _prefs.setStringList(
        'read_message_ids',
        _readMessageIds.map((id) => id.toString()).toList(),
      );
      setState(() {});
    }
  }

  Future<void> _markAsUnread(int messageId) async {
    if (_readMessageIds.contains(messageId)) {
      _readMessageIds.remove(messageId);
      await _prefs.setStringList(
        'read_message_ids',
        _readMessageIds.map((id) => id.toString()).toList(),
      );
      setState(() {});
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.instance.api.messages.getApiMessages(
        direction: 'received',
      );
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final myId = currentUser.bipupuId;
        final filtered = response.messages
            .where(
              (msg) =>
                  msg.receiverBipupuId == myId &&
                  msg.messageType != MessageType.system,
            )
            .toList();
        setState(() {
          _messages = filtered;
        });
      }
    } on ApiException catch (e) {
      debugPrint('Error loading messages: ${e.message}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _refresh() {
    _loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text('messages_menu_received'.tr())),
        body: Center(child: Text('please_login'.tr())),
      );
    }

    // Sort messages by latest first
    final List<MessageResponse> messages = List.from(_messages)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: Text('messages_menu_received'.tr()),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : messages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mail_outline,
                    size: 48,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'no_messages'.tr(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async => _loadMessages(),
              child: ListView.separated(
                itemCount: messages.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isRead = _readMessageIds.contains(msg.id);

                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () async {
                        await _markAsRead(msg.id);
                        if (mounted) {
                          context.push('/messages/detail', extra: msg);
                        }
                      },
                      onLongPress: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => Wrap(
                            children: [
                              ListTile(
                                leading: Icon(
                                  isRead ? Icons.mail : Icons.mail_outline,
                                ),
                                title: Text(
                                  isRead
                                      ? 'mark_unread'.tr()
                                      : 'mark_read'.tr(),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  if (isRead) {
                                    _markAsUnread(msg.id);
                                  } else {
                                    _markAsRead(msg.id);
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.2),
                                  child: Text(
                                    msg.senderBipupuId
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                if (!isRead)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'From: ${msg.senderBipupuId}',
                                          style: TextStyle(
                                            fontWeight: isRead
                                                ? FontWeight.w500
                                                : FontWeight.bold,
                                            fontSize: 14,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormat(
                                          'MM-dd HH:mm',
                                        ).format(msg.createdAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    msg.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isRead
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
