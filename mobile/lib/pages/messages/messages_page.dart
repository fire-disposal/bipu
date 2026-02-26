import 'package:flutter/material.dart';
import 'package:bipupu/core/network/network.dart';
import 'package:bipupu/core/network/api_exception.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/auth_service.dart';
import 'pages/subscriptions_management_page.dart';

enum MessageMenuType { received, sent, favorites, system }

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final AuthService _authService = AuthService();
  MessageMenuType? _selectedMenu;
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
      final response = await ApiClient.instance.api.messages.getApiMessages();
      setState(() {
        _messages = response.messages;
      });
    } on ApiException catch (e) {
      debugPrint('Error loading messages: ${e.message}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _refresh() {
    _loadMessages();
  }

  int _getUnreadCount(MessageMenuType menuType) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return 0;

    final myId = currentUser.bipupuId;
    final filtered = _messages.where((msg) {
      switch (menuType) {
        case MessageMenuType.received:
          return msg.receiverId == myId &&
              msg.messageType != MessageType.system;
        case MessageMenuType.sent:
          return msg.senderId == myId && msg.messageType != MessageType.system;
        case MessageMenuType.favorites:
          return false; // TODO: 实现收藏消息
        case MessageMenuType.system:
          return msg.messageType == MessageType.system;
      }
    }).toList();

    return filtered.where((msg) => !_readMessageIds.contains(msg.id)).length;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return Center(child: Text('please_login'.tr()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('messages_title'.tr()),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 菜单栏
                _buildMenuBar(
                  'messages_menu_received'.tr(),
                  MessageMenuType.received,
                ),
                _buildMenuBar('messages_menu_sent'.tr(), MessageMenuType.sent),
                _buildMenuBar(
                  'messages_menu_favorites'.tr(),
                  MessageMenuType.favorites,
                ),
                _buildMenuBar(
                  'messages_menu_system'.tr(),
                  MessageMenuType.system,
                ),
                _buildManagementMenuBar(),
                const Divider(height: 1),
                // 二级菜单消息列表
                if (_selectedMenu != null)
                  Expanded(child: _buildMessageList(_selectedMenu!))
                else
                  Expanded(child: Center(child: Text('select_menu'.tr()))),
              ],
            ),
    );
  }

  Widget _buildMenuBar(String title, MessageMenuType menuType) {
    final selected = _selectedMenu == menuType;
    final unreadCount = _getUnreadCount(menuType);

    return Material(
      color: selected ? Theme.of(context).primaryColor.withOpacity(0.08) : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMenu = menuType;
          });
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check, size: 18, color: Colors.green),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagementMenuBar() {
    return Material(
      child: InkWell(
        onTap: () {
          context.push('/messages/subscriptions');
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'subscription_management'.tr(),
                style: const TextStyle(fontSize: 16),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(MessageMenuType menuType) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return Center(child: Text('please_login'.tr()));
    }

    final myId = currentUser.bipupuId;

    // Sort messages by latest first
    final List<MessageResponse> messages = List.from(_messages)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Apply filter selection
    final filtered = messages.where((msg) {
      switch (menuType) {
        case MessageMenuType.received:
          return msg.receiverId == myId &&
              msg.messageType != MessageType.system;
        case MessageMenuType.sent:
          return msg.senderId == myId && msg.messageType != MessageType.system;
        case MessageMenuType.favorites:
          return false; // TODO: 实现收藏消息
        case MessageMenuType.system:
          return msg.messageType == MessageType.system;
      }
    }).toList();

    return filtered.isEmpty
        ? Center(child: Text('no_messages'.tr()))
        : ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final msg = filtered[index];
              final isRead = _readMessageIds.contains(msg.id);
              final title = msg.senderId == myId
                  ? 'To: ${msg.receiverId}'
                  : 'From: ${msg.senderId}';

              return ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      child: Text(
                        (msg.senderId.isNotEmpty
                                ? msg.senderId
                                : msg.receiverId)
                            .substring(0, 1)
                            .toUpperCase(),
                      ),
                    ),
                    if (!isRead)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  msg.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isRead ? Colors.grey : Colors.black87,
                  ),
                ),
                trailing: Text(
                  DateFormat('MM-dd HH:mm').format(msg.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
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
                            isRead ? 'mark_unread'.tr() : 'mark_read'.tr(),
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
              );
            },
          );
  }
}
